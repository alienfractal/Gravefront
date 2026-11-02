import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../../../camera/pixel_viewport.dart';
import '../../../../gen/assets.gen.dart';
import 'battle_logic_service.dart';
import 'sprite_sheet_name.dart';

/// Cached sprite that creates a fresh component for each placement.
class SpriteSpec {
  SpriteSpec(ui.Image image, [Vector2? size])
    : sprite = Sprite(image),
      size = size ?? Vector2(image.width.toDouble(), image.height.toDouble());

  final Sprite sprite;
  final Vector2 size;

  SpriteComponent getSpriteComponent({int priority = 0}) => SpriteComponent(
    sprite: sprite,
    size: size.clone(),
    priority: priority,
    paint: ui.Paint()..filterQuality = ui.FilterQuality.none,
  );
}

class UnitAtlas {
  UnitAtlas(this.image, this.frameCount);

  final ui.Image image;
  final int frameCount;
  final Map<int, SpriteAnimation> _animations = {};

  double get cellWidth => image.width / 8;
  double get cellHeight => image.height / frameCount;

  Rect sourceRect(int frame, int facing) => Rect.fromLTWH(
    (facing - 1) * cellWidth,
    frame * cellHeight,
    cellWidth,
    cellHeight,
  );

  SpriteAnimation animationFor(int facing) => _animations.putIfAbsent(
    facing,
    () => SpriteAnimation.spriteList([
      for (var frame = 0; frame < frameCount; frame++)
        Sprite(
          image,
          srcPosition: Vector2((facing - 1) * cellWidth, frame * cellHeight),
          srcSize: Vector2(cellWidth, cellHeight),
        ),
    ], stepTime: 1 / 7),
  );
}

class ProjectileSheet {
  ProjectileSheet._(
    this.image,
    this.displayWidth,
    this.displayHeight,
    this.frames,
  );

  factory ProjectileSheet.fromFilename(String filename, ui.Image image) {
    final name = SpriteSheetName.parse(filename);
    final width = name.width;
    final height = name.height;
    final frames = name.frames;
    if (frames < 1 ||
        image.width % frames != 0 ||
        image.width ~/ frames > width ||
        image.height > height) {
      throw FormatException('Sprite sheet dimensions do not match $filename');
    }
    return ProjectileSheet._(image, width, height, frames);
  }

  final ui.Image image;
  final int displayWidth;
  final int displayHeight;
  final int frames;
  late final SpriteAnimation animation = SpriteAnimation.spriteList(
    [
      for (var frame = 0; frame < frames; frame++)
        Sprite(
          image,
          srcPosition: Vector2(frame * sourceWidth.toDouble(), 0),
          srcSize: Vector2(sourceWidth.toDouble(), image.height.toDouble()),
        ),
    ],
    stepTime: AttackEffect.duration / frames,
    loop: false,
  );

  int get sourceWidth => image.width ~/ frames;

  Rect sourceRect(int frame) => Rect.fromLTWH(
    (frame % frames * sourceWidth).toDouble(),
    0,
    sourceWidth.toDouble(),
    image.height.toDouble(),
  );

  Rect destinationRect(Offset center) {
    const scale = 0.5;
    final width = sourceWidth * scale;
    final height = image.height * scale;

    return Rect.fromLTWH(
      (center.dx - width / 2).roundToDouble(),
      (center.dy - height / 2).roundToDouble(),
      width,
      height,
    );
  }

  int frameAt(double progress) => min(frames - 1, (progress * frames).floor());
}

class LevelCacheService {
  final Map<String, Map<String, UnitAtlas>> atlases = {};
  final Map<Faction, ProjectileSheet> projectiles = {};
  final Map<BattlefieldArt, SpriteSpec> _terrains = {};
  late final ui.Image buttonFrame;
  late final SpriteAnimation manaCrystal;
  late final SpriteSpec hereticKeep;
  late final SpriteSpec hexenKeep;
  final List<SpriteSpec> _loadedKeeps = [];
  ui.Image? _manaCrystalImage;
  Future<void>? _loading;
  bool _disposed = false;
  bool _buttonLoaded = false;

  Future<void> load() => _loading ??= _load();

  SpriteComponent terrainComponent(BattlefieldArt map) {
    final terrain = _terrains[map];
    if (terrain == null) {
      throw StateError('Terrain $map was not preloaded');
    }
    return terrain.getSpriteComponent();
  }

  UnitAtlas unitAtlas(Faction faction, UnitRole role, String state) {
    final name = assetNameFor(faction, role);
    final atlas = atlases[name]?[state];
    if (atlas == null) {
      throw StateError('Unit atlas $name/$state was not preloaded');
    }
    return atlas;
  }

