#!/usr/bin/env python3
"""Clean symbol map and build inverted index for LIZ-125."""

import sys
import json
import re
from pathlib import Path
from collections import defaultdict

# Identifier regex for Dart
IDENT_RE = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_]*$')


def is_valid_identifier(name: str) -> bool:
    """Check if name is a valid Dart identifier."""
    return bool(IDENT_RE.match(name)) and len(name) <= 100


def load_raw_map(path: Path) -> dict:
    """Load raw symbol map."""
    with path.open() as f:
        return json.load(f)


def clean_symbols(raw: dict) -> dict:
    """Clean definitions and references."""
    cleaned_symbols = []

    for entry in raw["symbols"]:
        file_path = entry["file"]

        # Deduplicate definitions by (name, line, col)
        defs_seen = set()
        clean_defs = []
        for d in entry["definitions"]:
            key = (d["name"], d["line"], d["col"])
            if key in defs_seen:
                continue
            if not is_valid_identifier(d["name"]):
                continue
            defs_seen.add(key)
            clean_defs.append(d)

        # Filter references: valid identifiers only, deduplicate by (name, line, col)
        refs_seen = set()
        clean_refs = []
        for r in entry["references"]:
            key = (r["name"], r["line"], r["col"])
            if key in refs_seen:
                continue
            if not is_valid_identifier(r["name"]):
                continue
            refs_seen.add(key)
            clean_refs.append(r)

        cleaned_symbols.append({
            "file": file_path,
            "definitions": clean_defs,
            "references": clean_refs,
        })

    return {
        "generated_at": raw["generated_at"],
        "total_files": len(cleaned_symbols),
        "symbols": cleaned_symbols,
    }


def build_index(cleaned: dict) -> dict:
    """Build inverted index: symbol_name -> list of locations."""
    index = defaultdict(list)

    for entry in cleaned["symbols"]:
        file_path = entry["file"]
        rel_path = file_path.replace("/workspace/bili/", "")

        for d in entry["definitions"]:
            index[d["name"]].append({
                "file": rel_path,
                "type": d["type"],
                "line": d["line"],
                "col": d["col"],
            })

    # Sort each symbol's locations by file, then line
    for sym in index:
        index[sym].sort(key=lambda x: (x["file"], x["line"]))

    return dict(index)


def main():
    raw = load_raw_map(Path("/workspace/bili/symbol_map.json"))
    cleaned = clean_symbols(raw)

    # Save cleaned map
    with open("/workspace/bili/symbol_map_clean.json", "w") as f:
        json.dump(cleaned, f, ensure_ascii=False)

    # Build and save index
    index = build_index(cleaned)
    with open("/workspace/bili/symbol_index.json", "w") as f:
        json.dump({
            "generated_at": cleaned["generated_at"],
            "total_symbols": len(index),
            "index": index,
        }, f, ensure_ascii=False)

    # Stats
    total_defs = sum(len(e["definitions"]) for e in cleaned["symbols"])
    total_refs = sum(len(e["references"]) for e in cleaned["symbols"])

    print(f"Cleaned: {cleaned['total_files']} files")
    print(f"  Definitions: {total_defs} (was {sum(len(e['definitions']) for e in raw['symbols'])})")
    print(f"  References: {total_refs} (was {sum(len(e['references']) for e in raw['symbols'])})")
    print(f"Index: {len(index)} unique symbols")


if __name__ == "__main__":
    main()