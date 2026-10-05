#include "BeatLabDSP.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <inttypes.h>
#include <string.h>

static uint64_t checks;
#define CHECK(expr) do { checks++; if (!(expr)) { fprintf(stderr, "FAIL line %d: %s\n", __LINE__, #expr); exit(1); } } while (0)
static void advance(BLDSP *d, uint32_t frames) {
    float buffer[4096];
    while (frames) {
        uint32_t count = frames > 4096 ? 4096 : frames;
        BLDSPRender(d, buffer, count, 12345);
        frames -= count;
    }
}
static void boundaries(void) {
    BLSettings initial = {120, 2, 0, 1,0,0};
    CHECK(!BLDSPCreate(0, initial));
    CHECK(!BLDSPCreate(192001, initial));
    CHECK(!BLDSPCreate(48000, (BLSettings){120, 3, 0, 1,0,0}));
    BLDSP *d = BLDSPCreate(48000, initial);
    CHECK(d);
    BLBeat beat;
    BLClock clock;
    CHECK(!BLDSPReadClock(d, &clock));
    CHECK(!BLDSPReadBeat(d, -1, &beat));
    advance(d, 1000);
    CHECK(BLDSPRequest(d, (BLSettings){60, 2, 1, 1,0,0}));
    advance(d, 23001);
    CHECK(BLDSPReadBeat(d, 23999, &beat));
    CHECK(beat.settings.bpm == 120 && beat.settings.subdivision == 0);
    CHECK(BLDSPReadBeat(d, 24000, &beat));
    CHECK(beat.settings.bpm == 60 && beat.settings.subdivision == 1);
    CHECK(beat.startFrame == 24000 && beat.endFrame == 72000);
    BLDSPDestroy(d);

    d = BLDSPCreate(48000, initial);
    advance(d, 1);
    CHECK(BLDSPRequest(d, (BLSettings){120, 3, 4, 0,0,0}));
    advance(d, 24000);
    CHECK(BLDSPReadBeat(d, 24000, &beat));
    CHECK(beat.settings.meter == 2 && beat.settings.subdivision == 0 && beat.settings.accent == 1);
    advance(d, 72000);
    CHECK(BLDSPReadBeat(d, 96000, &beat));
    CHECK(beat.settings.meter == 3 && beat.settings.subdivision == 4 && beat.settings.accent == 0);
    CHECK(beat.beatInBar == 0 && beat.barNumber == 1);
    CHECK(BLDSPRequest(d, (BLSettings){60, 0, 1, 1,0,0}));
    CHECK(BLDSPRequest(d, (BLSettings){180, 1, 3, 1,0,0}));
    CHECK(!BLDSPRequest(d, (BLSettings){241, 1, 3, 1,0,0}));
    advance(d, 24000);
    CHECK(BLDSPReadBeat(d, 120000, &beat));
    CHECK(beat.settings.bpm == 180 && beat.settings.meter == 3 && beat.settings.subdivision == 4);
    CHECK(beat.endFrame == 136000);
    advance(d, 16000);
    CHECK(BLDSPReadBeat(d, 136000, &beat));
    CHECK(beat.settings.meter == 1 && beat.settings.subdivision == 3 && beat.settings.accent == 1);
    CHECK(beat.beatInBar == 0);
    BLDSPSetGain(d, 0);
    float silent[48000];
    BLDSPRender(d, silent, 48000, 67890);
    for (int i = 0; i < 48000; i++) CHECK(silent[i] == 0);
    CHECK(BLDSPReadClock(d, &clock));
    CHECK(clock.hostTime == 67890 && clock.renderStartFrame == 136001);
    CHECK(BLDSPReadBeat(d, 184000, &beat) && beat.beatNumber == 9);
    BLDSPDestroy(d);
    /* Explicit restart owns a fresh transport; no old bar/phase survives. */
    for (int i = 0; i < 100; i++) {
        d = BLDSPCreate(48000, initial);
        CHECK(d);
        float first;
        BLDSPRender(d, &first, 1, 1);
        CHECK(first != 0 && BLDSPReadBeat(d, 0, &beat));
        CHECK(beat.beatNumber == 0 && beat.beatInBar == 0);
        BLDSPDestroy(d);
    }
}

