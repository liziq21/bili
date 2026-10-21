#!/usr/bin/env python3
"""Regenerate app/test/fonts/subset-characters.txt from live source.

Scans every .dart file under app/lib/ and app/test/ and extracts all
non-ASCII characters that appear inside string-literal text bodies
(simple literals, raw literals, and the literal fragments of
interpolated strings).  Interpolation holes (${expr} and $ident) are
skipped — that is code, not user-visible text.

The output is a single line of sorted unique characters, written to
app/test/fonts/subset-characters.txt.

Usage:
  python3 tool/generate_subset_characters.py           # summary
  python3 tool/generate_subset_characters.py --write   # update the file
  python3 tool/generate_subset_characters.py --check   # exit 1 if stale

CI step (in .github/workflows/ci.yml, after `flutter pub get`):
  - name: Check font subset is up to date
    run: python3 tool/generate_subset_characters.py --check
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Linear string-literal scanner
# ---------------------------------------------------------------------------


def _is_ascii_identifier_start(char: str) -> bool:
    return char == "_" or (char.isascii() and char.isalpha())


def _is_ascii_identifier_part(char: str) -> bool:
    return char == "_" or (char.isascii() and char.isalnum())


def _scan_string_literals(source: str) -> str:
    """Return the concatenated text-body of every string literal in *source*.

    Walks the source character by character, tracking whether we are inside
    a string literal or a comment.  Handles:
      - single-quoted ' and double-quoted "
      - raw string prefixes (r / R / $r / $" / ...)
      - escape sequences (\\, \\n, \\t, \\' etc.)
      - interpolated holes: ${...} (skipped, code not text) and $ident (skipped)
      - // line comments and /* */ block comments (skipped entirely)

    Only the *text fragments* of the literal body are returned, which is
    exactly what matters for the font subset: the characters a user can see.
    """
    i = 0
    n = len(source)
    result_parts: list[str] = []

    while i < n:
        c = source[i]

        # -- Comment: // ... --
        if c == "/" and i + 1 < n and source[i + 1] == "/":
            # skip to end of line
            i += 2
            while i < n and source[i] != "\n":
                i += 1
            continue

        # -- Comment: /* ... */ --
        if c == "/" and i + 1 < n and source[i + 1] == "*":
            i += 2
            while i < n:
                if source[i] == "*" and i + 1 < n and source[i + 1] == "/":
                    i += 2
                    break
                i += 1
            continue

        # -- String literal start: optional prefix chars then a quote --
        # Check for triple-quote first (multiline string).
        if (
            c in "'\""
            and i + 2 < n
            and source[i + 1] == c
            and source[i + 2] == c
        ):
            # Triple-quote: source[i..i+2] is ''' or """
            triple = c * 3
            i += 3
            body_parts: list[str] = []
            while i < n:
                # Check for closing triple-quote.
                if (
                    i + 2 < n
                    and source[i] == c
                    and source[i + 1] == c
                    and source[i + 2] == c
                ):
                    i += 3
                    break
                if i + 2 == n and source[i] == c and source[i + 1] == c:
                    # Two quotes at EOF — treat as closing.
                    i += 2
                    break
                ch = source[i]
                if ch == "$":
                    # Interpolation hole in a non-raw triple-quote.
                    if i + 1 < n and source[i + 1] == "{":
                        depth = 1
                        i += 2
                        while i < n and depth > 0:
                            if source[i] == "{":
                                depth += 1
                            elif source[i] == "}":
                                depth -= 1
                            i += 1
                    elif i + 1 < n and _is_ascii_identifier_start(source[i + 1]):
                        i += 1
                        while i < n and _is_ascii_identifier_part(source[i]):
                            i += 1
                    else:
                        i += 1
                    continue
                if ord(ch) > 0x7F:
                    body_parts.append(ch)
                i += 1
            result_parts.append("".join(body_parts))
            continue

        if c in "'\"" or (
            c in "rRf$" and i + 1 < n and source[i + 1] in "'\""
        ):
            # Find the actual opening quote (skip prefix chars).
            j = i
            while j < n and source[j] in "rRf$":
                j += 1
            if j < n and source[j] in "'\"":
                quote = source[j]
                i = j + 1
                # Now scan the literal body.
                body_parts: list[str] = []
                while i < n:
                    ch = source[i]
                    if ch == "\\":
                        # Escape sequence: include the escaped char.
                        if i + 1 < n:
                            body_parts.append(source[i + 1])
                            i += 2
                        else:
                            i += 1
                        continue
                    if ch == "$":
                        # Interpolation hole — skip it.
                        if i + 1 < n and source[i + 1] == "{":
                            depth = 1
                            i += 2
                            while i < n and depth > 0:
                                if source[i] == "{":
                                    depth += 1
                                elif source[i] == "}":
                                    depth -= 1
                                i += 1
                        elif i + 1 < n and _is_ascii_identifier_start(source[i + 1]):
                            i += 1
                            while i < n and _is_ascii_identifier_part(source[i]):
                                i += 1
                        else:
                            i += 1
                        continue
                    if ch == quote:
                        i += 1
                        break
                    if ord(ch) > 0x7F:
                        body_parts.append(ch)
                    i += 1
                result_parts.append("".join(body_parts))
                continue
        i += 1

    return "".join(result_parts)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def collect_non_ascii_codepoints(dart_dirs: list[Path]) -> set[int]:
    """Scan all .dart files under *dart_dirs* and return non-ASCII code points
    found inside string-literal text bodies."""
    code_points: set[int] = set()
    total_files = 0
    for d in dart_dirs:
        if not d.is_dir():
            continue
        for path in d.rglob("*.dart"):
            total_files += 1
            source = path.read_text(encoding="utf-8", errors="replace")
            bodies = _scan_string_literals(source)
            for ch in bodies:
                cp = ord(ch)
                if cp > 0x7F and cp < 0x10000:
                    code_points.add(cp)
    print(f"  scanned {total_files} .dart files", file=sys.stderr)
    return code_points


SUBSET_PATH = Path("app/test/fonts/subset-characters.txt")


def render_sorted(code_points: set[int]) -> str:
    """Return the single-line, code-point-sorted string."""
    return "".join(chr(cp) for cp in sorted(code_points))


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Regenerate subset-characters.txt from live source"
    )
    ap.add_argument("--write", action="store_true", help="update the file in place")
    ap.add_argument(
        "--check",
        action="store_true",
        help="diff against committed file; exit 1 on mismatch",
    )
    args = ap.parse_args()

    t0 = time.time()
    repo_root = Path(__file__).resolve().parent.parent
    app_dir = repo_root / "app"
    dart_dirs = [app_dir / "lib", app_dir / "test"]

    code_points = collect_non_ascii_codepoints(dart_dirs)
    generated = render_sorted(code_points)
    elapsed = time.time() - t0
    print(
        f"[scan] {len(code_points)} unique non-ASCII chars "
        f"in {elapsed:.1f}s",
        file=sys.stderr,
    )

    subset_file = repo_root / SUBSET_PATH

    if args.write:
        subset_file.parent.mkdir(parents=True, exist_ok=True)
        subset_file.write_text(generated + "\n", encoding="utf-8")
        print(f"[write] {subset_file}  ({len(code_points)} chars)")
        return 0

    if args.check:
        if not subset_file.exists():
            print(
                f"[check] FAIL — {subset_file} does not exist; "
                f"run with --write first.",
                file=sys.stderr,
            )
            return 1
        existing = subset_file.read_text(encoding="utf-8").strip()
        if existing == generated:
            print(
                f"[check] OK — {SUBSET_PATH} is up to date "
                f"({len(code_points)} chars)",
                file=sys.stderr,
            )
            return 0
        missing = sorted(set(generated) - set(existing))
        extra = sorted(set(existing) - set(generated))
        print(
            f"[check] STALE — {SUBSET_PATH} does not match the source scan.",
            file=sys.stderr,
        )
        if missing:
            print(
                f"  Missing ({len(missing)}): {''.join(missing)}",
                file=sys.stderr,
            )
        if extra:
            print(f"  Extra ({len(extra)}): {''.join(extra)}", file=sys.stderr)
        print(
            "\n  To fix:\n"
            "    python3 tool/generate_subset_characters.py --write\n"
            "    # then regenerate the OTF:\n"
            "    pyftsubset /path/to/NotoSansCJK-Regular.ttc \\\n"
            "      --font-number=2 \\\n"
            f"      --text-file={SUBSET_PATH} \\\n"
            "      --unicodes=U+0020-007E \\\n"
            "      --output-file=app/test/fonts/NotoSansSC-golden-subset.otf \\\n"
            "      --flavor=none --layout-features='*' --no-hinting --desubroutinize\n"
            "    # then re-record goldens:\n"
            "    cd app && flutter test --concurrency=1 --update-goldens test/golden/\n"
            "    # then commit both files and push.",
            file=sys.stderr,
        )
        return 1

    # Default: print summary
    print(f"  first 60: {generated[:60]!r}")
    print(f"  last  60: {generated[-60:]!r}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
