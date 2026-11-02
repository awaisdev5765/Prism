#!/usr/bin/env python3
"""Generate the GitHub Pages landing page from the package itself.

The component list is read from README.md and the token values from
lib/src/theme/tokens.dart, so the page cannot claim something the package does
not contain. The markup lives in template.html beside this file.

Run from the repository root:

    python3 site/build.py

The docs workflow runs this before publishing, which is why the page cannot go
stale the way a hand-maintained one does.
"""

from __future__ import annotations

import argparse
import html
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
OUT = SITE / "index.html"
TEMPLATE = SITE / "template.html"

# Editorial grouping. The README lists the components flat; someone arriving
# with "is the thing I need in here?" wants them bucketed.
GROUPS: list[tuple[str, str, list[str]]] = [
    (
        "Layout and navigation",
        "Structure, movement, and the shapes a screen takes.",
        [
            "AdaptiveScaffold", "AdaptiveDialog", "AdaptiveSheet", "Tabs",
            "MasterDetail", "Stepper", "Accordion", "CommandPalette",
        ],
    ),
    (
        "Data and input",
        "Collecting and presenting information, forms included.",
        [
            "DataTable", "Calendar", "Form", "Search", "Settings", "ChipInput",
            "OtpField", "Rating", "SegmentedControl",
        ],
    ),
    (
        "Feedback and status",
        "Telling the user what is happening without interrupting them.",
        [
            "Toast", "Banner", "StateViews", "Skeleton", "Pagination",
            "ConnectionBanner", "SyncStatus", "Badge", "Timeline",
        ],
    ),
    (
        "Content, media and platform",
        "Rendering, appearance, and the pieces that talk to the outside.",
        [
            "Markdown", "CodeView", "Changelog", "Palette", "Avatar",
            "Image", "Updater", "PrismAi",
        ],
    ),
]

SPACE_KEYS = ["spaceXs", "spaceSm", "spaceMd", "spaceLg", "spaceXl", "spaceXxl"]
RADIUS_KEYS = ["radiusSm", "radiusMd", "radiusLg", "radiusXl"]
DURATION_KEYS = ["durationFast", "durationMedium", "durationSlow"]


def read_components() -> dict[str, str]:
    """Parse the component table out of the README."""
    text = (ROOT / "README.md").read_text()
    found: dict[str, str] = {}
    for line in text.splitlines():
        m = re.match(
            r"^\|\s*\d+\s*\|\s*\*\*(.+?)\*\*\s*\|\s*(.+?)\s*\|\s*$", line
        )
        if m:
            found[m.group(1).strip()] = m.group(2).strip().replace("`", "")
    return found


def read_tokens() -> dict[str, str]:
    """Parse the default token values out of the source."""
    src = (ROOT / "lib" / "src" / "theme" / "tokens.dart").read_text()
    values: dict[str, str] = {}
    for key, raw in re.findall(
        r"this\.(space\w+|radius\w+|controlHeight|breakpoint\w+)\s*=\s*([^,\n]+),",
        src,
    ):
        values[key] = raw.strip()
    for key, ms in re.findall(
        r"this\.(duration\w+)\s*=\s*const Duration\(milliseconds:\s*(\d+)\)", src
    ):
        values[key] = f"{ms} ms"
    return values


def count_declared_tests() -> int:
    """Count test declarations in the source.

    This is a *lower bound*, not the number that runs: several suites build
    their cases in loops (the component matrix alone generates 184), so the
    executed total is higher. The docs workflow passes the real figure from an
    actual run with --tests, and the label changes accordingly, because a number
    the page cannot verify is worse than no number.
    """
    total = 0
    for path in sorted((ROOT / "test").rglob("*_test.dart")):
        total += len(re.findall(r"\btestWidgets?\(|\btest\(", path.read_text()))
    return total


def render_directory(components: dict[str, str]) -> str:
    sections = []
    for title, blurb, names in GROUPS:
        cards = []
        for name in names:
            desc = components.get(name)
            if desc is None:
                print(f"warning: {name} is not in the README table", file=sys.stderr)
                desc = ""
            cards.append(
                '<li class="comp" data-name="{n}" data-desc="{d}">'
                '<code class="comp-name">{n}</code>'
                '<span class="comp-desc">{d}</span></li>'.format(
                    n=html.escape(name), d=html.escape(desc)
                )
            )
        slug = re.sub(r"[^a-z]+", "-", title.lower()).strip("-")
        sections.append(
            '<section class="group" aria-labelledby="g-{slug}">\n'
            '  <h3 id="g-{slug}">{title}</h3>\n'
            '  <p class="group-blurb">{blurb}</p>\n'
            '  <ul class="comp-list">\n{cards}\n  </ul>\n'
            "</section>".format(
                slug=slug,
                title=html.escape(title),
                blurb=html.escape(blurb),
                cards="\n".join("    " + c for c in cards),
            )
        )
    return "\n".join(sections)


def render_spacing(tokens: dict[str, str]) -> str:
    rows = []
    for key in SPACE_KEYS:
        raw = tokens.get(key, "0")
        width = float(re.sub(r"[^0-9.]", "", raw) or 0)
        rows.append(
            '<div class="scale-row"><code>{k}</code>'
            '<span class="scale-bar" style="--w: {w}px"></span>'
            '<span class="scale-value">{v}</span></div>'.format(
                k=key, w=width, v=html.escape(raw)
            )
        )
    return "\n".join(rows)


def render_radii(tokens: dict[str, str]) -> str:
    cells = []
    for key in RADIUS_KEYS:
        raw = tokens.get(key, "0")
        cells.append(
            '<div class="radius-cell">'
            '<span class="radius-box" style="border-radius: {v}px"></span>'
            "<code>{k}</code><span class=\"scale-value\">{v}px</span>"
            "</div>".format(k=key, v=html.escape(raw))
        )
    return "\n".join(cells)


def build(measured_tests: int | None = None) -> str:
    components = read_components()
    if len(components) != 34:
        print(
            f"warning: expected 34 components in README.md, found {len(components)}",
            file=sys.stderr,
        )
    tokens = read_tokens()
    if measured_tests is None:
        tests, tests_label = count_declared_tests(), "test cases written"
    else:
        tests, tests_label = measured_tests, "tests passing"

    replacements = {
        "{{COMPONENTS}}": render_directory(components),
        "{{SPACING}}": render_spacing(tokens),
        "{{RADII}}": render_radii(tokens),
        "{{MOTION}}": " · ".join(
            f"<code>{k}</code> {html.escape(tokens.get(k, ''))}"
            for k in DURATION_KEYS
        ),
        "{{COUNT}}": str(len(components)),
        "{{TESTS}}": str(tests),
        "{{TESTS_LABEL}}": tests_label,
        "{{COMPACT_BP}}": html.escape(tokens.get("breakpointCompact", "")),
        "{{EXPANDED_BP}}": html.escape(tokens.get("breakpointExpanded", "")),
        "{{CONTROL_H}}": html.escape(tokens.get("controlHeight", "")),
    }

    page = TEMPLATE.read_text()
    for token, value in replacements.items():
        page = page.replace(token, value)

    leftovers = re.findall(r"\{\{[A-Z_]+\}\}", page)
    if leftovers:
        print(f"error: unsubstituted placeholders: {set(leftovers)}", file=sys.stderr)
        raise SystemExit(1)
    return page


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--tests",
        type=int,
        default=None,
        help=(
            "number of tests that actually ran; pass this from CI so the page "
            "reports a measured figure rather than a counted one"
        ),
    )
    args = parser.parse_args()
    OUT.write_text(build(args.tests))
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
