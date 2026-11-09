# Gravefront Arena architecture

This project follows the ownership pattern used in `C:/lien/gamejams/RobotFluttbag` and `C:/lien/gamejams/CoolorBurn/coolorburn`: a composition root, explicit screen flow, state-specific models, rules, views, handlers, cache services, and a separate audio boundary. Like CoolorBurn, the RTS uses a Flame `CameraComponent.withFixedResolution` at 320 × 200 logical pixels.

## Ownership

| Responsibility | Owner |
| --- | --- |
| Flutter bootstrap and `GameWidget` mounting | `lib/main.dart`, `lib/rts_app.dart` |
| Menu, level, win, loss and retry transitions | `lib/gamefsm/campaign_fsm.dart` |
| Campaign definitions and current progress | `lib/game/model/campaign_model.dart` |
| Fixed simulation tick and per-battle audio lifetime | `lib/gravefront_arena_game.dart` |
| Shared level-image cache lifetime | `lib/rts_app.dart` |
| Unit identity, stats, position and animation state | `lib/game/states/level/model/unit_model.dart` |
| Spawning, orders, combat, AI, mana and victory | `lib/game/states/level/services/battle_logic_service.dart` |
| Preloaded sprite and animation data, fresh image components | `lib/game/states/level/services/level_cache_service.dart` |
| Generated asset paths and sheet suffix metadata | `lib/gen/assets.gen.dart`, `lib/game/states/level/services/sprite_sheet_name.dart` |
| Unit sprite pose, frame and draw size | `lib/game/states/level/handlers/unit_animation_handler.dart` |
| Arena component tree, terrain, keeps and projectiles | `lib/game/states/level/view/level_play_view.dart` |
| Flame keep and unit-range collision sensors | `lib/game/states/level/view/keep_collision_view.dart`, `lib/game/states/level/view/keep_hitbox_view.dart` |
| Unit keep-contact collision behavior | `lib/game/states/level/behaviours/keep_contact_behavior.dart` |
| Per-unit sprite, shadow, selection and hit flash components | `lib/game/states/level/view/unit_view.dart` |
| Debug art bounds and battle target outlines | `lib/game/states/level/view/hitbox_view.dart` |
| Level keyboard shortcuts | `lib/game/states/level/handlers/level_input_handler.dart` |
| Health bar rectangle components | `lib/game/states/level/view/health_bar_view.dart` |
| Crystal sprite animation and selection components | `lib/game/states/level/view/arena_effect_views.dart` |
| Pixel-scaled level HUD and command buttons | `lib/game/states/level/view/level_screen_view.dart` |
| Pointer input and fixed tick | `lib/gravefront_arena_game.dart` |
| Fixed-camera Flame menu and faction hit targets | `lib/game/states/main_menu/view/main_menu_view.dart` |
| Pooled battle sound effects and audio ownership | `lib/audio/game_audio_service.dart` |
| Looping battle music, mute, finish and disposal | `lib/audio/battle_music_service.dart` |
| Screen-to-world coordinate mapping | `lib/game/camera/pixel_viewport.dart` |
| Shared UI colors and frames | `lib/game/view/retro_theme.dart` |

The data flow is `pointer or button → battle order → fixed-step simulation → model state → animation handler and level view`. Flame keep hitboxes detect contact with unit attack-range sensors; `KeepContactBehavior` reports those contacts to the battle model. Combat changes health and mana in pure Dart. Rendering and sound consume the result; neither decides damage, victory or pickup timing. `CampaignFsm` keeps level progress while `RtsHome` replaces the `RtsGame` instance for each new battle. `RtsHome` keeps one `LevelCacheService` across those replacements and disposes it when the app home is removed.

`assets/audio/only_retro_2.mid` is the editable Type 1 Arrangement export from Ableton. The game plays its `only_retro_2.ogg` render through Flame Audio, so Windows and web use the same OPL3-generated music without runtime MIDI synthesis. The render uses libADLMIDI 1.6.2.1 with Nuked OPL3, embedded bank 0 (AIL Fat Man), two chips, 44.1 kHz stereo, and no automatic arpeggio. ADLplug's saved bank differs, so its exact timbres are not reproduced. `tool/render_battle_music.ps1` regenerates the OGG after the MIDI asset changes. `GameAudioService` owns the effect pools and one `BattleMusicService` for each battle. The music loops during play, follows the existing sound toggle, stops when a winner is recorded, and begins disposal when a battle is replaced or the app home is removed. `BattleMusicService` serializes asynchronous start, mute, finish and disposal; audio completion never drives combat or campaign state.

`BattleState.step` stops after a winner is set. `CampaignFsm.advance` accepts only a victory and `retry` accepts only a defeat; each reports whether the transition happened. `RtsHome` opens a fresh battle only after an accepted transition, so a stale result-button callback cannot restart a lost or already restarted battle.

When either keep reaches zero health, battle logic records the attacking unit's faction as the winner. Losing the player keep therefore enters `CampaignPhase.defeat` and leaves campaign progress on the current level.

