# Reusable Flame game structure

This is a template for a **Flame game hosted by Flutter**. Copy it into a new project, replace the values in the project decisions table, and write that project's `docs/ARCHITECTURE.md` before adding screens or assets. It is not the architecture document for Gravefront Arena.

The patterns come from the actual CoolorBurn and RobotFluttbag source: state-specific views, handlers and caches; a screen FSM; preloaded `SpriteSpec` data; and fresh Flame components for each placement. Copy the ownership rules, then adapt the details to the new game's source and requirements.

## Decide these values for each project

| Decision | Record the project's answer |
| --- | --- |
| Logical camera width and height | `<camera width> × <camera height>` |
| Playfield rectangle inside that camera | `<x, y, width, height>` |
| HUD rectangles | `<rectangles in camera pixels>` |
| Window scaling | `<integer zoom with letterboxing, or another explicit policy>` |
| Window smaller than the logical camera | `<crop, resize, or reject; choose one>` |
| Simulation coordinate system | `<world width, height, origin, units>` |
| Cache owner and lifetime | `<one game instance or an app/session owner>` |
| Screen states and transitions | `<menu, loading, level, pause, result, etc.>` |
| Allowed Flutter-rendered exceptions | `<none by default; name and justify any exception>` |

Do not copy a camera size, sprite size, or zoom rule from a reference project without checking the new game's assets and design. A fixed-resolution Flame camera keeps logical proportions; **it does not by itself guarantee whole-number window scaling**. Implement and test the chosen scaling rule separately.

## Boundaries

1. Flutter runs the app and mounts `GameWidget`. Menu, loading, play, pause, result, HUD and their hit targets are Flame components by default. Do not introduce a Flutter widget screen or overlay as a convenience substitution. Document an intentional exception before implementing it.
2. Pure Dart models and logic own campaign progress, combat, movement, timers, damage, collision and victory. They must not import Flutter or Flame.
3. A screen FSM owns transitions and the exit of the previous screen. A view sends intent; it does not independently replace screens or decide campaign progress.
4. Cache services load and decode images and animations. They retain reusable `Sprite`/`SpriteAnimation` data, not mounted `SpriteComponent` instances. A view requests a **fresh component** for each placement.
   Use FlutterGen-generated `Assets` paths for bundled files. Keep generated-path imports out of pure game models; models may carry logical asset IDs that a cache resolves through the generated registry.
5. Handlers choose animation state, facing and frame from model state. Views choose camera-space size, anchor, position, priority and other placement details. Animation rendering must not advance combat time.
6. Input handlers translate pointer or key events into model intent. Render code reads state; it does not decide game rules.
7. Audio is a separate consumer of game events. Sound completion must not govern combat or transitions.

## Suggested layout

```text
lib/
  main.dart                         Flutter bootstrap only
  game_host.dart                    GameWidget and app/session-owned resources
  gen/assets.gen.dart               FlutterGen output; never edit by hand
  <game_name>_game.dart              FlameGame, camera, shared wiring, fixed tick
  gamefsm/                          Screen states and transitions
  game/
    camera/                         Logical viewport and coordinate conversion
    model/                          Campaign-wide pure Dart state
    states/
      main_menu/
        model/                       Only if the menu has its own state
        services/                    Menu-specific assets or rules
        handlers/                    Menu input/animation choices
        view/                        Flame menu and button components
      level/
        model/                       Unit and level state
        services/                    Pure rules and asset cache
        handlers/                    Input and animation selection
        view/                        World, units, effects and HUD components
      <other_state>/                 Same ownership pattern
    view/                            Shared Flame visual components
  audio/                             Audio loading and playback
test/                                Rules, cache, viewport and interaction tests
docs/ARCHITECTURE.md                This project's actual decisions and ownership
AGENTS.md                           Short instructions pointing to the architecture
```

Place code by its responsibility. A `view/` file may import Flame; a combat `model/` or pure logic `services/` file may not. Shared code belongs in `game/view/` or a common service only after two states actually need it.

## Preload and component contract

Choose one owner that outlives every screen which uses the assets. Start its preload once, await it before mounting dependent views, and dispose it once when that owner ends. For a small fixed catalog, preload the whole catalog before the first dependent screen, including art unlocked later. Retrying or advancing a level creates new views and components, **not new decoded images**.

Declare assets in `pubspec.yaml`, add `build_runner` and `flutter_gen_runner` as development dependencies, and run `flutter pub run build_runner build --delete-conflicting-outputs` after changing assets. Use `Assets.images...path` or generated audio paths at load sites. For data-driven names, build a checked lookup from FlutterGen's generated `values`; do not construct a bundled directory path by string concatenation.

Use named `late final SpriteSpec` fields for a fixed set of assets, following CoolorBurn's direct access pattern. `late final` prevents a nullable field at the call site; it does **not** load an image. The preload method must assign the field before any view reads it. Use a map only when asset keys are genuinely dynamic, and expose a checked, nonnullable accessor instead of scattering `!` through views.

