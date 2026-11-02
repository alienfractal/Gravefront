import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// Level keyboard shortcuts, independent of combat state.
class LevelInputHandler extends Component with KeyboardHandler {
  LevelInputHandler(this.toggleHitboxes);

  final void Function() toggleHitboxes;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return true;
    if (event.logicalKey != LogicalKeyboardKey.digit1 &&
        event.logicalKey != LogicalKeyboardKey.numpad1) {
      return true;
    }
    toggleHitboxes();
    return false;
  }
}
