#!/usr/bin/env python3
"""Contract tests for the ARB translation metadata.

Run from the repo root:
    python3 -m unittest discover -s tool -p 'test_*.py' -v

A translator only sees the `description` and the placeholder metadata, so a
missing, placeholder or wrong description is a defect: it forces the
translator to guess the screen, the tone and the role of every `{p1}`.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ARB_DIR = REPO_ROOT / 'app' / 'lib' / 'l10n'
TEMPLATE = ARB_DIR / 'app_.arb'
LOCALES = {'zh': ARB_DIR / 'app_zh.arb'}

# Written by the LIZ-51 migration and its follow-ups: they record where a
# string came from, not what it means, so they carry no information for a
# translator. Match the prefix so a new variant cannot slip through.
_LEGACY_DESCRIPTION = re.compile(r'^Migrated from hardcoded literal\b')

# `{p1}` and `{count, plural, ...}`; the `=1{...}` branches of an ICU plural
# start with a non-word character and are not matched.
_PLACEHOLDER_REF = re.compile(r'\{(\w+)\s*[,}]')


def _load(path: Path) -> dict:
    return json.loads(path.read_text(encoding='utf-8'))


def _message_keys(data: dict) -> list[str]:
    return [key for key in data if not key.startswith('@')]


def _referenced_placeholders(message: str) -> set[str]:
    return set(_PLACEHOLDER_REF.findall(message))


class ArbMetadataContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.template = _load(TEMPLATE)
        self.locales = {name: _load(path) for name, path in LOCALES.items()}
        self.files = {'en': self.template, **self.locales}

    def test_every_key_has_metadata(self):
        for name, data in self.files.items():
            missing = [
                key for key in _message_keys(data) if f'@{key}' not in data
            ]
            self.assertEqual(missing, [], f'{name}: keys without an @meta block')

    def test_every_key_has_a_real_description(self):
        for name, data in self.files.items():
            offenders = []
            for key in _message_keys(data):
                meta = data.get(f'@{key}') or {}
                description = (meta.get('description') or '').strip()
                if not description or _LEGACY_DESCRIPTION.search(description):
                    offenders.append(key)
            self.assertEqual(
                offenders,
                [],
                f'{name}: description missing or still the migration placeholder',
            )

    def test_every_placeholder_is_documented(self):
        for name, data in self.files.items():
            offenders = []
            for key in _message_keys(data):
                placeholders = (data.get(f'@{key}') or {}).get('placeholders') or {}
                for placeholder in sorted(_referenced_placeholders(data[key])):
                    meta = placeholders.get(placeholder)
                    if meta is None:
                        offenders.append(f'{key}: {placeholder} has no metadata')
                        continue
                    for field in ('type', 'example', 'description'):
                        if not str(meta.get(field) or '').strip():
                            offenders.append(f'{key}.{placeholder}: empty {field}')
            self.assertEqual(
                offenders, [], f'{name}: incomplete placeholder metadata'
            )

    def test_no_orphan_placeholder_metadata(self):
        for name, data in self.files.items():
            offenders = []
            for key in _message_keys(data):
                placeholders = (data.get(f'@{key}') or {}).get('placeholders') or {}
                offenders.extend(
                    f'{key}: {placeholder} is documented but not used'
                    for placeholder in sorted(
                        set(placeholders) - _referenced_placeholders(data[key])
                    )
                )
            self.assertEqual(offenders, [], f'{name}: stale placeholder metadata')

    def test_locales_share_the_template_key_set(self):
        template_keys = _message_keys(self.template)
        for name, data in self.locales.items():
            self.assertEqual(
                _message_keys(data),
                template_keys,
                f'{name} key order or membership differs from the template',
            )

    def test_locales_carry_the_same_placeholder_metadata(self):
        for name, data in self.locales.items():
            for key in _message_keys(self.template):
                self.assertEqual(
                    (data.get(f'@{key}') or {}).get('placeholders'),
                    (self.template.get(f'@{key}') or {}).get('placeholders'),
                    f'{name}.{key} placeholder metadata differs',
                )


if __name__ == '__main__':
    unittest.main()
