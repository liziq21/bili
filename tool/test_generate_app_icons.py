"""Tests for the brand icon generator and its committed outputs."""

import json
import re
import struct
import unittest
import xml.etree.ElementTree as ET

import generate_app_icons as icons

SVG_NS = "{http://www.w3.org/2000/svg}"
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"


def png_header(path):
    with open(path, "rb") as handle:
        header = handle.read(26)
    assert header[:8] == b"\x89PNG\r\n\x1a\n", f"{path} is not a PNG"
    width, height = struct.unpack(">II", header[16:24])
    return width, height, header[24], header[25]


class SourceSvgTest(unittest.TestCase):
    def test_foreground_mark_stays_inside_the_adaptive_safe_zone(self):
        tree = ET.parse(icons.BRAND / "app_icon_foreground.svg")
        values = [
            float(number)
            for path in tree.iter(f"{SVG_NS}path")
            for number in re.findall(r"-?\d+(?:\.\d+)?", path.attrib["d"])
        ]
        # The 108dp viewport keeps x/y 18..90 unclipped by any launcher mask.
        # Miter tips extend a few units past the 23/85 vertices.
        miter_allowance = 5
        self.assertGreaterEqual(min(values), 18 + miter_allowance)
        self.assertLessEqual(max(values), 90 - miter_allowance)

    def test_full_icon_has_bone_ground_and_two_mark_paths(self):
        tree = ET.parse(icons.BRAND / "app_icon.svg")
        self.assertEqual(len(list(tree.iter(f"{SVG_NS}rect"))), 1)
        self.assertEqual(len(list(tree.iter(f"{SVG_NS}path"))), 2)


class AndroidVectorsTest(unittest.TestCase):
    def test_foreground_vector_reuses_the_svg_path_data(self):
        tree = ET.parse(icons.BRAND / "app_icon_foreground.svg")
        expected = [path.attrib["d"] for path in tree.iter(f"{SVG_NS}path")]
        vector = ET.parse(
            icons.ANDROID_RES / "main/res/drawable/ic_launcher_foreground.xml"
        )
        actual = [
            path.attrib[f"{ANDROID_NS}pathData"] for path in vector.iter("path")
        ]
        self.assertEqual(actual, expected)

    def test_notification_icon_uses_the_same_mark_as_a_white_mask(self):
        tree = ET.parse(
            icons.ANDROID_RES / "main/res/drawable/ic_notification_icon.xml"
        )
        for path in tree.iter("path"):
            for attribute in ("fillColor", "strokeColor"):
                key = f"{ANDROID_NS}{attribute}"
                if key in path.attrib:
                    self.assertEqual(path.attrib[key], "#FFFFFFFF")

    def test_adaptive_icon_wires_background_foreground_and_monochrome(self):
        tree = ET.parse(
            icons.ANDROID_RES / "main/res/mipmap-anydpi-v26/ic_launcher.xml"
        )
        layers = {
            child.tag: child.attrib[f"{ANDROID_NS}drawable"]
            for child in tree.getroot()
        }
        self.assertEqual(layers["background"], "@drawable/ic_launcher_background")
        self.assertEqual(layers["foreground"], "@drawable/ic_launcher_foreground")
        self.assertEqual(layers["monochrome"], "@drawable/ic_launcher_foreground")


class ColorResourcesTest(unittest.TestCase):
    def test_every_variant_declares_its_palette(self):
        locations = {
            "release": icons.ANDROID_RES / "main/res/values/colors.xml",
            "debug": icons.ANDROID_RES / "debug/res/values/colors.xml",
            "dev": icons.ANDROID_RES / "dev/res/values/colors.xml",
        }
        for variant, path in locations.items():
            colors = {
                element.attrib["name"]: element.text
                for element in ET.parse(path).iter("color")
            }
            background, foreground = icons.VARIANTS[variant]
            self.assertEqual(colors["ic_launcher_background_tint"], background)
            self.assertEqual(colors["ic_launcher_foreground_tint"], foreground)

    def test_variants_are_visually_distinct(self):
        palettes = list(icons.VARIANTS.values())
        self.assertEqual(len(palettes), len(set(palettes)))


class RasterAssetsTest(unittest.TestCase):
    def test_legacy_mipmaps_exist_at_every_density_for_every_variant(self):
        for directory in ("main", "debug", "dev"):
            for density, pixels in icons.MIPMAP_DENSITIES.items():
                path = (
                    icons.ANDROID_RES / directory / "res"
                    / f"mipmap-{density}" / "ic_launcher.png"
                )
                width, height, _, _ = png_header(path)
                self.assertEqual((width, height), (pixels, pixels), path)

    def test_play_store_and_web_icons_have_their_declared_size(self):
        expected = {
            icons.ANDROID_RES / "main/ic_launcher-playstore.png": 512,
            icons.APP / "web/favicon.png": 64,
            icons.APP / "web/icons/Icon-192.png": 192,
            icons.APP / "web/icons/Icon-512.png": 512,
            icons.APP / "web/icons/Icon-maskable-192.png": 192,
            icons.APP / "web/icons/Icon-maskable-512.png": 512,
        }
        for path, pixels in expected.items():
            width, height, _, _ = png_header(path)
            self.assertEqual((width, height), (pixels, pixels), path)

    def test_ios_marketing_icon_is_opaque(self):
        path = (
            icons.APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
            / "Icon-App-1024x1024@1x.png"
        )
        width, height, bit_depth, color_type = png_header(path)
        self.assertEqual((width, height), (1024, 1024))
        self.assertEqual((bit_depth, color_type), (8, 2))

    def test_ios_icon_set_covers_every_contents_entry(self):
        icon_set = icons.APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
        contents = json.loads((icon_set / "Contents.json").read_text())
        for entry in contents["images"]:
            path = icon_set / entry["filename"]
            self.assertTrue(path.exists(), path)
            points = float(entry["size"].split("x")[0])
            scale = int(entry["scale"].rstrip("x"))
            width, height, _, _ = png_header(path)
            self.assertEqual((width, height), (round(points * scale),) * 2, path)


if __name__ == "__main__":
    unittest.main()
