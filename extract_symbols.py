#!/usr/bin/env python3
"""Extract Dart symbols using tree-sitter for LIZ-125."""

import sys
import json
import ctypes
import datetime
from pathlib import Path
from tree_sitter import Language, Parser, Query, QueryCursor

# Load the Dart language from the compiled .so
DART_SO = Path("/tmp/tree-sitter-dart/dart.so")
if not DART_SO.exists():
    print(f"Error: {DART_SO} not found", file=sys.stderr)
    sys.exit(1)

lib = ctypes.CDLL(str(DART_SO))
func = lib.tree_sitter_dart
func.restype = ctypes.c_void_p
ptr = func()

DART_LANGUAGE = Language(ptr)
parser = Parser(DART_LANGUAGE)

# Query for definitions (classes, methods, functions, etc.)
TAGS_QUERIES = [
    # class_definition
    ("definition.class", Query(DART_LANGUAGE, "(class_definition name: (identifier) @name) @definition")),
    # method_signature -> function_signature
    ("definition.method", Query(DART_LANGUAGE, "(method_signature (function_signature name: (identifier) @name)) @definition")),
    # method_signature -> getter_signature
    ("definition.method", Query(DART_LANGUAGE, "(method_signature (getter_signature name: (identifier) @name)) @definition")),
    # method_signature -> setter_signature
    ("definition.method", Query(DART_LANGUAGE, "(method_signature (setter_signature name: (identifier) @name)) @definition")),
    # method_signature -> constructor_signature
    ("definition.method", Query(DART_LANGUAGE, "(method_signature (constructor_signature name: (identifier) @name)) @definition")),
    # method_signature -> factory_constructor_signature (non-redirecting)
    ("definition.method", Query(DART_LANGUAGE, "(method_signature (factory_constructor_signature (identifier) @name)) @definition")),
    # declaration -> redirecting_factory_constructor_signature (redirecting factory)
    ("definition.method", Query(DART_LANGUAGE, "(declaration (redirecting_factory_constructor_signature (identifier) @name)) @definition")),
    # top-level function_signature
    ("definition.function", Query(DART_LANGUAGE, "(function_signature name: (identifier) @name) @definition")),
    # type_alias - first type_identifier is the name
    ("definition.type", Query(DART_LANGUAGE, "(type_alias (type_identifier) @name) @definition")),
    # mixin_declaration
    ("definition.mixin", Query(DART_LANGUAGE, "(mixin_declaration (identifier) @name) @definition")),
    # extension_declaration
    ("definition.extension", Query(DART_LANGUAGE, "(extension_declaration name: (identifier) @name) @definition")),
    # enum_declaration
    ("definition.enum", Query(DART_LANGUAGE, "(enum_declaration (identifier) @name) @definition")),
]

# Query for references
# 1. New expressions
# 2. Simple function calls: expression_statement where first child is identifier and second is selector(argument_part)
# 3. Method calls: selector with unconditional_assignable_selector containing identifier
REFS_QUERIES = [
    ("reference.class", Query(DART_LANGUAGE, "(new_expression (type_identifier) @name) @reference")),
    # Method calls - captures the method name inside unconditional_assignable_selector
    ("reference.call", Query(DART_LANGUAGE, "(expression_statement (selector (unconditional_assignable_selector (identifier) @name))) @reference")),
    # Simple function calls - captures the identifier at start of expression_statement
    # Note: This will also capture object identifiers in method calls, so we filter in Python
    ("reference.call", Query(DART_LANGUAGE, "(expression_statement (identifier) @name (selector (argument_part))) @reference")),
]


def extract_symbols(filepath: Path) -> dict:
    """Extract definitions and references from a Dart file."""
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        return {"error": str(e), "file": str(filepath)}

    tree = parser.parse(bytes(content, "utf-8"))
    root = tree.root_node

    defs = []
    refs = []

    # Extract definitions
    for def_type, query in TAGS_QUERIES:
        cursor = QueryCursor(query)
        captures = cursor.captures(root)
        for capture_name, nodes in captures.items():
            if capture_name == "name":
                for node in nodes:
                    name = content[node.start_byte:node.end_byte]
                    defs.append({
                        "type": def_type,
                        "name": name,
                        "line": node.start_point[0] + 1,
                        "col": node.start_point[1],
                    })

    # Extract references - use matches to distinguish simple vs method calls
    # Method calls
    for ref_type, query in REFS_QUERIES[:2]:  # new_expression and method calls
        cursor = QueryCursor(query)
        captures = cursor.captures(root)
        for capture_name, nodes in captures.items():
            if capture_name == "name":
                for node in nodes:
                    name = content[node.start_byte:node.end_byte]
                    refs.append({
                        "type": ref_type,
                        "name": name,
                        "line": node.start_point[0] + 1,
                        "col": node.start_point[1],
                    })

    # Simple function calls - need to filter out object identifiers in method calls
    query = REFS_QUERIES[2][1]  # simple call query
    cursor = QueryCursor(query)
    for match in cursor.matches(root):
        for capture_name, nodes in match[1].items():
            if capture_name == "name":
                for node in nodes:
                    # Check if this is a simple call or method call
                    # Get the parent expression_statement
                    parent = node.parent
                    while parent and parent.type != "expression_statement":
                        parent = parent.parent
                    if parent and len(parent.children) >= 2:
                        second_child = parent.children[1]
                        # If second child is selector with unconditional_assignable_selector, it's a method call
                        if second_child.type == "selector" and second_child.children:
                            if second_child.children[0].type == "unconditional_assignable_selector":
                                # This is the object identifier in a method call, skip
                                continue
                            elif second_child.children[0].type == "argument_part":
                                # This is a simple function call
                                name = content[node.start_byte:node.end_byte]
                                refs.append({
                                    "type": "reference.call",
                                    "name": name,
                                    "line": node.start_point[0] + 1,
                                    "col": node.start_point[1],
                                })

    return {
        "file": str(filepath),
        "definitions": defs,
        "references": refs,
    }


def main():
    root = Path("/workspace/bili")
    dart_files = list(root.glob("app/lib/**/*.dart")) + \
                 list(root.glob("app/test/**/*.dart")) + \
                 list(root.glob("packages/**/lib/**/*.dart"))

    print(f"Found {len(dart_files)} Dart files", file=sys.stderr)

    all_symbols = []
    for i, f in enumerate(dart_files):
        if i % 50 == 0:
            print(f"Processing {i}/{len(dart_files)}...", file=sys.stderr)
        result = extract_symbols(f)
        if "error" not in result:
            all_symbols.append(result)

    # Output as JSON
    output = {
        "generated_at": datetime.datetime.utcnow().isoformat() + "Z",
        "total_files": len(all_symbols),
        "symbols": all_symbols,
    }
    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()