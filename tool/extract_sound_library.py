"""Extract the complete Heretic and Hexen sound sections from ZDoom Wars.

Usage: python tool/extract_sound_library.py path/to/zdoomwarsiv3.15d.pk3

Each WAD sound is kept in its original format and converted to a listenable WAV.
The matching SNDINFO text is included to identify in-game sound names.
"""

from __future__ import annotations

import json
import struct
import subprocess
import sys
import wave
import zipfile
from pathlib import Path


def wad_lumps(wad: bytes) -> list[tuple[str, bytes]]:
    magic, count, directory = struct.unpack_from("<4sII", wad)
    if magic != b"PWAD":
        raise ValueError("Sounds.wad is not a PWAD")
    lumps = []
    for index in range(count):
        offset, size, raw_name = struct.unpack_from("<II8s", wad, directory + index * 16)
        name = raw_name.rstrip(b"\0").decode("ascii", "replace")
        lumps.append((name, wad[offset : offset + size]))
    return lumps


def convert_doom_sound(payload: bytes, destination: Path) -> None:
    format_id, sample_rate, sample_count = struct.unpack_from("<HHI", payload)
    if format_id != 3 or len(payload) - 8 != sample_count:
        raise ValueError(f"Unexpected Doom sound header for {destination.name}")
    with wave.open(str(destination), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(1)
        sound.setframerate(sample_rate)
        sound.writeframes(payload[8:])


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    source = Path(sys.argv[1])
    destination = Path(__file__).resolve().parents[1] / "external" / "sfx"
    with zipfile.ZipFile(source) as archive:
        lumps = wad_lumps(archive.read("Sounds.wad"))

    markers = {name: index for index, (name, data) in enumerate(lumps) if not data}
    sections = {
        "heretic": (markers["HERETIC"] + 1, markers["HEXEN"], 715),
        "hexen": (markers["HEXEN"] + 1, markers["STRIFE"], 716),
    }
    catalog = {}
    for game, (start, end, sndinfo_index) in sections.items():
        folder = destination / game
        original = folder / "original"
        wav = folder / "wav"
        original.mkdir(parents=True, exist_ok=True)
        wav.mkdir(parents=True, exist_ok=True)
        (folder / "SNDINFO.txt").write_bytes(lumps[sndinfo_index][1])
        entries = []
        for name, payload in lumps[start:end]:
            if payload.startswith(b"OggS"):
                source_path = original / f"{name}.ogg"
                source_path.write_bytes(payload)
                subprocess.run(
                    [
                        "ffmpeg", "-y", "-loglevel", "error", "-i", str(source_path),
                        "-ac", "1", "-ar", "22050", "-c:a", "pcm_s16le",
                        str(wav / f"{name}.wav"),
                    ],
                    check=True,
                )
                sound_format = "ogg"
            elif payload[:2] == b"\x03\0":
                source_path = original / f"{name}.lmp"
                source_path.write_bytes(payload)
                convert_doom_sound(payload, wav / f"{name}.wav")
                sound_format = "doom"
            else:
                raise ValueError(f"Unknown sound format: {game}/{name}")
            entries.append({"lump": name, "format": sound_format})
        catalog[game] = entries
        print(f"{game}: {len(entries)} sounds")
    (destination / "catalog.json").write_text(
        json.dumps(catalog, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Saved original sounds, WAV previews, and SNDINFO to {destination}")


if __name__ == "__main__":
    main()
