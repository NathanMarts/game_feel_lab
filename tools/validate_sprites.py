"""Validate the actual traveler PNG used by the Godot atlas. Requires Pillow."""
from pathlib import Path
from PIL import Image

ASSET = Path(__file__).resolve().parents[1] / "assets" / "traveler_sheet.png"
CELL = 48
COLUMNS = 5
ROWS = 2
BASELINE = 46

def validate() -> None:
    with Image.open(ASSET) as image:
        assert image.size == (COLUMNS * CELL, ROWS * CELL), (
            f"Expected 240x96 image, found {image.size}"
        )
        assert image.info.get("transparency") is not None or "A" in image.getbands(), (
            "Sheet needs transparent background"
        )
        sheet = image.convert("RGBA")
    for row in range(ROWS):
        for col in range(COLUMNS):
            frame = sheet.crop(
                (col * CELL, row * CELL, (col + 1) * CELL, (row + 1) * CELL)
            )
            alpha = frame.getchannel("A")
            bounds = alpha.getbbox()
            assert bounds is not None, f"Frame {row},{col} is empty"
            assert 0 <= bounds[0] and bounds[2] <= CELL
            assert abs(bounds[3] - BASELINE) <= 1, (
                f"Frame {row},{col}: foot alignment drift at y={bounds[3]}"
            )
            assert alpha.getpixel((0, 0)) == 0, (
                f"Frame {row},{col} lost transparent margins"
            )
    print("OK: 5 idle + 5 run frames, fixed 48x48 grid, transparent margins, stable foot baseline.")

if __name__ == "__main__":
    validate()
