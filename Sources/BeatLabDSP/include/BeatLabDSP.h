#ifndef BEATLAB_DSP_H
#define BEATLAB_DSP_H
#include <stdint.h>
#include <stdbool.h>

#ifdef _WIN32
#define BL_API __declspec(dllexport)
#else
#define BL_API
#endif

typedef struct BLDSP BLDSP;
/* Meter: 0=2/4, 1=3/4, 2=4/4, 3=6/8.
   Subdivision: 0=quarter, 1=eighth, 2=sixteenth, 3=triplet, 4=compound eighth. */
typedef struct { int bpm, meter, subdivision, accent; } BLSettings;
typedef struct {
    int64_t startFrame, endFrame;
    uint64_t beatNumber, barNumber;
    int beatInBar;
    BLSettings settings;
    bool muted;
} BLBeat;
typedef struct {
    int64_t renderStartFrame;
    uint64_t hostTime;
    uint32_t frameCount, sampleRate;
} BLClock;

BL_API BLDSP *BLDSPCreate(uint32_t sampleRate, BLSettings settings);
BL_API void BLDSPDestroy(BLDSP *dsp);
BL_API bool BLDSPRequest(BLDSP *dsp, BLSettings settings);
BL_API BLSettings BLDSPRequestedSettings(const BLDSP *dsp);
BL_API void BLDSPSetGain(BLDSP *dsp, float gain);
/* SetVoice is stopped/pre-start only. Copies PCM, never called by render. */
BL_API bool BLDSPSetVoice(BLDSP *dsp, int index, const float *samples, uint32_t count);
/* mode: 0 click, 1 voice, 2 both. Gap: 0 off, 1/2 silent bars after four.
   Ladder: 0 off, otherwise +5 BPM every ladderBars complete bars. */
BL_API bool BLDSPSetPracticeOptions(BLDSP *dsp, int mode, int gapBars, int ladderBars);
/* Single render-thread owner; no allocations, locks or Objective-C calls. */
BL_API void BLDSPRender(BLDSP *dsp, float *output, uint32_t count, uint64_t hostTime);
/* Control thread reads atomic history; false means no coherent snapshot yet. */
BL_API bool BLDSPReadClock(const BLDSP *dsp, BLClock *clock);
BL_API bool BLDSPReadBeat(const BLDSP *dsp, int64_t audibleFrame, BLBeat *beat);
#endif
