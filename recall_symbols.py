#!/usr/bin/env python3
"""Symbol index recall tool for LIZ-125."""

import sys
import json
import argparse
from pathlib import Path

INDEX_PATH = Path("/workspace/bili/symbol_index.json")


def load_index() -> dict:
    with INDEX_PATH.open() as f:
        return json.load(f)


def search(index: dict, query: str, type_filter: str | None = None, fuzzy: bool = False) -> list:
    """Search symbols in index."""
    results = []

    if fuzzy:
        query_lower = query.lower()
        for sym, locations in index.items():
            if query_lower in sym.lower():
                if type_filter is None or any(loc["type"] == type_filter for loc in locations):
                    results.append((sym, locations))
    else:
        # Exact match first
        if query in index:
            locations = index[query]
            if type_filter is None or any(loc["type"] == type_filter for loc in locations):
                results.append((query, locations))
        # Then prefix match
        for sym, locations in index.items():
            if sym.startswith(query) and sym != query:
                if type_filter is None or any(loc["type"] == type_filter for loc in locations):
                    results.append((sym, locations))

    return results


def main():
    parser = argparse.ArgumentParser(description="Symbol index recall")
    parser.add_argument("query", nargs="?", help="Symbol name to search")
    parser.add_argument("--type", help="Filter by definition type (e.g., definition.class)")
    parser.add_argument("--fuzzy", action="store_true", help="Fuzzy substring match")
    parser.add_argument("--list-types", action="store_true", help="List all definition types")
    parser.add_argument("--stats", action="store_true", help="Show index stats")
    args = parser.parse_args()

    data = load_index()
    index = data["index"]

    if args.stats:
        type_counts = {}
        for loc_list in index.values():
            for loc in loc_list:
                type_counts[loc["type"]] = type_counts.get(loc["type"], 0) + 1
        print(f"Total unique symbols: {data['total_symbols']}")
        print("By type:")
        for t, c in sorted(type_counts.items(), key=lambda x: -x[1]):
            print(f"  {t}: {c}")
        return

    if args.list_types:
        types = set()
        for loc_list in index.values():
            for loc in loc_list:
                types.add(loc["type"])
        for t in sorted(types):
            print(t)
        return

    if not args.query:
        parser.print_help()
        return

    results = search(index, args.query, args.type, args.fuzzy)

    if not args.query:
        parser.print_help()
        return

    results = search(index, args.query, args.type, args.fuzzy)

    if not results:
        print(f"No symbols found for '{args.query}'")
        return

    for sym, locations in results:
        print(f"\n{sym}:")
        for loc in locations:
            if args.type is None or loc["type"] == args.type:
                print(f"  {loc['file']}:{loc['line']}:{loc['col']}  ({loc['type']})")


if __name__ == "__main__":
    main()