import 'package:flutter/painting.dart';

const retroGold = Color(0xFFE3C47C);
const retroPale = Color(0xFFE4DFC7);
const retroMuted = Color(0xFFB7AC91);
const retroStone = Color(0xFF292D27);

TextStyle retroText(
  double size, {
  Color color = retroPale,
  bool bold = false,
}) => TextStyle(
  fontFamily: 'Courier New',
  fontSize: size,
  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
  letterSpacing: 0.7,
  color: color,
  shadows: const [Shadow(color: Color(0xFF000000), offset: Offset(1, 2))],
);