`MainMenuGame` and `RtsGame` each configure a 320 × 200 fixed-resolution Flame camera. The menu uses cached terrain and unit sprites, a Flame backdrop component, and Flame faction-card tap targets. `RtsGame` anchors its viewfinder at the top left, places `LevelPlayView` in the world, and attaches `LevelScreenView` and its button hit targets to the camera viewport. The battlefield occupies 320 × 160 camera pixels between a 16-pixel header and a 24-pixel command bar. `LevelPlayView` owns terrain and keep sprites, `UnitView` children with directional atlas animation, projectiles, and the crystal animation. Borders, health bars, shadows, and selection are Flame components. `PixelViewport` maps positions between this arena and the independent 1000 × 620 battle simulation. Flame scales all world and HUD components together to the available window while preserving their proportions. The Flutter host mounts `GameWidget` and forwards battle pointer positions; Flame dispatches menu and HUD button input. New RTS screens should be placed under `game/states/<screen>/view/` and wired through `CampaignFsm` rather than added to the level view.

The active battlefield art meets the ground near arena y=64, equivalent to battle-world y=248. `BattleState` clamps unit movement and move destinations to that horizon and places mana crystals below it. `UnitAnimationHandler` maps depth from 0.5 scale at the horizon to full size at the near edge; `UnitView` applies that scale to sprites, shadows, rings, and health bars. Selection bounds use the same scale in the pure battle model, and `HitboxView` displays those scaled bounds. A unit's feet can reach the horizon but cannot move into the sky.

`RtsHome` starts `LevelCacheService.load` while the menu is open. The cache decodes the complete unit catalog, each distinct campaign terrain image, both keeps, the mana crystal, both projectiles, and the HUD button frame once. `RtsGame.onLoad` awaits that same load before constructing its views. Later levels reuse the decoded images without loading them again. Like CoolorBurn's `SpriteSpec`, the cache creates fresh terrain, keep, unit, mana crystal, and projectile components from cached sprites or animations. The fixed keeps are exposed as named `late final SpriteSpec` fields; `LevelPlayView.onLoad` calls `getSpriteComponent()` and sets each fresh component's size to 83 × 102 camera pixels before placing it. The cached button image is rendered inside each three-slice Flame `HudButton`; unit icons and portraits also use preloaded atlas images inside Flame HUD components. Dynamic atlas and projectile maps use checked, nonnullable accessors because a map lookup remains nullable in Dart even when every key was populated at runtime. `UnitAnimationHandler` chooses the state, facing frame and destination size from simulation state; the animation components do not advance combat clocks. Sprite dimensions are specified in camera pixels and are not derived from their battle-world coordinates.

FlutterGen generates `lib/gen/assets.gen.dart` from the declared assets in `pubspec.yaml`; regenerate it with `flutter pub run build_runner build --delete-conflicting-outputs` when assets change. Cache and audio services use generated `Assets` paths instead of typed path literals. Pure Dart campaign and combat models use logical IDs such as `BattlefieldArt.battlefield`; the cache resolves them to generated paths. Optional horizontal sprite-sheet filenames end in `_WxH-frames.png` or `-WxH-frames.png` (for example, `fireball1-32x32-3.png`). `SpriteSheetName` parses the declared frame canvas size and frame count; sheets without that suffix use explicit metadata, such as the unit catalog. The suffix does not set the rendered component size or its collision shape.

Pressing `1` toggles `HitboxView`, following RobotFluttbag's keyboard-handler and Flame-overlay pattern. It draws yellow rectangles around actual sprite extents, cyan keep hurt rectangles, a red enemy-keep click rectangle, and pink unit selection rectangles. `BattleState` owns the keep hurt and click dimensions in battle-world units; the hurt rectangle is approximately 74 × 89 camera pixels inside the visible 83 × 102 keep, and the click rectangle follows the art bounds. Units move toward the nearest point on the keep rectangle. A Flame circle hitbox with each unit's attack radius detects contact with an opposing keep rectangle; `KeepContactBehavior` handles the callback and `BattleState` applies attack cooldown, damage, and victory rules. Unit-versus-unit combat still uses point positions and attack ranges. The overlay reads the same keep bounds without deciding combat.

The button frame uses the unchanged `assets/images/ui/buttonstart.png` from RobotFluttbag (originally CoolorBurn). Flame menu cards and HUD buttons render three source slices on the game canvas. This keeps the baked START lettering out of buttons with other labels. `LevelCacheService` owns the one shared image and disposes it when `RtsHome` is removed.

All five campaign levels use `assets/images/terrain/battlefield.png`. Level definitions change encounter difficulty and unlocks without selecting a different background.

## Extending the game

1. Add a unit's identity and stats in `unit_model.dart`. Give it gameplay rules in `battle_logic_service.dart` only if its behavior is distinct from existing roles.
2. Put runtime sprites in `assets/images/units/`, rebuild directional atlases with `tool/build_unit_atlases.py`, declare the assets in `pubspec.yaml`, and regenerate FlutterGen. `LevelCacheService` loads them through generated paths; `UnitAnimationHandler` chooses frames from simulation state.
3. Put sound files in `assets/audio/` and map their events through `GameAudioService`. Sound completion never controls combat.
4. Add a level definition in `campaign_model.dart`. Keep win/lose/advance/retry decisions in `CampaignFsm` and create a fresh battle for a new level.
5. Add visual or input changes to the corresponding state view. Keep canvas-space conversions in `PixelViewport`.
6. Run `dart format lib test`, `flutter analyze --no-pub`, `flutter test --no-pub`, and `flutter build windows --no-pub` after gameplay or asset wiring changes.

`C:/Users/lien/Downloads/architecture.md` and `architecture-guide.md` describe Kuradi Sääsed, while the root `architecture-guide.md` in this workspace describes RetroMIDI. They are references, not this RTS's live architecture. This file is the RTS-specific contract.
