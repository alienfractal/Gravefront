# Gravefront Arena

A small Flutter + Flame fantasy RTS prototype inspired by ZDoom Wars and classic Warcraft skirmishes. The playable factions are Heretic and Hexen.

The menu and battles use 320 × 200 fixed-resolution Flame cameras, like CoolorBurn. Each battlefield is drawn within a 320 × 160 camera-space arena, with a 16-pixel header and a 24-pixel command bar. Menu art, world sprites, and HUD controls scale together with nearest-neighbor sprite sampling. The level cache starts loading campaign art on the menu and remains alive across level changes, creating fresh Flame components for terrain, keeps, units, mana crystals, and projectiles without decoding their images again. `LevelPlayView` gets each keep from a named cached `SpriteSpec` and sizes its fresh component to 83 × 102 camera pixels; unit display heights are 40–44 camera pixels. The buttons reuse a preloaded pixel frame from RobotFluttbag/CoolorBurn.

Bundled image and audio paths come from FlutterGen's `lib/gen/assets.gen.dart`. After adding or renaming assets, run `flutter pub run build_runner build --delete-conflicting-outputs`. Horizontal sprite sheets may end in `_WxH-frames.png` or `-WxH-frames.png`; the fireballs use `-32x32-3.png`. This suffix declares sheet metadata, while Flame views set the display size and gameplay rules set hitboxes.

## Run

```powershell
flutter pub get
flutter run -d windows -t lib/main.dart
```

For a browser build, use `flutter run -d chrome` or `flutter build web`.

## Play

- Choose Heretic or Hexen on the title screen. The other faction is controlled by a simple AI.
- Mana regenerates over time. Spawn unlocked units from the command bar.
- Clear a level to advance through five encounters on the same battlefield. Each level unlocks another unit for both factions. After a defeat, the battle stops; press **Retry Level** to restart that level.
- Units get smaller as they move toward the skyline. Their feet stop at the ground horizon; selection areas shrink with them.
- A purple mana crystal appears at random times. Send a friendly unit to it before it disappears to gain 60 mana.
- Click a unit to select it, or drag a rectangle around several units.
- Right click the field to move selected units. Right click an enemy unit or keep to attack it.
- The **Move / Attack** button provides the same command for touch or one-button mice.
- The speaker button in the top bar mutes or enables battle music and sound effects.
- Press **1** to show or hide hitbox debug outlines. Yellow marks sprite bounds, cyan marks each keep's solid hurt area, red marks the enemy keep's click target, and pink marks unit selection areas. Keep combat and click areas fit the visible keep sprites. Flame hitboxes detect when a unit's attack range reaches a keep; a keep-contact behavior reports the collision and the battle model applies damage. Unit-versus-unit combat still uses point positions and attack ranges.
- Destroy the opposing keep to win.

Summoning, attacks, damage, and deaths use the corresponding ZDoom Wars sound effects. The game plays WAV copies for reliable Windows support; the extracted OGG originals are kept alongside them.

Battle music comes from the editable `assets/audio/only_retro_2.mid` Arrangement export. The game loops an OPL3-rendered `only_retro_2.ogg` while a battle is active, stops it on victory or defeat, and starts it again for a new battle. This render uses libADLMIDI's Nuked OPL3 emulator with its default AIL Fat Man bank and two chips. Its patches can differ from the ADLplug bank selected in Ableton. The game does not synthesize MIDI at runtime.

After editing the Ableton arrangement, export a fresh Type 1 MIDI file to `assets/audio/only_retro_2.mid`, then regenerate the playable asset with a wave-only `adlmidiplay` built from libADLMIDI 1.6.2.1 and FFmpeg:

```powershell
.\tool\render_battle_music.ps1 -Renderer 'C:\path\to\adlmidiplay.exe' -Ffmpeg 'C:\path\to\ffmpeg.exe'
flutter pub run build_runner build --delete-conflicting-outputs
```