static void challenges(void) {
    BLDSP *d = BLDSPCreate(48000, (BLSettings){120,2,0,1,0,0});
    CHECK(d);
    CHECK(!BLDSPSetPracticeOptions(d, 3, 0, 0));
    CHECK(!BLDSPSetPracticeOptions(d, 0, 3, 0));
    CHECK(!BLDSPSetPracticeOptions(d, 0, 0, 33));
    CHECK(BLDSPSetPracticeOptions(d, 0, 1, 0));
    advance(d, 384000); /* Four complete audible 4/4 bars. */
    float buffer[4096];
    uint32_t remaining = 96000;
    while (remaining) {
        uint32_t n = remaining > 4096 ? 4096 : remaining;
        BLDSPRender(d, buffer, n, 10);
        for (uint32_t i = 0; i < n; i++) CHECK(buffer[i] == 0);
        remaining -= n;
    }
    BLBeat beat;
    CHECK(BLDSPReadBeat(d, 479999, &beat) && beat.muted && beat.barNumber == 4);
    BLDSPRender(d, buffer, 1, 11);
    CHECK(buffer[0] != 0);
    CHECK(BLDSPReadBeat(d, 480000, &beat) && !beat.muted && beat.barNumber == 5 && beat.beatNumber == 20);
    BLDSPDestroy(d);

    d = BLDSPCreate(48000, (BLSettings){120,2,0,1,0,0});
    CHECK(BLDSPSetPracticeOptions(d, 0, 1, 2));
    advance(d, 192001);
    CHECK(BLDSPReadBeat(d, 192000, &beat) && beat.settings.bpm == 125 && beat.barNumber == 2);
    CHECK(beat.endFrame == 215040);
    advance(d, 184320);
    CHECK(BLDSPReadBeat(d, 376320, &beat) && beat.settings.bpm == 130 && beat.barNumber == 4 && beat.muted);
    CHECK(beat.endFrame == 398474);
    CHECK(BLDSPRequestedSettings(d).bpm == 130);
    CHECK(BLDSPSetPracticeOptions(d, 0, 0, 0));
    CHECK(BLDSPRequest(d, (BLSettings){60,2,0,1,0,0}));
    advance(d, 22154);
    CHECK(BLDSPReadBeat(d, 398474, &beat) && beat.settings.bpm == 60);
    CHECK(beat.endFrame == 446474);
    BLDSPDestroy(d);

    d = BLDSPCreate(48000, (BLSettings){235,0,0,1,0,0});
    CHECK(BLDSPSetPracticeOptions(d, 0, 0, 1));
    advance(d, 25000);
    CHECK(BLDSPRequestedSettings(d).bpm == 240);
    advance(d, 100000);
    CHECK(BLDSPRequestedSettings(d).bpm == 240);
    BLDSPDestroy(d);

    d = BLDSPCreate(48000, (BLSettings){120,2,1,1,0,0});
    const float word[] = {0.4f,0.2f,0.1f};
    for (int i = 0; i < 5; i++) CHECK(BLDSPSetVoice(d,i,word,3));
    CHECK(!BLDSPSetVoice(d,5,word,3));
    CHECK(BLDSPSetPracticeOptions(d,1,0,0));
    BLDSPRender(d,buffer,4,12);
    CHECK(fabsf(buffer[0]-0.28f)<1e-6f && buffer[3]==0);
    CHECK(!BLDSPSetVoice(d,0,word,3));
    advance(d,11996);
    BLDSPRender(d,buffer,1,13);
    CHECK(fabsf(buffer[0]-0.28f)<1e-6f); /* 'and' starts on the eighth onset. */
    CHECK(BLDSPSetPracticeOptions(d,2,0,0));
    advance(d,11999);
    BLDSPRender(d,buffer,1,14);
    CHECK(buffer[0]>0.28f && buffer[0]<=1);
    BLDSPDestroy(d);
}

static void beat_controls(void) {
    float *output = calloc(120001, sizeof(float));
    CHECK(output);
    for (int meter = 0; meter < 4; meter++) for (int timbre = 0; timbre < 3; timbre++) {
        int count = meter == 1 ? 3 : meter == 2 ? 4 : 2;
        int pattern = 2 | (3 << 2);
        for (int i = 2; i < count; i++) pattern |= 1 << (i * 2);
        int sub = meter == 3 ? 4 : 2;
        BLDSP *d = BLDSPCreate(48000, (BLSettings){120,meter,sub,1,pattern,timbre});
        CHECK(d);
        BLDSPRender(d,output,(uint32_t)(24000 * count + 1),12345);
        CHECK(output[0] != 0 && output[24000 * count] != 0);
        for (int i = 24000; i < 48000; i++) CHECK(output[i] == 0);
        if (count > 2) CHECK(output[48000] != 0);
        BLBeat beat;
        CHECK(BLDSPReadBeat(d,24000,&beat) && beat.muted && beat.beatNumber == 1);
        CHECK(BLDSPReadBeat(d,24000 * count,&beat) && !beat.muted && beat.barNumber == 1);
        CHECK(!BLDSPRequest(d,(BLSettings){120,meter,sub,1,1,timbre}));
        CHECK(!BLDSPRequest(d,(BLSettings){120,meter,sub,1,pattern,3}));
        BLDSPDestroy(d);
    }
    float voices[3][64];
    for (int timbre = 0; timbre < 3; timbre++) {
        BLDSP *d = BLDSPCreate(48000,(BLSettings){120,2,0,1,86,timbre});
        CHECK(d); BLDSPRender(d,voices[timbre],64,1); BLDSPDestroy(d);
    }
    for (int a = 0; a < 3; a++) for (int b = a + 1; b < 3; b++) {
        float difference = 0;
        for (int i = 0; i < 64; i++) difference += fabsf(voices[a][i] - voices[b][i]);
        CHECK(difference > 0.1f);
    }
    /* All-muted output still advances the ladder and transport; restore next bar. */
    BLDSP *d = BLDSPCreate(48000,(BLSettings){120,2,0,1,255,0});
    CHECK(d && BLDSPSetPracticeOptions(d,0,1,2));
    BLDSPRender(d,output,96000,1);
    for (int i = 0; i < 96000; i++) CHECK(output[i] == 0);
    CHECK(BLDSPRequest(d,(BLSettings){120,2,0,1,86,2}));
    BLDSPRender(d,output,96001,2);
    CHECK(output[0] != 0);
    BLBeat beat;
    CHECK(BLDSPReadBeat(d,192000,&beat) && beat.beatNumber == 8 && beat.settings.bpm == 125);
    BLDSPDestroy(d);
    free(output);
}

