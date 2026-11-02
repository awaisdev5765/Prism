#!/usr/bin/env python3
"""Summarise a `flutter test --reporter json` stream and print the pass count.

The landing page states how many tests pass, and that number has to be measured
rather than typed in. Parsing the human-readable reporter is fragile: it wraps
numbers in ANSI codes, trails a summary with a tearDownAll line, and a test name
can contain a "+". The JSON reporter is stable, so this reads that instead.

Prints the human summary to stderr, so it shows up in CI logs, and the number of
passing tests to stdout, so the caller can capture it:

    count=$(python3 site/test_summary.py /tmp/report.json)

Skipped tests are reported separately: they did not pass, and counting them would
overstate the figure on the page. Hidden tests are the synthetic cases package:test
emits for group set-up and tear-down, and are excluded from both.
"""

from __future__ import annotations

import json
import pathlib
import sys


def summarise(path: pathlib.Path) -> tuple[int, int, int, list[str]]:
    passed = skipped = failed = 0
    failures: list[str] = []

    for line in path.read_text(errors="replace").splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") != "testDone":
            continue
        if event.get("hidden"):
            continue
        name = str(event.get("testID", "unknown"))
        if event.get("skipped"):
            skipped += 1
        elif event.get("result") == "success":
            passed += 1
        else:
            failed += 1
            failures.append(name)

    return passed, skipped, failed, failures


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2

    path = pathlib.Path(argv[1])
    if not path.exists():
        print(f"test report not found at {path}", file=sys.stderr)
        return 1

    passed, skipped, failed, failures = summarise(path)
    print(
        f"tests: {passed} passed, {skipped} skipped, {failed} failed",
        file=sys.stderr,
    )
    if failures:
        print("failing tests:", file=sys.stderr)
        for name in failures[:40]:
            print(f"  - {name}", file=sys.stderr)

    # The count is the only thing on stdout, so the caller can capture it.
    print(passed)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
