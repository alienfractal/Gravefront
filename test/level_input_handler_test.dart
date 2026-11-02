import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravefront_arena/game/states/level/handlers/level_input_handler.dart';

void main() {
  test('1 toggles hitboxes once per key press', () {
    var toggles = 0;
    final input = LevelInputHandler(() => toggles++);
    final down = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.digit1,
      logicalKey: LogicalKeyboardKey.digit1,
      timeStamp: Duration.zero,
    );
    final repeat = KeyRepeatEvent(
      physicalKey: PhysicalKeyboardKey.digit1,
      logicalKey: LogicalKeyboardKey.digit1,
      timeStamp: Duration.zero,
    );
    final up = KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.digit1,
      logicalKey: LogicalKeyboardKey.digit1,
      timeStamp: Duration.zero,
    );

    expect(input.onKeyEvent(down, {}), isFalse);
    expect(input.onKeyEvent(repeat, {}), isTrue);
    expect(input.onKeyEvent(up, {}), isTrue);
    expect(toggles, 1);
  });
}
