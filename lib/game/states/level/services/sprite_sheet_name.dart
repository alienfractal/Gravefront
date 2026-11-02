/// Optional horizontal sprite-sheet metadata at the end of an asset name.
///
/// Both `name_32x32-3.png` and `name-32x32-3.png` are accepted.
class SpriteSheetName {
  const SpriteSheetName(this.width, this.height, this.frames);

  final int width;
  final int height;
  final int frames;

  static final _suffix = RegExp(r'[-_](\d+)[xX](\d+)-(\d+)\.png$');

  static SpriteSheetName? tryParse(String path) {
    final match = _suffix.firstMatch(path);
    if (match == null) return null;
    final width = int.parse(match.group(1)!);
    final height = int.parse(match.group(2)!);
    final frames = int.parse(match.group(3)!);
    if (width < 1 || height < 1 || frames < 1) {
      throw FormatException('Sprite sheet dimensions must be positive', path);
    }
    return SpriteSheetName(width, height, frames);
  }

  static SpriteSheetName parse(String path) =>
      tryParse(path) ??
      (throw FormatException('Missing sprite sheet size/frame suffix', path));
}
