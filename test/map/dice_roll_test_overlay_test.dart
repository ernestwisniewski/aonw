import 'dart:ui' as ui;

import 'package:aonw/map/widgets/dice_roll_test_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dice roll overlay renders and rolls from a tap', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiceRollTestOverlay(spriteSheetFuture: _fakeDiceSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('diceRollTestOverlay')), findsOneWidget);
    expect(find.byKey(const Key('diceRollTestOverlay.die.0')), findsOneWidget);
    expect(find.byKey(const Key('diceRollTestOverlay.die.1')), findsOneWidget);

    await tester.tapAt(const Offset(400, 372));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(tester.takeException(), isNull);
  });
}

Future<ui.Image> _fakeDiceSheet() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = Colors.white;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 600, 600), paint);
  return recorder.endRecording().toImage(600, 600);
}
