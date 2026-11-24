#!/usr/bin/env python3
"""Contract tests for the ARB translation metadata.

Run from the repo root:
    python3 -m unittest discover -s tool -p 'test_*.py' -v

A translator only sees the `description` and the placeholder metadata, so a
missing or placeholder description is a defect: it forces the translator to
guess the screen, the tone and the role of every `{p1}`.
"""

from __future__ import annotations

import json
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ARB_DIR = REPO_ROOT / 'app' / 'lib' / 'l10n'
TEMPLATE = ARB_DIR / 'app_.arb'
LOCALES = {'zh': ARB_DIR / 'app_zh.arb'}

# Written by the LIZ-51 migration: it records where a string came from, not
# what it means, so it carries no information for a translator.
LEGACY_SENTINEL = 'Migrated from hardcoded literal (LIZ-51 batch base)'


def _load(path: Path) -> dict:
    return json.loads(path.read_text(encoding='utf-8'))


def _message_keys(data: dict) -> list[str]:
    return [key for key in data if not key.startswith('@')]


class ArbMetadataContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.template = _load(TEMPLATE)
        self.locales = {name: _load(path) for name, path in LOCALES.items()}

    def test_every_key_has_metadata(self):
        missing = [
            key
            for key in _message_keys(self.template)
            if f'@{key}' not in self.template
        ]
        self.assertEqual(missing, [], 'keys without an @meta block')

    def test_every_key_has_a_real_description(self):
        offenders = []
        for key in _message_keys(self.template):
            meta = self.template.get(f'@{key}') or {}
            description = (meta.get('description') or '').strip()
            if not description or description == LEGACY_SENTINEL:
                offenders.append(key)
        self.assertEqual(
            offenders,
            [],
            'keys whose description is missing or the migration placeholder',
        )

    def test_every_placeholder_is_documented(self):
        offenders = []
        for key in _message_keys(self.template):
            placeholders = (self.template.get(f'@{key}') or {}).get('placeholders')
            for name, meta in (placeholders or {}).items():
                missing = [
                    field
                    for field in ('type', 'example', 'description')
                    if field not in meta
                ]
                if missing:
                    offenders.append(f'{key}.{name}: {", ".join(missing)}')
        self.assertEqual(offenders, [], 'placeholders missing metadata')

    def test_locales_share_the_template_key_set(self):
        template_keys = _message_keys(self.template)
        for name, data in self.locales.items():
            self.assertEqual(
                _message_keys(data),
                template_keys,
                f'{name} key order or membership differs from the template',
            )

    def test_locales_carry_the_same_metadata(self):
        for name, data in self.locales.items():
            for key in _message_keys(self.template):
                self.assertEqual(
                    (data.get(f'@{key}') or {}).get('placeholders'),
                    (self.template.get(f'@{key}') or {}).get('placeholders'),
                    f'{name}.{key} placeholder metadata differs',
                )


if __name__ == '__main__':
    unittest.main()