The render script selects Nuked OPL3, bank 0, two chips, gain 1, and Vorbis quality 5. The MIDI source remains bundled so it can be edited and re-rendered later.

Level 1 starts with Golem versus Ettin. Each later level starts with the newly unlocked unit on both sides as well. Units attack nearby enemies automatically. There is no building construction, pathfinding around obstacles, or multiplayer yet.

| Level | Heretic unlock | Hexen unlock | Arena |
| --- | --- | --- | --- |
| 1 | Golem | Ettin | The First March |
| 2 | Gargoyle | Afrit | Sunken Road |
| 3 | Undead Knight | Centaur | Broken Shrine |
| 4 | Ophidian | Bishop | Blood Grove |
| 5 | Iron Lich | Chaos Serpent | Final Siege |

All five levels use `assets/images/terrain/battlefield.png` as their background. The other battlefield images remain in the project as art references.

## Project layout

- `lib/rts_app.dart` and `lib/gravefront_arena_game.dart`: Flutter `GameWidget` hosting and the fixed-resolution Flame battle lifecycle.
- `lib/gamefsm/` and `lib/game/model/`: campaign transitions, level definitions and progress.
- `lib/game/states/level/model/` and `services/`: unit data, battle rules and asset cache.
- `lib/gen/assets.gen.dart`: generated, typed FlutterGen paths for bundled images and audio.
- `lib/game/states/level/handlers/` and `view/`: animation choice, battlefield sprite, shape and text components, input and HUD.
- `lib/game/states/main_menu/view/`: fixed-camera Flame faction menu and tap targets.
- `lib/game/camera/` and `lib/game/view/`: pixel viewport mapping and shared UI styling.
- `lib/game/states/level/services/level_cache_service.dart`: preloads one shared copy of campaign and button art for both menu and battles.
- `lib/audio/`: sound loading, playback and disposal.
- `assets/images/units/`: generated eight-direction walk and attack atlases, plus death sequences, for the ten playable units.
- `assets/images/terrain/`: pixel battlefields, keeps, a two-frame mana crystal, and three-frame fireball sheets. Heretic shots use orange `fireball1`, Hexen shots use purple `fireball2`. Each 26×26 source frame currently draws at 13×13 pixels.
- `assets/images/ui/buttonstart.png`: unchanged 100×22 Start button art from RobotFluttbag (originally CoolorBurn). Flame menu and HUD components use the blank center column and end caps to frame buttons without stretching the baked START text.
- `tool/build_retro_scenery.py`: creates optional procedural scenery previews in `assets/images/terrain/generated/` without overwriting the active map.
- `external/png/`: the full Heretic and Hexen sprite library from the user's local PK3, converted to previewable PNGs.
- `tool/build_unit_atlases.py`: rebuilds the directional atlases from `external/png/`; mirrored Doom sprite rotations are handled during generation.
- `assets/audio/`: attack, hurt, and death effects for all ten creatures, the summon sound, and the battle music MIDI source plus OPL3 render.
- `tool/extract_game_sfx.py`: extracts OGG lumps from the local PK3 and converts them to WAV with FFmpeg.
- `external/sfx/`: all 77 Heretic and 211 Hexen sounds from the PK3's labeled sound sections, each kept in its original format with a WAV preview. The folders include `SNDINFO.txt` sound-name mappings; `catalog.json` lists every lump.
- `tool/extract_sound_library.py`: rebuilds the full sound library from the local PK3.
- `test/battle_state_test.dart`: order, victory, campaign unlock, mana pickup, animation, and sound cue checks.

The source art has eight rotations for movement and attack poses. Most death frames are supplied only as rotation 0, so the atlas repeats those frames for each facing angle; Gargoyle and Afrit retain their directional first death frames.

The live project structure and ownership rules are in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). The supplied Kuradi Sääsed documents and the root `architecture-guide.md` (RetroMIDI) remain reference material.