/* Independent oracle: observed nonzero onset after silence versus ideal real-valued
   musical time. Compare every pulse and its count, never just the renderer's history. */
static void long_run(uint32_t rate, int bpm, int meter, int sub, int divisions, int timbre, int comma) {
    BLDSP *d = BLDSPCreate(rate, (BLSettings){bpm, meter, sub, 1,0,timbre});
    CHECK(d);
    float buffer[4096], previous = 0;
    uint64_t total = (uint64_t)rate * 900, cursor = 0, onsets = 0, last = 0;
    uint64_t min_interval = UINT64_MAX, max_interval = 0;
    double max_error = 0, last_error = 0;
    while (cursor < total) {
        uint32_t n = total - cursor > 4096 ? 4096 : (uint32_t)(total - cursor);
        BLDSPRender(d, buffer, n, cursor + 1);
        for (uint32_t i = 0; i < n; i++) {
            CHECK(isfinite(buffer[i]) && fabsf(buffer[i]) <= 1);
            if (previous == 0 && buffer[i] != 0) {
                uint64_t frame = cursor + i;
                double ideal = (double)onsets * rate * 60.0 / (bpm * divisions);
                last_error = (double)frame - ideal;
                CHECK(fabs(last_error) <= 0.500001);
                if (fabs(last_error) > max_error) max_error = fabs(last_error);
                if (onsets) {
                    uint64_t interval = frame - last;
                    if (interval < min_interval) min_interval = interval;
                    if (interval > max_interval) max_interval = interval;
                }
                last = frame;
                onsets++;
            }
            previous = buffer[i];
        }
        cursor += n;
    }
    CHECK(onsets == (uint64_t)bpm * divisions * 15);
    printf("%s{\"rate\":%u,\"bpm\":%d,\"meter\":%d,\"subdivision\":%d,\"timbre\":%d,\"duration_seconds\":900,\"onsets\":%" PRIu64 ",\"interval_min_samples\":%" PRIu64 ",\"interval_max_samples\":%" PRIu64 ",\"max_onset_error_samples\":%.9f,\"final_onset_error_samples\":%.9f}", comma ? ",\n" : "", rate, bpm, meter, sub, timbre, onsets, min_interval, max_interval, max_error, last_error);
    fflush(stdout);
    BLDSPDestroy(d);
}
int main(int argc, char **argv) {
    boundaries();
    challenges();
    beat_controls();
    if (argc > 1 && strcmp(argv[1], "--boundaries-only") == 0) {
        printf("{\"boundary_restart_silence_gap_ladder_voice_tests\":\"PASS\",\"beat_controls\":\"PASS\",\"assertions\":%" PRIu64 "}\n", checks);
        return 0;
    }
    puts("{\"status\":\"PASS\",\"method\":\"actual C renderer, offline samples, independent onset oracle\",\"physical_device_gate\":\"NOT RUN\",\"runs\":[");
    const uint32_t rates[] = {44100,48000};
    const int tempos[] = {30,60,120,137,180,240};
    int run = 0;
    for (unsigned r = 0; r < 2; r++) for (unsigned t = 0; t < 6; t++)
        for (int meter = 0; meter < 4; meter++) for (int sub = 0; sub < 5; sub++) {
            if (meter == 3 ? sub != 4 : sub == 4) continue;
            const int divisions[] = {1,2,4,3,3};
            for (int timbre = 0; timbre < 3; timbre++) long_run(rates[r],tempos[t],meter,sub,divisions[sub],timbre,run++ != 0);
        }
    printf("\n],\"assertions\":%" PRIu64 ",\"boundary_restart_silence_gap_ladder_voice_tests\":\"PASS\"}\n", checks);
    return 0;
}
