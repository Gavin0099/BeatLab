#include "BeatLabDSP.h"
#include <stdlib.h>
#include <math.h>
#include <stdatomic.h>

#define HISTORY 64
#define CLICK_MAX 1536

typedef struct {
    atomic_uint_fast64_t version, start, end, number, bar, settings;
    atomic_int index, muted;
} BeatSlot;
struct BLDSP {
    uint32_t rate, clickLength;
    float clicks[3][3][CLICK_MAX];
    atomic_uint_fast64_t requested;
    atomic_uint gain;
    atomic_uint options;
    float *voices[5];
    uint32_t voiceLengths[5], speechOffset;
    int speechVoice, appliedMode, appliedGap, appliedLadder, ladderCounter;
    bool muted;
    atomic_uint_fast64_t clockVersion, clockStart, clockHost;
    atomic_uint clockCount;
    BeatSlot history[HISTORY];
    BLSettings applied;
    int64_t cursor, segmentStart, beatStart, nextBeat, nextPulse;
    uint64_t beatNumber, barNumber, segmentBeat;
    int beatInBar, pulse, voice, voiceOffset;
    bool started;
};
static int beats(int meter) { return meter == 1 ? 3 : meter == 2 ? 4 : 2; }
static int pulses(int sub) { return sub == 1 ? 2 : sub == 2 ? 4 : sub >= 3 ? 3 : 1; }
static bool compatible(int meter, int sub) { return meter == 3 ? sub == 4 : sub >= 0 && sub <= 3; }
static bool valid(BLSettings s) {
    if (!(s.bpm >= 30 && s.bpm <= 240 && s.meter >= 0 && s.meter <= 3 &&
        compatible(s.meter, s.subdivision) && (s.accent == 0 || s.accent == 1) &&
        s.timbre >= 0 && s.timbre <= 2 && s.beatPattern >= 0 && s.beatPattern <= 255)) return false;
    if (!s.beatPattern) return true;
    if ((s.beatPattern >> (2 * beats(s.meter))) != 0) return false;
    for (int i = 0; i < beats(s.meter); i++) if (((s.beatPattern >> (i * 2)) & 3) == 0) return false;
    return true;
}
static uint64_t pack(BLSettings s) {
    return (uint64_t)s.bpm | ((uint64_t)s.meter << 8) |
        ((uint64_t)s.subdivision << 12) | ((uint64_t)s.accent << 16) |
        ((uint64_t)s.beatPattern << 17) | ((uint64_t)s.timbre << 25);
}
static BLSettings unpack(uint64_t value) {
    BLSettings s = {(int)(value & 255), (int)((value >> 8) & 15),
        (int)((value >> 12) & 15), (int)((value >> 16) & 1),
        (int)((value >> 17) & 255), (int)((value >> 25) & 3)};
    return s;
}
/* Integer rational positions, rounded independently. No cumulative interval rounding. */
static int64_t position(const BLDSP *d, uint64_t beat, int pulse, int divisions) {
    uint64_t ticks = (beat - d->segmentBeat) * (uint64_t)divisions + (uint64_t)pulse;
    uint64_t numerator = ticks * d->rate * 60ULL;
    uint64_t denominator = (uint64_t)d->applied.bpm * (uint64_t)divisions;
    return d->segmentStart + (int64_t)((numerator + denominator / 2) / denominator);
}
static void recordBeat(BLDSP *d) {
    BeatSlot *slot = &d->history[d->beatNumber % HISTORY];
    uint64_t version = atomic_load_explicit(&slot->version, memory_order_relaxed);
    atomic_store_explicit(&slot->version, version + 1, memory_order_seq_cst);
    atomic_store_explicit(&slot->start, (uint64_t)d->beatStart, memory_order_seq_cst);
    atomic_store_explicit(&slot->end, (uint64_t)d->nextBeat, memory_order_seq_cst);
    atomic_store_explicit(&slot->number, d->beatNumber, memory_order_seq_cst);
    atomic_store_explicit(&slot->bar, d->barNumber, memory_order_seq_cst);
    atomic_store_explicit(&slot->settings, pack(d->applied), memory_order_seq_cst);
    atomic_store_explicit(&slot->index, d->beatInBar, memory_order_seq_cst);
    atomic_store_explicit(&slot->muted, d->muted, memory_order_seq_cst);
    atomic_store_explicit(&slot->version, version + 2, memory_order_seq_cst);
}
static void beginBeat(BLDSP *d) {
    if (d->started) {
        d->beatNumber++;
        d->beatInBar++;
        if (d->beatInBar >= beats(d->applied.meter)) {
            d->beatInBar = 0;
            d->barNumber++;
        }
    }
    d->started = true;
    BLSettings desired = unpack(atomic_load_explicit(&d->requested, memory_order_acquire));
    unsigned options = atomic_load_explicit(&d->options, memory_order_acquire);
    bool manualTempo = d->applied.bpm != desired.bpm;
    if (d->beatInBar == 0) {
        d->applied.meter = desired.meter;
        d->applied.accent = desired.accent;
        d->applied.beatPattern = desired.beatPattern;
        int ladder = (int)((options >> 8) & 255);
        if (ladder != d->appliedLadder) d->ladderCounter = 0;
        d->appliedLadder = ladder;
        d->appliedGap = (int)((options >> 4) & 3);
        if (d->barNumber > 0 && ladder && !manualTempo && ++d->ladderCounter >= ladder) {
            desired.bpm = desired.bpm > 235 ? 240 : desired.bpm + 5;
            /* Update BPM only if the user has not changed the mailbox concurrently. */
            uint64_t expected = atomic_load_explicit(&d->requested, memory_order_acquire);
            BLSettings current = unpack(expected);
            if (current.bpm == d->applied.bpm) {
                current.bpm = desired.bpm;
                uint64_t updated = pack(current);
                if (!atomic_compare_exchange_strong_explicit(&d->requested, &expected, updated,
                        memory_order_acq_rel, memory_order_acquire)) desired = unpack(expected);
            } else desired.bpm = current.bpm;
            d->ladderCounter = 0;
        }
    }
    d->appliedMode = (int)(options & 3);
    d->applied.timbre = desired.timbre;
    bool beatMuted = d->applied.beatPattern && ((d->applied.beatPattern >> (d->beatInBar * 2)) & 3) == 3;
    d->muted = beatMuted || (d->appliedGap && (d->barNumber % (uint64_t)(4 + d->appliedGap)) >= 4);
    if (compatible(d->applied.meter, desired.subdivision)) {
        d->applied.subdivision = desired.subdivision;
    }
    if (d->applied.bpm != desired.bpm) {
        d->segmentStart = d->cursor;
        d->segmentBeat = d->beatNumber;
        d->applied.bpm = desired.bpm;
    }
    d->beatStart = d->cursor;
    d->nextBeat = position(d, d->beatNumber + 1, 0, 1);
    d->pulse = 0;
    d->nextPulse = d->cursor;
    recordBeat(d);
}
BLDSP *BLDSPCreate(uint32_t rate, BLSettings settings) {
    if (rate < 8000 || rate > 192000 || !valid(settings)) return NULL;
    BLDSP *d = calloc(1, sizeof(*d));
    if (!d) return NULL;
    d->rate = rate; d->applied = settings;
    atomic_init(&d->requested, pack(settings)); atomic_init(&d->gain, 700);
    atomic_init(&d->options, 0);
    atomic_init(&d->clockVersion, 0); atomic_init(&d->clockStart, 0);
    atomic_init(&d->clockHost, 0); atomic_init(&d->clockCount, 0);
    for (int i = 0; i < HISTORY; i++) {
        BeatSlot *s = &d->history[i];
        atomic_init(&s->version, 0); atomic_init(&s->start, 0); atomic_init(&s->end, 0);
        atomic_init(&s->number, 0); atomic_init(&s->bar, 0); atomic_init(&s->settings, 0);
        atomic_init(&s->index, 0);
        atomic_init(&s->muted, 0);
    }
    if (!atomic_is_lock_free(&d->requested) || !atomic_is_lock_free(&d->gain) ||
        !atomic_is_lock_free(&d->clockCount) || !atomic_is_lock_free(&d->history[0].index)) {
        free(d); return NULL;
    }
    d->clickLength = rate / 125; /* 8 ms, generated before the real-time path. */
    const double frequencies[3] = {2100.0, 3200.0, 1400.0};
    for (int timbre = 0; timbre < 3; timbre++) for (int voice = 0; voice < 3; voice++) for (uint32_t i = 0; i < d->clickLength; i++) {
        double t = (double)i / rate;
        /* Start at nonzero amplitude; onset is observable at the target sample. */
        double phase = 6.283185307179586 * frequencies[voice] * t;
        double value = cos(phase) * exp(-650.0 * t);
        if (timbre == 1) value = (0.65 * cos(phase * 0.38) + 0.35 * cos(phase * 0.93)) * exp(-450.0 * t);
        if (timbre == 2) value = (0.5 * cos(phase * 0.7) + 0.3 * cos(phase * 1.83) + 0.2 * cos(phase * 2.61)) * exp(-1000.0 * t);
        d->clicks[timbre][voice][i] = (float)(0.7 * value);
    }
    d->voiceOffset = (int)d->clickLength;
    return d;
}
void BLDSPDestroy(BLDSP *d) {
    if (d) for (int i = 0; i < 5; i++) free(d->voices[i]);
    free(d);
}
bool BLDSPSetVoice(BLDSP *d, int index, const float *samples, uint32_t count) {
    if (!d || d->started || index < 0 || index >= 5 || !samples || !count || count > d->rate) return false;
    for (uint32_t i = 0; i < count; i++) if (!isfinite(samples[i])) return false;
    float *copy = malloc(sizeof(float) * count);
    if (!copy) return false;
    for (uint32_t i = 0; i < count; i++) copy[i] = samples[i];
    free(d->voices[index]); d->voices[index] = copy; d->voiceLengths[index] = count;
    return true;
}
bool BLDSPSetPracticeOptions(BLDSP *d, int mode, int gap, int ladder) {
    if (!d || mode < 0 || mode > 2 || gap < 0 || gap > 2 || ladder < 0 || ladder > 32) return false;
    atomic_store_explicit(&d->options, (unsigned)mode | ((unsigned)gap << 4) | ((unsigned)ladder << 8), memory_order_release);
    return true;
}
bool BLDSPRequest(BLDSP *d, BLSettings s) {
    if (!d || !valid(s)) return false;
    atomic_store_explicit(&d->requested, pack(s), memory_order_release); return true;
}
BLSettings BLDSPRequestedSettings(const BLDSP *d) {
    return d ? unpack(atomic_load_explicit(&d->requested, memory_order_acquire)) : (BLSettings){80,2,0,1,0,0};
}
void BLDSPSetGain(BLDSP *d, float gain) {
    if (!d || !isfinite(gain)) return;
    if (gain < 0) gain = 0;
    if (gain > 1) gain = 1;
    atomic_store_explicit(&d->gain, (unsigned)(gain * 1000.0f), memory_order_relaxed);
}
void BLDSPRender(BLDSP *d, float *output, uint32_t count, uint64_t host) {
    if (!d || !output) return;
    uint64_t version = atomic_load_explicit(&d->clockVersion, memory_order_relaxed);
    atomic_store_explicit(&d->clockVersion, version + 1, memory_order_seq_cst);
    atomic_store_explicit(&d->clockStart, (uint64_t)d->cursor, memory_order_seq_cst);
    atomic_store_explicit(&d->clockHost, host, memory_order_seq_cst);
    atomic_store_explicit(&d->clockCount, count, memory_order_seq_cst);
    atomic_store_explicit(&d->clockVersion, version + 2, memory_order_seq_cst);
    float gain = (float)atomic_load_explicit(&d->gain, memory_order_relaxed) / 1000.0f;
    for (uint32_t i = 0; i < count; i++, d->cursor++) {
        if (!d->started || d->cursor == d->nextBeat) beginBeat(d);
        if (d->cursor == d->nextPulse) {
            int emphasis = d->applied.beatPattern ? (d->applied.beatPattern >> (d->beatInBar * 2)) & 3
                : (d->beatInBar == 0 && d->applied.accent ? 2 : 1);
            d->voice = d->pulse == 0 ? (emphasis == 2 ? 1 : 0) : 2;
            d->voiceOffset = 0;
            if (d->pulse == 0 || d->applied.subdivision == 1) {
                d->speechVoice = d->pulse == 0 ? d->beatInBar : 4;
                d->speechOffset = 0;
            }
            d->pulse++;
            d->nextPulse = d->pulse < pulses(d->applied.subdivision)
                ? position(d, d->beatNumber, d->pulse, pulses(d->applied.subdivision)) : d->nextBeat;
        }
        float click = d->voiceOffset < (int)d->clickLength
            ? d->clicks[d->applied.timbre][d->voice][d->voiceOffset++] * gain * (d->voice == 2 ? 0.45f : 1.0f) : 0;
        int word = d->speechVoice;
        float speech = d->voices[word] && d->speechOffset < d->voiceLengths[word]
            ? d->voices[word][d->speechOffset++] * gain : 0;
        float value = d->appliedMode == 0 ? click : d->appliedMode == 1 ? speech : click * 0.45f + speech * 0.7f;
        output[i] = d->muted ? 0 : fmaxf(-1, fminf(1, value));
    }
}
bool BLDSPReadClock(const BLDSP *d, BLClock *clock) {
    if (!d || !clock) return false;
    uint64_t version = atomic_load_explicit(&d->clockVersion, memory_order_seq_cst);
    if (!version || (version & 1)) return false;
    clock->renderStartFrame = (int64_t)atomic_load_explicit(&d->clockStart, memory_order_seq_cst);
    clock->hostTime = atomic_load_explicit(&d->clockHost, memory_order_seq_cst);
    clock->frameCount = atomic_load_explicit(&d->clockCount, memory_order_seq_cst);
    clock->sampleRate = d->rate;
    return version == atomic_load_explicit(&d->clockVersion, memory_order_seq_cst);
}
bool BLDSPReadBeat(const BLDSP *d, int64_t frame, BLBeat *beat) {
    if (!d || !beat || frame < 0) return false;
    for (int i = 0; i < HISTORY; i++) {
        const BeatSlot *slot = &d->history[i];
        uint64_t version = atomic_load_explicit(&slot->version, memory_order_seq_cst);
        if (!version || (version & 1)) continue;
        BLBeat candidate;
        candidate.startFrame = (int64_t)atomic_load_explicit(&slot->start, memory_order_seq_cst);
        candidate.endFrame = (int64_t)atomic_load_explicit(&slot->end, memory_order_seq_cst);
        candidate.beatNumber = atomic_load_explicit(&slot->number, memory_order_seq_cst);
        candidate.barNumber = atomic_load_explicit(&slot->bar, memory_order_seq_cst);
        candidate.beatInBar = atomic_load_explicit(&slot->index, memory_order_seq_cst);
        candidate.muted = atomic_load_explicit(&slot->muted, memory_order_seq_cst) != 0;
        candidate.settings = unpack(atomic_load_explicit(&slot->settings, memory_order_seq_cst));
        if (version == atomic_load_explicit(&slot->version, memory_order_seq_cst) &&
            frame >= candidate.startFrame && frame < candidate.endFrame) {
            *beat = candidate; return true;
        }
    }
    return false;
}
