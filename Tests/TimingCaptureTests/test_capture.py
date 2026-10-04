import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("capture", Path(__file__).resolve().parents[2] / "scripts/analyze_capture.py")
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)


class CaptureTests(unittest.TestCase):
    def test_known_constant_offset_and_alternating_one_ms_jitter(self):
        rows = [dict(expected_seconds=i, observed_seconds=i + .100 + (.001 if i % 2 else -.001)) for i in range(900)]
        result = capture.analyze(rows, .100, .5)
        self.assertAlmostEqual(result["p95_abs_ms"], 1, places=6)
        self.assertAlmostEqual(result["final_minus_initial_median_ms"], 0, places=6)
        self.assertEqual(result["numeric_budget"], "PASS")
        self.assertEqual(result["device_gate"], "NOT ACCEPTED")

    def test_drift_and_insufficient_instrument_resolution(self):
        rows = [dict(expected_seconds=i, observed_seconds=i + .100 + i * .00002) for i in range(900)]
        self.assertEqual(capture.analyze(rows, .100, .5)["numeric_budget"], "FAIL")
        self.assertEqual(capture.analyze(rows, .100, 20)["numeric_budget"], "UNKNOWN")

    def test_short_invalid_or_unpaired_capture_is_rejected(self):
        with self.assertRaises(ValueError):
            capture.analyze([], 0, 1)
        rows = [dict(expected_seconds=i, observed_seconds=i) for i in range(100)]
        self.assertEqual(capture.analyze(rows, 0, 1)["numeric_budget"], "UNKNOWN")
        rows[20]["observed_seconds"] = 0
        with self.assertRaises(ValueError):
            capture.analyze(rows, 0, 1)


if __name__ == "__main__":
    unittest.main()
