# ZDoom Wars Heretic and Hexen sprites

Source: `C:\Users\lien\Desktop\gzdoom-4-4-2-Windows-64bit\zdoomwarsiv3.15d.pk3`

The `Heretic/` and `Hexen/` directories are direct byte-for-byte copies of the archive's `Sprites/Heretic/` and `Sprites/Hexen/` entries. Names and subfolders are preserved. No images were converted.

The archive contains 16 duplicate paths under `Sprites/Hexen/Unsorted/`, each with different bytes. The later entry occupies the normal path, while the earlier entry is preserved under `_duplicate_entries/entry-1/` with the same relative path.

Many files are PNG images, including some without a `.png` extension. Some extensionless Heretic files use the older Doom patch graphic format.

## Previewable PNGs

`png/` contains a PNG copy of every sprite entry, with the same folder structure and a `.png` extension. Existing PNG image data was copied unchanged. The 53 Doom patch graphics were converted to RGBA PNGs using the first `PLAYPAL` palette from the local `DOOM2.WAD`; their original sprite offsets are stored in each PNG's `grAb` metadata chunk. Earlier versions of the 16 duplicate Hexen files are mirrored under `png/_duplicate_entries/entry-1/`.
