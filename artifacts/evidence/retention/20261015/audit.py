"""Read-only evidence audit. Exit 1 means original retention is incomplete."""
from pathlib import Path
import datetime
import hashlib
import json
import subprocess

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]


def read(path):
    return json.loads((ROOT / path).read_text())


def verify(pairs):
    issues = []
    for name, expected in pairs:
        path = ROOT / name
        if not path.is_file():
            issues.append({"path": name, "issue": "missing", "expected_sha256": expected})
        elif hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            issues.append({"path": name, "issue": "hash mismatch", "expected_sha256": expected})
    return {"expected_files": len(pairs), "issues": issues}


def command(args):
    result = subprocess.run(args, cwd=ROOT, text=True, capture_output=True)
    return {"command": args, "exit_code": result.returncode,
            "stdout": result.stdout, "stderr": result.stderr}


night = {}
for number in range(26, 32):
    key = f"GAME-{number}"
    data = read(f"docs/slices/{key}-verification.json")
    night[key] = verify(list(data["evidence_sha256"].items()))

stage = read("docs/slices/UI-STAGE-03-verification.json")
stage_artifacts = verify([(v["path"], v["sha256"]) for v in stage["artifacts"]])
raw_bundles = []
for item in stage["raw_bundle_hashes"]:
    raw_bundles.append({
        "path": item["raw_result"],
        "exists": (ROOT / item["raw_result"]).is_dir(),
        "historical_file_count": item["file_count"],
        "inventory": verify([(item["hash_inventory"], item["sha256"])]),
        "original_file_hashes_revalidated": False,
    })

batch = read("docs/slices/RHYTHM-PLAY-BATCH-verification.json")
package = batch["candidate"]
phone = verify([(str(Path(package["frozen_path"]) / p), h)
                for p, h in package["package_files_sha256"].items()])
archive = verify([(package["archive"]["path"], package["archive"]["sha256"])])
tracked_records = []
for path in ["docs/slices/NIGHT-01.md", "docs/slices/QA-NIGHT-01-verification.json",
             "docs/slices/PHONE-10-verification.json", "docs/slices/GAME-33-verification.json",
             "docs/slices/GAME-34-verification.json", "docs/slices/RHYTHM-PLAY-BATCH-verification.json",
             "docs/slices/UI-STAGE-03-verification.json"]:
    tracked_records.append({"path": path, "exists": (ROOT / path).is_file(),
                            "sha256": hashlib.sha256((ROOT / path).read_bytes()).hexdigest()})

domain_paths = ["BeatLab", "BeatLabTests", "BeatLabUITests", "Sources", "Tests",
                "BeatLab.xcodeproj", "Package.swift"]
source = command(["git", "diff", "--exit-code", "cc6f5e7", "--", *domain_paths])
head = command(["git", "rev-parse", "HEAD"])
remote = command(["git", "ls-remote", "origin", "refs/heads/product-alpha/ui-checkpoint"])
alternate = [str(ROOT / "TestResults"), "/Users/pc49-58/.Trash/TestResults",
             "/Users/pc49-58/Desktop/TestResults"]

report = {
    "checked_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "audit_only": True,
    "new_build_test_install_upload": False,
    "original_TestResults_exists": (ROOT / "TestResults").exists(),
    "bounded_alternate_locations": [{"path": p, "exists": Path(p).exists()} for p in alternate],
    "cause": "NOT ESTABLISHED; no deletion action performed by this audit",
    "latest_prior_observation": "2026-10-14 turn reported retained evidence matching; prior ignored audit now absent",
    "night_artifact_retention": night,
    "drummer_artifact_retention": stage_artifacts,
    "drummer_raw_bundles": raw_bundles,
    "drummer_source118_manifest": "MISSING; cannot repeat frozen118-input hash binding",
    "tracked_source_vs_cc6f5e7": source,
    "head_at_start": head,
    "remote_at_start": remote,
    "tracked_summary_records": tracked_records,
    "phone14_package": phone,
    "phone14_archive": archive,
    "phone14_install_launch_raw_receipts": [
        {"path": f"TestResults/RHYTHM-PLAY-BATCH/{n}.json", "exists":
         (ROOT / f"TestResults/RHYTHM-PLAY-BATCH/{n}.json").is_file()}
        for n in ["install", "launch", "install-command", "launch-command"]],
    "historical_observations": {
        "phone14": "Committed summary records historical Wi-Fi install/launch success; current raw receipts missing",
        "drummer": "Committed summary records native13/UI3 and Dark1 repeat passing; raw results now missing",
    },
    "present_phone_state": "NOT CHECKED",
    "not_claimed": ["retention PASS", "fresh iOS tests", "byte-identical original package recovery",
                    "physical timing/FPS", "child/fullAX acceptance", "release readiness"],
}
issues = [v for v in [*night.values(), stage_artifacts, phone, archive] if v["issues"]]
report["result"] = "FAIL_ORIGINAL_EVIDENCE_RETENTION" if issues else "PASS"
report["audit_exit_code"] = 1 if issues else 0
(OUT / "audit.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"result": report["result"], "night_missing": sum(len(v["issues"]) for v in night.values()),
                  "drummer_missing": len(stage_artifacts["issues"]), "raw_bundle_count": len(raw_bundles),
                  "phone14_missing_files": len(phone["issues"]), "phone14_zip_missing": len(archive["issues"]),
                  "tracked_source_diff_exit": source["exit_code"]}, ensure_ascii=False))
raise SystemExit(report["audit_exit_code"])
