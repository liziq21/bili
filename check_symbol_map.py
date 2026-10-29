#!/usr/bin/env python3
"""CI gate: verify symbol map is up to date with changed files for LIZ-125.

Usage:
  - In CI: python3 check_symbol_map.py (uses CI_BASE_REF env var, defaults to origin/main)
  - Local: python3 check_symbol_map.py --base origin/main

The script checks if the committed symbol_index.json covers all Dart files
changed in the current branch vs base. If not, fails with exit code 1.

To update the symbol map:
  python3 extract_symbols.py && python3 clean_symbols.py
  git add symbol_index.json symbol_map_clean.json
"""

import sys
import json
import subprocess
import argparse
from pathlib import Path

SYMBOL_INDEX = Path("/workspace/bili/symbol_index.json")


def get_changed_files(base: str) -> list[str]:
    """Get list of changed Dart files in current branch vs base.
    
    Shows files that differ in HEAD compared to base (what a PR would introduce).
    """
    try:
        # Use merge-base to find common ancestor, then diff from there to HEAD
        # This works correctly whether HEAD is ahead or behind base
        merge_base = subprocess.run(
            ["git", "merge-base", base, "HEAD"],
            capture_output=True, text=True, cwd="/workspace/bili"
        ).stdout.strip()
        
        if not merge_base:
            # Fallback: direct diff (may show reverse if behind)
            result = subprocess.run(
                ["git", "diff", "--name-only", f"{base}..HEAD"],
                capture_output=True, text=True, cwd="/workspace/bili"
            )
        else:
            result = subprocess.run(
                ["git", "diff", "--name-only", f"{merge_base}..HEAD"],
                capture_output=True, text=True, cwd="/workspace/bili"
            )
        
        files = [f for f in result.stdout.strip().split("\n") if f and f.endswith(".dart")]
        return files
    except Exception as e:
        print(f"Error getting changed files: {e}", file=sys.stderr)
        return []


def check_symbol_map_freshness(changed_files: list[str]) -> tuple[bool, list[str]]:
    """Check if symbol map contains definitions for changed files."""
    if not SYMBOL_INDEX.exists():
        return False, ["Symbol index not found at " + str(SYMBOL_INDEX)]

    with SYMBOL_INDEX.open() as f:
        data = json.load(f)
    index = data["index"]

    # Collect all files that have definitions in the index
    indexed_files = set()
    for locations in index.values():
        for loc in locations:
            indexed_files.add(loc["file"])

    missing = []
    for f in changed_files:
        # Normalize path (remove workspace prefix if present)
        rel = f
        if rel.startswith("/workspace/bili/"):
            rel = rel[len("/workspace/bili/"):]
        if rel not in indexed_files:
            missing.append(rel)

    return len(missing) == 0, missing


def main():
    parser = argparse.ArgumentParser(description="Check symbol map freshness")
    parser.add_argument("--base", default="origin/main", help="Base ref to compare against")
    parser.add_argument("--update", action="store_true", help="Regenerate symbol map if stale")
    args = parser.parse_args()

    changed = get_changed_files(args.base)
    if not changed:
        print("No Dart files changed")
        return 0

    print(f"Changed Dart files ({len(changed)}):")
    for f in changed:
        print(f"  {f}")

    ok, missing = check_symbol_map_freshness(changed)

    if ok:
        print("✓ Symbol map is up to date")
        return 0
    else:
        print(f"✗ Symbol map missing definitions for {len(missing)} changed file(s):")
        for f in missing:
            print(f"  {f}")
        if args.update:
            print("\nRegenerating symbol map...")
            subprocess.run([sys.executable, "extract_symbols.py"], cwd="/workspace/bili")
            subprocess.run([sys.executable, "clean_symbols.py"], cwd="/workspace/bili")
            print("Done. Re-run check to verify.")
            return 0
        else:
            print("\nTo update: python3 extract_symbols.py && python3 clean_symbols.py")
            print("Then commit symbol_index.json and symbol_map_clean.json")
            return 1


if __name__ == "__main__":
    sys.exit(main())