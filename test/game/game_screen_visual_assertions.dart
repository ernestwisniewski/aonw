part of 'game_screen_test.dart';

void _expectWarmPanelSurface(
  WidgetTester tester,
  Key key, {
  required String reason,
}) {
  final surface = tester.widget<DecoratedBox>(find.byKey(key));
  final decoration = surface.decoration;
  expect(decoration, isA<BoxDecoration>(), reason: reason);
  final box = decoration as BoxDecoration;
  expect(box.gradient, isA<LinearGradient>(), reason: reason);
  expect(box.color, isNull, reason: reason);
}
