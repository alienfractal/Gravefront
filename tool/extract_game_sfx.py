"""Extract selected ZDoom Wars sounds and make Windows-friendly WAV copies.

Usage: python tool/extract_game_sfx.py path/to/zdoomwarsiv3.15d.pk3
"""

from __future__ import annotations

import struct
import subprocess
import sys
import zipfile
from pathlib import Path


LUMPS = {
    "ARTIUSE": "summon.ogg",
    "MUMAT2": "golem_attack.ogg",
    "MUMPAI": "golem_hurt.ogg",
    "MUMDTH": "golem_death.ogg",
    "IMPAT1": "gargoyle_attack.ogg",
    "IMPPAI": "gargoyle_hurt.ogg",
    "IMPDTH": "gargoyle_death.ogg",
    "ETHIT1": "ettin_attack.ogg",
    "CENT1": "ettin_hurt.ogg",
    "CNTDTH1": "ettin_death.ogg",
    "SPIT6": "afrit_attack.ogg",
    "FIRED2": "afrit_hurt.ogg",
    "FIRED3": "afrit_death.ogg",
    "KGTAT2": "knight_attack.ogg",
    "KGTPAI": "knight_hurt.ogg",
    "KGTDTH": "knight_death.ogg",
    "CENTHIT2": "centaur_attack.ogg",
    "TAUR4": "centaur_hurt.ogg",
    "SNKATK": "ophidian_attack.ogg",
    "SNKPAI": "ophidian_hurt.ogg",
    "SNKDTH": "ophidian_death.ogg",
    "POP": "bishop_attack.ogg",
    "BSHPN1": "bishop_hurt.ogg",
    "BISHDTH1": "bishop_death.ogg",
    "HEDAT1": "lich_attack.ogg",
    "HEDPAI": "lich_hurt.ogg",
    "HEDDTH": "lich_death.ogg",
    "WTRSWIP": "serpent_attack.ogg",
    "SERPPN1": "serpent_hurt.ogg",
    "SRPDTH1": "serpent_death.ogg",
}

ALIASES = {"centaur_death.ogg": "ettin_death.ogg"}


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    source = Path(sys.argv[1])
    target = Path(__file__).resolve().parents[1] / "assets" / "audio"
    target.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(source) as archive:
        wad = archive.read("Sounds.wad")
    magic, count, directory = struct.unpack_from("<4sII", wad)
    if magic != b"PWAD":
        raise ValueError("Sounds.wad is not a PWAD")
    remaining = set(LUMPS)
    for index in range(count):
        offset, size, raw_name = struct.unpack_from("<II8s", wad, directory + index * 16)
        name = raw_name.rstrip(b"\0").decode("ascii", "replace")
        if name not in remaining:
            continue
        payload = wad[offset : offset + size]
        if not payload.startswith(b"OggS"):
            raise ValueError(f"{name} is not OGG audio")
        (target / LUMPS[name]).write_bytes(payload)
        remaining.remove(name)
    if remaining:
        raise ValueError(f"Missing sound lumps: {sorted(remaining)}")
    for alias, original in ALIASES.items():
        (target / alias).write_bytes((target / original).read_bytes())
    for ogg_name in [*LUMPS.values(), *ALIASES]:
        ogg = target / ogg_name
        wav = ogg.with_suffix(".wav")
        subprocess.run(
            [
                "ffmpeg", "-y", "-loglevel", "error", "-i", str(ogg),
                "-ac", "1", "-ar", "22050", "-c:a", "pcm_s16le", str(wav),
            ],
            check=True,
        )
    print(f"Extracted and converted {len(LUMPS)} effects to {target}")


if __name__ == "__main__":
    main()
