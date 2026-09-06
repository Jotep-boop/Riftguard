#!/usr/bin/env python3
"""Run real Godot checks; reject runtime errors even if Godot exits zero."""
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT", "/home/hermes/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64")
checks = [
    ("import", ["--editor", "--quit"], None),
    ("rules", ["--script", "res://tests/run_tests.gd"], "PASS: 24 tests"),
    ("match", ["--script", "res://tests/match_tests.gd"], "Match assertions failed: 0"),
    ("strategy", ["--script", "res://tests/strategy_tests.gd"], "Strategy failures: 0"),
    ("integration", ["--script", "res://tests/integration_tests.gd"], "Integration failures: 0"),
    ("scene", ["--script", "res://tests/smoke_test.gd"], "PASS: match scene"),
    ("launch", ["--quit-after", "60"], None),
]
failed = []
for name, args, marker in checks:
    result = subprocess.run([GODOT, "--headless", "--path", str(ROOT), *args], capture_output=True, text=True, timeout=180)
    output = result.stdout + result.stderr
    print(f"=== {name} (exit {result.returncode}) ===\n{output}", flush=True)
    if result.returncode or re.search(r"(?:SCRIPT ERROR|ERROR:|WARNING:)", output) or (marker and marker not in output):
        failed.append(name)
result = subprocess.run(["git", "diff", "--check"], cwd=ROOT, capture_output=True, text=True)
print(result.stdout + result.stderr)
if result.returncode:
    failed.append("diff")
print("VERIFIED: all seven Godot checks and diff hygiene passed" if not failed else f"FAILED: {failed}")
sys.exit(bool(failed))
