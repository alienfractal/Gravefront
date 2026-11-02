# Phase 1 dependencies and licenses

The following native sources are included in `native/third_party/` at fixed
revisions. They are built into `retro_midi_engine.dll`; no source download is
needed during a normal Windows build.

| Library | Revision | Purpose | License notes |
| --- | --- | --- | --- |
| [libADLMIDI](https://github.com/Wohlstand/libADLMIDI) | `v1.6.2.1` (`99c5e03a5cf9b4fdf35b53efddb853c96320d50f`) | MIDI sequencing and Nuked OPL3 synthesis | Mixed licenses. Its README identifies GPLv3+ portions, LGPL emulators, and separate embedded-bank notices. Review all applicable notices before distribution. |
| [miniaudio](https://github.com/mackron/miniaudio) | `0.11.25` (`9634bedb5b5a2ca38c1ee7108a9358a4e233f14d`) | Default Windows audio-device output | Public domain or MIT No Attribution; this project uses the MIT No Attribution option. |

The Windows build enables only the Nuked OPL3 emulator and excludes libADLMIDI's
grey-zone banks. This reduces included code and bank material but does not by
itself remove libADLMIDI's copyleft obligations. The upstream source and its
notices remain in `native/third_party/`; the app's bridge is in `native/`.

The app also uses the Flutter team's `file_selector` package (BSD 3-Clause) and
Dart's `ffi` package (BSD 3-Clause). Versions are recorded in `pubspec.lock`.

The interface bundles [Pixelify Sans](https://github.com/google/fonts/tree/main/ofl/pixelifysans)
from Google Fonts under the SIL Open Font License 1.1. Its notice is kept at
`assets/fonts/OFL.txt`. The bundled `PixelifySans.ttf` has SHA-256
`9ba86cd010a4de309d263ceff8e8044092c9db7efda869620cb9ff1c4389e8a5`.

Display headings also use [Press Start 2P](https://github.com/google/fonts/tree/main/ofl/pressstart2p),
which AlienRetro loads on its main page. It is bundled under SIL Open Font
License 1.1 with its notice at `assets/fonts/PressStart2P-OFL.txt`. The bundled
`PressStart2P-Regular.ttf` has SHA-256
`034c77f1f05ec89421e4a63f0e3a4ca1ecf852cc6d2bf611f126f275728e017d`.

No license has been chosen for RetroMIDI itself. Before Phase 4 distribution,
choose a compatible project license and prepare the required source and
attribution materials. This document records the dependencies; it is not a
legal determination.
