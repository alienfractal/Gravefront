"""Build the playable units' directional atlases from external/png.

Run from the project root with: python tool/build_unit_atlases.py
The source sprites remain unchanged. Doom-style names contain a frame letter and
viewing rotation; a second frame/rotation pair uses the same image mirrored.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "external" / "png"
OUTPUT = ROOT / "assets" / "images" / "units"

UNITS = {
    "golem": {
        "source": ("Heretic", "Golem", "MUMM"),
        "walk": "ABCD",
        "attack": "EFG",
        "death": "IJKLMNOP",
    },
    "gargoyle": {
        "source": ("Heretic", "Gargoyle", "IMPX"),
        "walk": "ABC",
        "attack": "DEF",
        "death": "GHIJKL",
    },
    "ettin": {
        "source": ("Hexen", "Ettin", "ETTN"),
        "walk": "ABCD",
        "attack": "EFG",
        "death": "IJKLMNOPQ",
    },
    "afrit": {
        "source": ("Hexen", "Afrit", "FDMN"),
        "walk": "ABC",
        "attack": "K",
        "death": "DL",
    },
    "knight": {
        "source": ("Heretic", "Undead Knight", "KNIG"),
        "walk": "ABCD",
        "attack": "EFGH",
        "death": "IJKLMNO",
    },
    "centaur": {
        "source": ("Hexen", "Centaur", "CENT"),
        "walk": "ABCD",
        "attack": "EFG",
        "death": "KLMNOPQRSTU",
    },
    "ophidian": {
        "source": ("Heretic", "Ophidian", "SNKE"),
        "walk": "ABCD",
        "attack": "EF",
        "death": "GHIJKLMNOP",
    },
    "bishop": {
        "source": ("Hexen", "Bishop", "BISH"),
        "walk": "ABCD",
        "attack": "EF",
        "death": "GHIJKLMNOPQRSTUVWX",
    },
    "lich": {
        "source": ("Heretic", "Iron Lich", "LICH"),
        "walk": "AB",
        "attack": "B",
        "death": "CDEFGHI",
    },
    "serpent": {
        "source": ("Hexen", "Chaos Serpent", "DEMN"),
        "walk": "ABCD",
        "attack": "EFG",
        "death": "HIJKLMNOPQ",
    },
}


def read_rotations(folder: Path, prefix: str) -> dict[tuple[str, int], Image.Image]:
    pattern = re.compile(
        rf"^{re.escape(prefix)}([A-Z])([0-8])(?:([A-Z])([0-8]))?\.png$",
        re.IGNORECASE,
    )
    rotations: dict[tuple[str, int], Image.Image] = {}
    for path in folder.glob("*.png"):
        match = pattern.fullmatch(path.name)
        if match is None:
            continue
        image = Image.open(path).convert("RGBA")
        frame, rotation, second_frame, second_rotation = match.groups()
        rotations[(frame.upper(), int(rotation))] = image
        if second_frame is not None and second_rotation is not None:
            rotations[(second_frame.upper(), int(second_rotation))] = image.transpose(
                Image.Transpose.FLIP_LEFT_RIGHT
            )
    return rotations


def build_atlas(
    rotations: dict[tuple[str, int], Image.Image], frames: str, destination: Path
) -> None:
    cells: list[list[Image.Image]] = []
    for frame in frames:
        row = []
        for direction in range(1, 9):
            image = rotations.get((frame, direction)) or rotations.get((frame, 0))
            if image is None:
                raise ValueError(f"Missing {frame} rotation {direction} for {destination}")
            row.append(image)
        cells.append(row)

    cell_width = max(image.width for row in cells for image in row)
    cell_height = max(image.height for row in cells for image in row)
    atlas = Image.new("RGBA", (cell_width * 8, cell_height * len(frames)))
    for row_index, row in enumerate(cells):
        for column_index, image in enumerate(row):
            x = column_index * cell_width + (cell_width - image.width) // 2
            y = row_index * cell_height + cell_height - image.height
            atlas.alpha_composite(image, (x, y))
    atlas.save(destination, optimize=True)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    catalog = {}
    for name, spec in UNITS.items():
        faction, folder, prefix = spec["source"]
        rotations = read_rotations(SOURCE / faction / folder, prefix)
        catalog[name] = {}
        for state in ("walk", "attack", "death"):
            frames = spec[state]
            build_atlas(rotations, frames, OUTPUT / f"{name}_{state}.png")
            catalog[name][state] = frames
        portrait = OUTPUT / name / "a.png"
        portrait.parent.mkdir(parents=True, exist_ok=True)
        if not portrait.exists():
            rotations[(spec["walk"][0], 1)].save(portrait, optimize=True)
    (OUTPUT / "catalog.json").write_text(
        json.dumps(catalog, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Built {len(UNITS) * 3} atlases in {OUTPUT}")


if __name__ == "__main__":
    main()
