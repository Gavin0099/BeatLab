"""Analyze independent capture CSV; does not record audio or certify instrument accuracy."""
import argparse
import csv
import json
import math
from pathlib import Path
from statistics import median


def analyze(rows, offset_seconds, resolution_ms):
    if not math.isfinite(offset_seconds) or not math.isfinite(resolution_ms) or resolution_ms <= 0:
        raise ValueError("Finite fixed offset and positive instrument resolution required")
    pairs = [(float(r["expected_seconds"]), float(r["observed_seconds"])) for r in rows]
    if len(pairs) < 100 or any(not math.isfinite(v) for pair in pairs for v in pair):
        raise ValueError("At least 100 finite paired onsets required")
    if any(a[0] >= b[0] or a[1] >= b[1] for a, b in zip(pairs, pairs[1:])):
        raise ValueError("Onsets must be strictly increasing; repair pairing and account for misses/extras")
    errors = [(actual - expected - offset_seconds) * 1000 for expected, actual in pairs]
    absolute = sorted(map(abs, errors))
    # Nearest-rank p95; fixed offset is supplied once, never fit independently per beat.
    p95 = absolute[math.ceil(len(absolute) * .95) - 1]
    first_time, last_time = pairs[0][0], pairs[-1][0]
    first = [e for (t, _), e in zip(pairs, errors) if t < first_time + 60]
    last = [e for (t, _), e in zip(pairs, errors) if t > last_time - 60]
    drift = median(last) - median(first)
    duration = last_time - first_time
    adequate = resolution_ms <= 1 and duration >= 899
    # Pairing alone cannot establish zero missing/extra pulses or device approval.
    return dict(onsets=len(pairs), duration_seconds=duration, offset_seconds=offset_seconds,
                instrument_resolution_ms=resolution_ms, p95_abs_ms=p95,
                max_abs_ms=max(absolute), final_minus_initial_median_ms=drift,
                numeric_budget="PASS" if adequate and p95 <= 5 and max(absolute) <= 10 and abs(drift) <= 5
                    else "FAIL" if adequate else "UNKNOWN",
                device_gate="NOT ACCEPTED", missing_extra_accounting="REQUIRES INDEPENDENT CHECK")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path)
    parser.add_argument("--fixed-offset-ms", type=float, required=True)
    parser.add_argument("--resolution-ms", type=float, required=True)
    args = parser.parse_args()
    with args.csv.open(newline="", encoding="utf-8-sig") as stream:
        result = analyze(list(csv.DictReader(stream)), args.fixed_offset_ms / 1000, args.resolution_ms)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
