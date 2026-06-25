import 'package:aonw/game/presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameIconPathParser', () {
    test('tokenizes compact negative numbers', () {
      expect(GameIconPathParser.tokenize('M10-5L2.5-3.25'), [
        'M',
        '10',
        '-5',
        'L',
        '2.5',
        '-3.25',
      ]);
    });

    test('parses arc commands used by circular icons', () {
      final path = GameIconPathParser.parse(GameIcons.checkCircle.paths.first);
      final metrics = path.computeMetrics().toList();

      expect(metrics, isNotEmpty);
      expect(metrics.first.length, greaterThan(0));
    });

    test('parses smooth cubic commands used by organic icons', () {
      final path = GameIconPathParser.parse(GameIcons.population.paths[2]);
      final metrics = path.computeMetrics().toList();

      expect(metrics, isNotEmpty);
      expect(metrics.first.length, greaterThan(0));
      expect(GameIconPathParser.tokenize(GameIcons.water.paths.first), [
        'M',
        '3',
        '14',
        'c',
        '2',
        '-2',
        '4',
        '-2',
        '6',
        '0',
        's',
        '4',
        '2',
        '6',
        '0',
        '4',
        '-2',
        '6',
        '0',
      ]);
    });

    testWidgets('paints all shared icons without parser exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Wrap(
            children: [
              GameIcon(GameIcons.city, size: 24, color: Colors.white),
              GameIcon(GameIcons.cityFilled, size: 24, color: Colors.white),
              GameIcon(GameIcons.army, size: 24, color: Colors.white),
              GameIcon(GameIcons.warrior, size: 24, color: Colors.white),
              GameIcon(GameIcons.archer, size: 24, color: Colors.white),
              GameIcon(GameIcons.settler, size: 24, color: Colors.white),
              GameIcon(GameIcons.move, size: 24, color: Colors.white),
              GameIcon(GameIcons.workedHexes, size: 24, color: Colors.white),
              GameIcon(GameIcons.checkCircle, size: 24, color: Colors.white),
              GameIcon(GameIcons.hourglass, size: 24, color: Colors.white),
              GameIcon(GameIcons.chevronDown, size: 24, color: Colors.white),
              GameIcon(GameIcons.chevronUp, size: 24, color: Colors.white),
              GameIcon(GameIcons.population, size: 24, color: Colors.white),
              GameIcon(GameIcons.water, size: 24, color: Colors.white),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(GameIcon), findsNWidgets(14));
    });
  });
}