  SpriteComponent unitFrameComponent(Faction faction, UnitRole role) {
    final atlas = unitAtlas(faction, role, 'walk');
    final source = atlas.sourceRect(0, 1);
    return SpriteComponent(
      sprite: Sprite(
        atlas.image,
        srcPosition: Vector2(source.left, source.top),
        srcSize: Vector2(source.width, source.height),
      ),
      size: Vector2(source.width, source.height),
      paint: ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  SpriteAnimationComponent unitComponent(
    Faction faction,
    UnitRole role, {
    required int facing,
  }) => SpriteAnimationComponent(
    animation: unitAtlas(faction, role, 'walk').animationFor(facing),
    playing: false,
    size: Vector2.zero(),
    paint: ui.Paint()
      ..filterQuality = ui.FilterQuality.none
      ..isAntiAlias = false,
  );

  SpriteAnimationComponent manaCrystalComponent() => SpriteAnimationComponent(
    animation: manaCrystal,
    playing: false,
    size: Vector2(10, 13),
    paint: ui.Paint()..filterQuality = ui.FilterQuality.none,
  );

  ProjectileSheet projectileSheet(Faction faction) {
    final sheet = projectiles[faction];
    if (sheet == null) {
      throw StateError('Projectile sheet for $faction was not preloaded');
    }
    return sheet;
  }

  SpriteAnimationComponent projectileComponent(Faction faction) {
    final sheet = projectileSheet(faction);
    return SpriteAnimationComponent(
      animation: sheet.animation,
      playing: false,
      size: Vector2(sheet.sourceWidth * 0.5, sheet.image.height * 0.5),
      anchor: Anchor.center,
      priority: 400,
      paint: ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  Future<void> _load() async {
    final unitImages = {
      for (final image in Assets.images.units.values.whereType<AssetGenImage>())
        _filename(image.path): image.path,
    };
    final catalog =
        jsonDecode(await rootBundle.loadString(Assets.images.units.catalog))
            as Map<String, dynamic>;
    for (final unit in catalog.entries) {
      final states = unit.value as Map<String, dynamic>;
      final unitAtlases = <String, UnitAtlas>{};
      for (final state in states.entries) {
        final file = '${unit.key}_${state.key}.png';
        final path = unitImages[file];
        if (path == null) {
          throw StateError('Missing generated unit asset $file');
        }
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        unitAtlases[state.key] = UnitAtlas(
          (await codec.getNextFrame()).image,
          (state.value as String).length,
        );
        codec.dispose();
      }
      atlases[unit.key] = unitAtlases;
    }
    for (final map in campaignLevels.map((level) => level.map).toSet()) {
      final path = switch (map) {
        BattlefieldArt.battlefield => Assets.images.terrain.battlefield.path,
      };
      _terrains[map] = SpriteSpec(
        await _loadImage(path),
        Vector2(PixelViewport.width, PixelViewport.height),
      );
    }
    buttonFrame = await _loadImage(Assets.images.ui.buttonstart.path);
    _buttonLoaded = true;
    hereticKeep = SpriteSpec(
      await _loadImage(Assets.images.terrain.keepHereticS.path),
    );
    _loadedKeeps.add(hereticKeep);
    hexenKeep = SpriteSpec(
      await _loadImage(Assets.images.terrain.keepHexenS.path),
    );
    _loadedKeeps.add(hexenKeep);
    final manaCrystalImage = await _loadImage(
      Assets.images.terrain.manaCrystal.path,
    );
    _manaCrystalImage = manaCrystalImage;
    manaCrystal = SpriteAnimation.spriteList([
      for (var frame = 0; frame < 2; frame++)
        Sprite(
          manaCrystalImage,
          srcPosition: Vector2(frame * 10.0, 0),
          srcSize: Vector2(10, 13),
        ),
    ], stepTime: 0.25);
    for (final entry in <Faction, AssetGenImage>{
      Faction.heretic: Assets.images.terrain.fireball132x323,
      Faction.hexen: Assets.images.terrain.fireball232x323,
    }.entries) {
      final path = entry.value.path;
      final image = await _loadImage(path);
      projectiles[entry.key] = ProjectileSheet.fromFilename(path, image);
    }
  }

  String _filename(String path) => path.substring(path.lastIndexOf('/') + 1);

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return image;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _loading;
    } catch (_) {
      // Release any images loaded before a failed asset request.
    }
    for (final states in atlases.values) {
      for (final atlas in states.values) {
        atlas.image.dispose();
      }
    }
    for (final terrain in _terrains.values) {
      terrain.sprite.image.dispose();
    }
    if (_buttonLoaded) buttonFrame.dispose();
    for (final spec in _loadedKeeps) {
      spec.sprite.image.dispose();
    }
    _manaCrystalImage?.dispose();
    for (final sheet in projectiles.values) {
      sheet.image.dispose();
    }
    atlases.clear();
    _terrains.clear();
    _loadedKeeps.clear();
    projectiles.clear();
  }
}
