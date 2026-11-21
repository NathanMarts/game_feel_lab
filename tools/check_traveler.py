"""Validate the published V2 traveler spritesheet (requires Pillow)."""
from pathlib import Path
from PIL import Image

SPRITE = Path(__file__).resolve().parents[1] / "assets" / "traveler_sheet_v2.png"
CELL = 96

def check() -> None:
    sheet = Image.open(SPRITE).convert("RGBA")
    assert sheet.size == (480, 192), f"Unexpected atlas size {sheet.size}"
    for row in range(2):
        signatures = []
        for col in range(5):
            frame = sheet.crop((col * CELL, row * CELL, (col + 1) * CELL, (row + 1) * CELL))
            mask = frame.getchannel("A").point(lambda alpha: 255 if alpha > 120 else 0)
            bbox = mask.getbbox()
            assert bbox is not None, f"Empty frame {row}:{col}"
            assert bbox[0] >= 8 and bbox[2] <= 88, f"Cropped at edge: {row}:{col} {bbox}"
            assert abs((bbox[0] + bbox[2]) / 2 - 48) <= 3, f"Horizontal drift {row}:{col}"
            feet = 79 if (row, col) == (1, 3) else 86
            assert bbox[3] == feet, f"Foot baseline drift {row}:{col}: {bbox[3]} != {feet}"
            signatures.append(frame.tobytes())
        assert len(set(signatures)) == 5, f"Duplicate frames on row {row}"
    print("PASS: 10 distinct frames, consistent 96x96 grid, alpha, and anchors")

if __name__ == "__main__":
    check()
