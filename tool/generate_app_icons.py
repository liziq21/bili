#!/usr/bin/env python3
"""Regenerate every raster and Android-vector derivative of the brand icon.

Source of truth: app/assets/brand/app_icon.svg (full square) and
app/assets/brand/app_icon_foreground.svg (the mark on a transparent ground).
Geometry is never duplicated here; the Android vectors reuse the exact path
data parsed out of the SVG, and every raster is rendered from an SVG document
built around the same markup.

Requirements: rsvg-convert (librsvg), Pillow for stripping the alpha channel
from iOS icons. Neither is needed by the app at runtime.

Usage:
    python3 tool/generate_app_icons.py
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "app"
BRAND = APP / "assets" / "brand"
ANDROID_RES = APP / "android" / "app" / "src"

SVG_NS = "http://www.w3.org/2000/svg"

# Background / ink pairs. Keep in sync with the colors.xml files; the script
# rewrites those too so a palette change cannot drift from the bitmaps.
VARIANTS = {
    "release": ("#F8ECE5", "#B75B1E"),
    "debug": ("#1E1B18", "#EFA97C"),
    "dev": ("#B75B1E", "#F8ECE5"),
}

# Legacy launcher densities (pre-API 26 bitmaps).
MIPMAP_DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

# Android splash bitmaps, by density.
SPLASH_DENSITIES = {
    "mdpi": 128,
    "hdpi": 192,
    "xhdpi": 256,
    "xxhdpi": 384,
    "xxxhdpi": 512,
}


def _log(message: str) -> None:
    print(message)


def _require(tool: str) -> None:
    if shutil.which(tool) is None:
        sys.exit(f"missing dependency: {tool} (install librsvg2-bin)")


def _load_svg(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _svg_body(svg_text: str) -> str:
    """Inner markup of an SVG document, without the root element."""
    start = svg_text.index(">", svg_text.index("<svg")) + 1
    end = svg_text.rindex("</svg>")
    return svg_text[start:end]


def _svg_document(body: str, *, width: int = 108, height: int = 108,
                  view_box: str = "0 0 108 108") -> str:
    return (
        f'<svg xmlns="{SVG_NS}" width="{width}" height="{height}" '
        f'viewBox="{view_box}">{body}</svg>'
    )


def _recolor(body: str, background: str | None, ink: str) -> str:
    mapping = {"#B75B1E": ink}
    if background is not None:
        mapping["#F8ECE5"] = background
    # Single pass: a sequential replace would re-tint the ink when the
    # variant swaps the two colours (the dev variant does exactly that).
    return re.sub("|".join(mapping), lambda match: mapping[match.group(0)], body)


def _render(svg_text: str, size: int, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["rsvg-convert", "-w", str(size), "-h", str(size),
         "-o", str(destination)],
        input=svg_text.encode("utf-8"),
        check=True,
    )


def _render_opaque(svg_text: str, size: int, destination: Path) -> None:
    """Render a PNG without an alpha channel (App Store requirement)."""
    _render_converted(svg_text, size, destination, "RGB")


def _render_rgba(svg_text: str, size: int, destination: Path) -> None:
    """Render a 32-bit RGBA PNG (Play Store requirement)."""
    _render_converted(svg_text, size, destination, "RGBA")


def _render_converted(svg_text: str, size: int, destination: Path,
                      mode: str) -> None:
    try:
        from PIL import Image
    except ImportError:  # pragma: no cover - depends on host packages
        sys.exit("missing dependency: Pillow (pip install pillow)")
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.png"
        _render(svg_text, size, raw)
        with Image.open(raw) as image:
            image.convert(mode).save(destination, format="PNG", optimize=True)


def android_vector_paths() -> list[dict[str, str]]:
    """Extract drawable paths from the foreground SVG as attribute dicts."""
    tree = ET.parse(BRAND / "app_icon_foreground.svg")
    paths = []
    for element in tree.iter(f"{{{SVG_NS}}}path"):
        attrs = dict(element.attrib)
        paths.append(attrs)
    if len(paths) != 2:
        sys.exit(f"expected 2 paths in the foreground SVG, found {len(paths)}")
    return paths


def write_android_vectors() -> None:
    drawables = ANDROID_RES / "main" / "res" / "drawable"

    path_lines = []
    for attrs in android_vector_paths():
        attributes = [f'android:pathData="{attrs["d"]}"']
        if attrs.get("fill", "none") != "none":
            attributes.append(
                'android:fillColor="@color/ic_launcher_foreground_tint"'
            )
        if "stroke" in attrs:
            attributes.append(
                'android:strokeColor="@color/ic_launcher_foreground_tint"'
            )
            attributes.append(f'android:strokeWidth="{attrs["stroke-width"]}"')
            attributes.append(f'android:strokeLineJoin="{attrs.get("stroke-linejoin", "miter")}"')
            attributes.append(f'android:strokeLineCap="{attrs.get("stroke-linecap", "butt")}"')
        path_lines.append("    <path\n        " + "\n        ".join(attributes) + " />")

    foreground = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Generated by tool/generate_app_icons.py from\n"
        "     app/assets/brand/app_icon_foreground.svg. Do not edit by hand. -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="108dp"\n'
        '    android:height="108dp"\n'
        '    android:viewportWidth="108"\n'
        '    android:viewportHeight="108">\n'
        + "\n".join(path_lines)
        + "\n</vector>\n"
    )
    (drawables / "ic_launcher_foreground.xml").write_text(foreground, encoding="utf-8")

    background = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Generated by tool/generate_app_icons.py. Do not edit by hand. -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="108dp"\n'
        '    android:height="108dp"\n'
        '    android:viewportWidth="108"\n'
        '    android:viewportHeight="108">\n'
        '    <path\n'
        '        android:pathData="M0,0h108v108h-108z"\n'
        '        android:fillColor="@color/ic_launcher_background_tint" />\n'
        "</vector>\n"
    )
    (drawables / "ic_launcher_background.xml").write_text(
        background, encoding="utf-8"
    )

    # Notification small icons are tinted by the system from their alpha
    # channel; a fixed white fill keeps them usable when they are not.
    notification_paths = []
    for attrs in android_vector_paths():
        attributes = [f'android:pathData="{attrs["d"]}"']
        if attrs.get("fill", "none") != "none":
            attributes.append('android:fillColor="#FFFFFFFF"')
        if "stroke" in attrs:
            attributes.append('android:strokeColor="#FFFFFFFF"')
            attributes.append(f'android:strokeWidth="{attrs["stroke-width"]}"')
            attributes.append(f'android:strokeLineJoin="{attrs.get("stroke-linejoin", "miter")}"')
            attributes.append(f'android:strokeLineCap="{attrs.get("stroke-linecap", "butt")}"')
        notification_paths.append("    <path\n        " + "\n        ".join(attributes) + " />")

    notification = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Generated by tool/generate_app_icons.py. Do not edit by hand. -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="24dp"\n'
        '    android:height="24dp"\n'
        '    android:viewportWidth="108"\n'
        '    android:viewportHeight="108">\n'
        + "\n".join(notification_paths)
        + "\n</vector>\n"
    )
    (drawables / "ic_notification_icon.xml").write_text(
        notification, encoding="utf-8"
    )
    _log("android vectors: foreground, background, notification")


def write_color_resources() -> None:
    template = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        "    <!-- Launcher icon tints, referenced by ic_launcher_background /\n"
        "         ic_launcher_foreground. Each build variant overrides them so\n"
        "         builds are distinguishable at a glance (same approach as\n"
        "         android/nowinandroid). Generated by\n"
        "         tool/generate_app_icons.py. -->\n"
        '    <color name="ic_launcher_background_tint">{background}</color>\n'
        '    <color name="ic_launcher_foreground_tint">{foreground}</color>\n'
        "</resources>\n"
    )
    targets = {
        "release": ANDROID_RES / "main" / "res" / "values" / "colors.xml",
        "debug": ANDROID_RES / "debug" / "res" / "values" / "colors.xml",
        "dev": ANDROID_RES / "dev" / "res" / "values" / "colors.xml",
    }
    for variant, destination in targets.items():
        background, foreground = VARIANTS[variant]
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(
            template.format(background=background, foreground=foreground),
            encoding="utf-8",
        )
    _log("android colors: release, debug, dev")


def full_icon_svg(variant: str, *, rounded: bool = False) -> str:
    background, ink = VARIANTS[variant]
    body = _recolor(_svg_body(_load_svg(BRAND / "app_icon.svg")), background, ink)
    if rounded:
        body = (
            '<defs><clipPath id="squircle">'
            '<rect width="108" height="108" rx="24" ry="24"/>'
            "</clipPath></defs>"
            '<g clip-path="url(#squircle)">'
            + body
            + "</g>"
        )
    return _svg_document(body)


def foreground_svg(variant: str, *, background: str | None = None) -> str:
    _, ink = VARIANTS[variant]
    body = _recolor(_svg_body(_load_svg(BRAND / "app_icon_foreground.svg")), background, ink)
    if background is not None:
        body = f'<rect width="108" height="108" fill="{background}"/>' + body
    return _svg_document(body)


def write_android_bitmaps() -> None:
    for variant in VARIANTS:
        for density, size in MIPMAP_DENSITIES.items():
            if variant == "release":
                destination = (
                    ANDROID_RES / "main" / "res" / f"mipmap-{density}"
                    / "ic_launcher.png"
                )
            else:
                destination = (
                    ANDROID_RES / variant / "res" / f"mipmap-{density}"
                    / "ic_launcher.png"
                )
            _render(full_icon_svg(variant, rounded=True), size, destination)
        _log(f"android mipmaps: {variant}")

    _render_rgba(
        full_icon_svg("release"),
        512,
        ANDROID_RES / "main" / "ic_launcher-playstore.png",
    )
    _log("play store: ic_launcher-playstore.png")


def write_splash_icons() -> None:
    for density, size in SPLASH_DENSITIES.items():
        _render(
            foreground_svg("release"),
            size,
            ANDROID_RES / "main" / "res" / f"drawable-{density}" / "splash.png",
        )
        _render(
            foreground_svg("debug"),
            size,
            ANDROID_RES / "main" / "res" / f"drawable-night-{density}"
            / "splash.png",
        )

    ios = APP / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    for filename, size in {
        "LaunchImage.png": 128,
        "LaunchImage@2x.png": 256,
        "LaunchImage@3x.png": 384,
    }.items():
        _render(foreground_svg("release"), size, ios / filename)
    for filename, size in {
        "LaunchImageDark.png": 128,
        "LaunchImageDark@2x.png": 256,
        "LaunchImageDark@3x.png": 384,
    }.items():
        _render(foreground_svg("debug"), size, ios / filename)
    _log("splash: android light/night, ios light/dark")


def write_ios_icons() -> None:
    icon_set = APP / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    contents = json.loads((icon_set / "Contents.json").read_text(encoding="utf-8"))
    sizes = set()
    for entry in contents["images"]:
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        pixels = round(points * scale)
        sizes.add(pixels)
        _render_opaque(full_icon_svg("release"), pixels, icon_set / entry["filename"])
    _log(f"ios app icons: {len(contents['images'])} files ({sorted(sizes)} px)")


def write_web_icons() -> None:
    web = APP / "web"
    _render(full_icon_svg("release"), 192, web / "icons" / "Icon-192.png")
    _render(full_icon_svg("release"), 512, web / "icons" / "Icon-512.png")
    # Maskable icons are full-bleed: the mark already sits inside the inner
    # 80% safe circle, so the square ground can cover the whole canvas.
    _render(
        full_icon_svg("release"),
        192,
        web / "icons" / "Icon-maskable-192.png",
    )
    _render(
        full_icon_svg("release"),
        512,
        web / "icons" / "Icon-maskable-512.png",
    )
    _render(full_icon_svg("release", rounded=True), 64, web / "favicon.png")
    _log("web: favicon, PWA icons, maskable icons")


def main() -> None:
    _require("rsvg-convert")
    write_android_vectors()
    write_color_resources()
    write_android_bitmaps()
    write_splash_icons()
    write_ios_icons()
    write_web_icons()


if __name__ == "__main__":
    main()
