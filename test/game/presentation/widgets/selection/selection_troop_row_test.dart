import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionTroopRow', () {
    testWidgets('renders troop name and count', (tester) async {
      await _pump(tester, density: SelectionDensity.comfortable);

      expect(find.text('Warriors'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byTooltip('Detach warriors'), findsOneWidget);
    });

    testWidgets('calls detach with troop type when enabled', (tester) async {
      TroopType? detached;
      await _pump(
        tester,
        density: SelectionDensity.compact,
        onDetach: (type) => detached = type,
      );

      await tester.tap(find.byTooltip('Detach warriors'));

      expect(detached, TroopType.warrior);
    });
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required SelectionDensity density,
  ValueChanged<TroopType>? onDetach,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SelectionTroopRow(
          density: density,
          onDetach: onDetach,
          troop: const ArmyTroopViewModel(
            type: TroopType.warrior,
            name: 'Warriors',
            count: 12,
            icon: GameIcons.warrior,
          ),
        ),
      ),
    ),
  );
}
