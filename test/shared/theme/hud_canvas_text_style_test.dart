import 'package:aonw/shared/theme/hud_canvas_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('floatingText clamps opacity into the text and shadow colors', () {
    final style = HudCanvasTextStyle.floatingText(Colors.red, opacity: 1.5);

    expect(style.color?.a, 1);
    expect(style.shadows?.single.color.a, 0.75);
  });
}
