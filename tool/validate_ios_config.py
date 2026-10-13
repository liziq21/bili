#!/usr/bin/env python3
"""Validate iOS project configuration without requiring Xcode or CocoaPods."""

from __future__ import annotations

import plistlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INFO_PLIST = ROOT / 'app/ios/Runner/Info.plist'
PROJECT = ROOT / 'app/ios/Runner.xcodeproj/project.pbxproj'
PODFILE = ROOT / 'app/ios/Podfile'


def _version_tuple(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split('.'))


def main() -> int:
    errors: list[str] = []

    for path in (INFO_PLIST, PROJECT, PODFILE):
        if not path.is_file():
            errors.append(f'missing required iOS configuration: {path.relative_to(ROOT)}')

    if errors:
        _report(errors)
        return 1

    with INFO_PLIST.open('rb') as file:
        info_plist = plistlib.load(file)
    project = PROJECT.read_text(encoding='utf-8')
    podfile = PODFILE.read_text(encoding='utf-8')

    expected_plist_values = {
        'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)',
        'CFBundleShortVersionString': '$(FLUTTER_BUILD_NAME)',
        'CFBundleVersion': '$(FLUTTER_BUILD_NUMBER)',
    }
    for key, expected in expected_plist_values.items():
        actual = info_plist.get(key)
        if actual != expected:
            errors.append(
                f'app/ios/Runner/Info.plist: {key} must be {expected!r}, '
                f'found {actual!r}'
            )

    deployment_targets = re.findall(
        r'IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([^;]+);',
        project,
    )
    if not deployment_targets:
        errors.append('Runner.xcodeproj: no iOS deployment target was found')
    elif len(set(deployment_targets)) != 1:
        errors.append(
            'Runner.xcodeproj: iOS deployment targets must agree, found '
            + ', '.join(sorted(set(deployment_targets)))
        )

    platform_match = re.search(
        r'^\s*platform\s*:ios,\s*[\'\"]([^\'\"]+)[\'\"]',
        podfile,
        re.MULTILINE,
    )
    if platform_match is None:
        errors.append('Podfile: an iOS platform version is required')
    elif deployment_targets and deployment_targets[0] != platform_match.group(1):
        errors.append(
            'Podfile and Runner.xcodeproj must use the same iOS deployment target: '
            f"{platform_match.group(1)} vs {deployment_targets[0]}"
        )

    if platform_match is not None:
        try:
            if _version_tuple(platform_match.group(1)) < (13,):
                errors.append('Podfile: iOS platform version is below the supported minimum')
        except ValueError:
            errors.append(
                'Podfile: iOS platform version must contain only numeric components'
            )

    required_project_settings = {
        'INFOPLIST_FILE = Runner/Info.plist;': 'Info.plist reference',
        'CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";': 'build number mapping',
        'PRODUCT_BUNDLE_IDENTIFIER = ': 'bundle identifier setting',
    }
    for setting, description in required_project_settings.items():
        if project.count(setting) < 3:
            errors.append(
                f'Runner.xcodeproj: expected {description} in Debug, Profile, and '
                f'Release target configurations'
            )

    if 'flutter_install_all_ios_pods' not in podfile:
        errors.append('Podfile: Flutter iOS pod integration is not configured')

    if errors:
        _report(errors)
        return 1

    print('iOS static configuration checks passed.')
    return 0


def _report(errors: list[str]) -> None:
    print('iOS static configuration checks failed:', file=sys.stderr)
    for error in errors:
        print(f'- {error}', file=sys.stderr)


if __name__ == '__main__':
    raise SystemExit(main())
