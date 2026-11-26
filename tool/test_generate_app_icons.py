"""Tests for the brand icon generator and its committed outputs."""

import json
import math
import re
import struct
import unittest
import xml.etree.ElementTree as ET
import zlib

import generate_app_icons as icons

SVG_NS = "{http://www.w3.org/2000/svg}"
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"

# Kept independent of the generator so dropping a density from the generator
# cannot silently drop it from this check too.
REQUIRED_MIPMAP_DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def png_header(path):
    with open(path, "rb") as handle:
        header = handle.read(26)
    assert header[:8] == b"\x89PNG\r\n\x1a\n", f"{path} is not a PNG"
    width, height = struct.unpack(">II", header[16:24])
    return width, height, header[24], header[25]


def png_alpha_values(path):
    """Decode an 8-bit RGB(A) PNG (no interlace) and return every alpha byte."""
    data = path.read_bytes()
    width, height = struct.unpack(">II", data[16:24])
    bit_depth, color_type = data[24], data[25]
    assert bit_depth == 8 and color_type in (2, 6), f"{path} is not 8-bit RGB(A)"
    offset, idat = 8, b""
    while offset < len(data):
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        body = data[offset + 8:offset + 8 + length]
        if kind == b"IDAT":
            idat += body
        offset += 12 + length
    raw = zlib.decompress(idat)
    bpp = 4 if color_type == 6 else 3
    stride = width * bpp
    previous = bytearray(stride)
    alphas = []
    position = 0
    for _ in range(height):
        filter_type = raw[position]
        line = bytearray(raw[position + 1:position + 1 + stride])
        position += 1 + stride
        for index in range(stride):
            left = line[index - bpp] if index >= bpp else 0
            up = previous[index]
            upper_left = previous[index - bpp] if index >= bpp else 0
            if filter_type == 1:
                line[index] = (line[index] + left) & 0xFF
            elif filter_type == 2:
                line[index] = (line[index] + up) & 0xFF
            elif filter_type == 3:
                line[index] = (line[index] + (left + up) // 2) & 0xFF
            elif filter_type == 4:
                estimate = left + up - upper_left
                pa, pb, pc = (abs(estimate - left), abs(estimate - up),
                              abs(estimate - upper_left))
                predictor = left if pa <= pb and pa <= pc else (
                    up if pb <= pc else upper_left
                )
                line[index] = (line[index] + predictor) & 0xFF
        alphas.extend(line[3::4] if color_type == 6 else [255] * width)
        previous = line
    return width, height, alphas


def polygon(path_data):
    """Points of a path that only uses absolute M/L/H/V/Z commands."""
    tokens = re.findall(r"[MLHVZ]|-?\d+(?:\.\d+)?", path_data)
    points, index = [], 0
    x = y = start_x = start_y = 0.0
    while index < len(tokens):
        command = tokens[index]
        index += 1
        if command in "ML":
            x, y = float(tokens[index]), float(tokens[index + 1])
            index += 2
        elif command == "H":
            x = float(tokens[index])
            index += 1
        elif command == "V":
            y = float(tokens[index])
            index += 1
        elif command == "Z":
            points.append((start_x, start_y))
            continue
        if not points:
            start_x, start_y = x, y
        points.append((x, y))
    return points


def stroked_bounds(path_data, stroke_width):
    """Axis-aligned bounds of a closed polygon plus its miter joins."""
    points = polygon(path_data)[:-1]
    half = stroke_width / 2
    bounds = [(min(p[0] for p in points), min(p[1] for p in points)),
              (max(p[0] for p in points), max(p[1] for p in points))]
    for index, point in enumerate(points):
        before = points[index - 1]
        after = points[(index + 1) % len(points)]
        vectors = []
        for neighbour in (before, after):
            dx, dy = neighbour[0] - point[0], neighbour[1] - point[1]
            length = math.hypot(dx, dy)
            vectors.append((dx / length, dy / length))
        bisector = (-(vectors[0][0] + vectors[1][0]),
                    -(vectors[0][1] + vectors[1][1]))
        length = math.hypot(*bisector)
        if length < 1e-9:  # collinear edges: no miter extension
            continue
        half_angle = math.acos(max(-1.0, min(1.0, sum(
            a * b for a, b in zip(vectors[0], vectors[1])
        )))) / 2
        miter = half / math.sin(half_angle)
        bounds.append((point[0] + bisector[0] / length * miter,
                       point[1] + bisector[1] / length * miter))
    return (min(p[0] for p in bounds), min(p[1] for p in bounds),
            max(p[0] for p in bounds), max(p[1] for p in bounds))


class SourceSvgTest(unittest.TestCase):
    def test_stroked_mark_stays_inside_the_adaptive_safe_zone(self):
        tree = ET.parse(icons.BRAND / "app_icon_foreground.svg")
        stroked = next(
            path for path in tree.iter(f"{SVG_NS}path")
            if "stroke" in path.attrib
        )
        left, top, right, bottom = stroked_bounds(
            stroked.attrib["d"], float(stroked.attrib["stroke-width"])
        )
        # The 108dp viewport guarantees the central 72dp square (18..90).
        self.assertGreaterEqual(left, 18)
        self.assertGreaterEqual(top, 18)
        self.assertLessEqual(right, 90)
        self.assertLessEqual(bottom, 90)

    def test_full_icon_draws_the_mark_on_the_bone_ground(self):
        tree = ET.parse(icons.BRAND / "app_icon.svg")
        ground, ink = icons.VARIANTS["release"]
        rectangles = list(tree.iter(f"{SVG_NS}rect"))
        self.assertEqual(len(rectangles), 1)
        self.assertEqual(rectangles[0].attrib["fill"], ground)
        paths = list(tree.iter(f"{SVG_NS}path"))
        self.assertEqual(len(paths), 2)
        for path in paths:
            self.assertTrue(path.attrib["d"], "empty path data")
            paint = path.attrib.get("fill", "none") + path.attrib.get("stroke", "")
            self.assertIn(ink, paint, "path is not painted with the brand ink")


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
        # Android fills a path unless fillColor says otherwise; the outline
        # must be explicitly transparent or the eye renders as a solid blob.
        stroke_path = next(
            path for path in vector.iter("path")
            if f"{ANDROID_NS}strokeWidth" in path.attrib
        )
        self.assertEqual(
            stroke_path.attrib[f"{ANDROID_NS}fillColor"], "#00000000"
        )

    def test_notification_icon_uses_the_same_mark_as_a_white_mask(self):
        tree = ET.parse(
            icons.ANDROID_RES / "main/res/drawable/ic_notification_icon.xml"
        )
        paths = list(tree.iter("path"))
        self.assertEqual(len(paths), 2)
        for path in paths:
            self.assertTrue(path.attrib[f"{ANDROID_NS}pathData"])
        outline, pupil = paths
        self.assertEqual(outline.attrib[f"{ANDROID_NS}fillColor"], "#00000000")
        self.assertEqual(outline.attrib[f"{ANDROID_NS}strokeColor"], "#FFFFFFFF")
        self.assertEqual(pupil.attrib[f"{ANDROID_NS}fillColor"], "#FFFFFFFF")

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
        self.assertEqual(icons.MIPMAP_DENSITIES, REQUIRED_MIPMAP_DENSITIES)
        for directory in ("main", "debug", "dev"):
            for density, pixels in REQUIRED_MIPMAP_DENSITIES.items():
                path = (
                    icons.ANDROID_RES / directory / "res"
                    / f"mipmap-{density}" / "ic_launcher.png"
                )
                width, height, _, _ = png_header(path)
                self.assertEqual((width, height), (pixels, pixels), path)

    def test_play_store_icon_is_512_and_32_bit(self):
        path = icons.ANDROID_RES / "main/ic_launcher-playstore.png"
        width, height, bit_depth, color_type = png_header(path)
        self.assertEqual((width, height), (512, 512))
        self.assertEqual((bit_depth, color_type), (8, 6))

    def test_web_icons_have_their_declared_size(self):
        expected = {
            icons.APP / "web/favicon.png": 64,
            icons.APP / "web/icons/Icon-192.png": 192,
            icons.APP / "web/icons/Icon-512.png": 512,
            icons.APP / "web/icons/Icon-maskable-192.png": 192,
            icons.APP / "web/icons/Icon-maskable-512.png": 512,
        }
        for path, pixels in expected.items():
            width, height, _, _ = png_header(path)
            self.assertEqual((width, height), (pixels, pixels), path)

    def test_maskable_web_icons_have_no_transparent_edges(self):
        for name in ("Icon-maskable-192.png", "Icon-maskable-512.png"):
            width, height, alphas = png_alpha_values(
                icons.APP / "web/icons" / name
            )
            self.assertEqual(len(alphas), width * height)
            self.assertEqual(min(alphas), 255, f"{name} has transparent pixels")

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