```dart
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../gen/assets.gen.dart';

class SpriteSpec {
  SpriteSpec(this.sprite);

  final Sprite sprite;

  SpriteComponent getSpriteComponent() => SpriteComponent(
    sprite: sprite,
    size: sprite.srcSize.clone(),
    paint: Paint()..filterQuality = FilterQuality.none,
  );
}

class LevelCacheService {
  LevelCacheService(this._loadSprite);

  final Future<Sprite> Function(String path) _loadSprite;
  late final SpriteSpec hereticKeep;
  late final SpriteSpec hexenKeep;
  Future<void>? _loading;

  Future<void> preload() => _loading ??= _preload();

  Future<void> _preload() async {
    hereticKeep = SpriteSpec(
      await _loadSprite(Assets.images.terrain.keepHeretic.path),
    );
    hexenKeep = SpriteSpec(
      await _loadSprite(Assets.images.terrain.keepHexen.path),
    );
  }
}

// In the Flame view's onLoad, after await cache.preload():
final keep = cache.hereticKeep.getSpriteComponent()
  ..size = layout.keepDisplaySize.clone()
  ..anchor = Anchor.center
  ..position = viewport.toCamera(keepModel.position);
await add(keep);
```

The cache and view snippets are illustrative: replace asset names and supply the project's `layout`, viewport mapper, model and image loader. The cache owner must also dispose decoded images if its loader owns them. Do not cache the `keep` component itself; Flame components have parent and lifecycle state. The same cached sprite may create many fresh components.

## Camera, art and collision

- Specify sprite display dimensions in **logical camera pixels**. Convert simulation world positions through one viewport mapper. A sprite's source-image dimensions do not automatically determine its displayed size.
- Define hurt, collision, selection and action/click shapes in the gameplay model in **simulation units**. They may differ from the sprite rectangle. Document why each shape differs.
- Draw debug outlines for sprite bounds and each gameplay shape from their real sources. The debug view must not contain a second copy of collision constants.
- Sample pixel art with nearest-neighbor filtering. If the chosen policy is integer zoom, letterbox or crop deliberately and test odd window sizes; do not assume `CameraComponent.withFixedResolution` enforces integer scaling.
- If a horizontal sheet filename carries metadata, accept `<name>_WxH-frames.png` and `<name>-WxH-frames.png`. Parse the suffix in one asset service, validate positive dimensions and frame count, and validate them against the decoded image. A filename without the suffix needs explicit metadata. The suffix describes sheet frames, not camera-space display size or gameplay collision.

## Change procedure

1. Read this project's `AGENTS.md`, `docs/ARCHITECTURE.md`, and the relevant actual source before editing. Inspect reference-project source for a pattern; do not infer it from class names or a screenshot alone.
2. Write down the owner of each new model, rule, asset, component, handler and transition. If the proposed owner contradicts the project table, resolve that before coding.
3. Implement the smallest complete vertical change, including screen mounting, cache lifetime, input and cleanup. Do not update the architecture document to justify a deviation from the agreed structure.
4. Verify behavior at the boundary: preload once across a level retry, fresh components from a cached sprite, a real menu/HUD tap, viewport mapping, and distinct sprite versus gameplay hitboxes where applicable.
5. Update the project's architecture and README to describe the verified code. Run formatting, static analysis, tests and a platform build. Check a rendered screen when changing layout or scale.

If project instructions, architecture text, user requirements or actual source conflict, **surface the exact conflict before choosing an implementation**. The user's current explicit requirement takes precedence over a copied template.

## Starter `AGENTS.md` for a new Flame project

Copy this block into the new project's `AGENTS.md` after filling in its architecture document:

```md
# Working in <project>

Read `docs/ARCHITECTURE.md` and relevant source before adding screens, units, assets, services or handlers. Follow its ownership table and the actual project code. Use reference projects for patterns, not literal dimensions or names.

Flutter only bootstraps and hosts `GameWidget` unless `docs/ARCHITECTURE.md` names an exception. Render menu, level, pause, result and HUD through Flame components. Put pure game rules in Dart models/services; put screen transitions in the screen FSM; put asset decoding in cache services; put frame selection in handlers; put camera-space placement and size in views.

Preload shared images once per documented cache lifetime. Await preload before mounting dependent views. Keep sprites and animations cached, create fresh components for each placement, and dispose the cache only when its owner ends.

Use FlutterGen `Assets` references for bundled image, audio and data paths. Regenerate `lib/gen/assets.gen.dart` after asset changes. Optional horizontal sheet suffixes are `_WxH-frames` and `-WxH-frames`; parse them in one asset service and keep rendered size separate.

Use the camera size, arena rectangles, scaling policy and collision coordinate system written in `docs/ARCHITECTURE.md`. Treat visual bounds, hurt shapes and action targets as separate values. Use nearest-neighbor sampling for pixel art.

When instructions or source disagree, report the conflict before implementing. Update architecture and README after behavior or ownership changes. Run format, analysis, tests and the target-platform build for code changes.
```
