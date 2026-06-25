import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/selection/selection_action_chip.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_chip_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionActionChip', () {
    testWidgets('comfortable renders 48x48', (tester) async {
      await _pump(
        tester,
        model: _model(),
        density: SelectionDensity.comfortable,
      );

      final size = tester.getSize(find.byType(SelectionActionChip));
      expect(size.width, 48);
      expect(size.height, 48);
    });

    testWidgets('compact renders 36x36', (tester) async {
      await _pump(tester, model: _model(), density: SelectionDensity.compact);

      final size = tester.getSize(find.byType(SelectionActionChip));
      expect(size.width, 36);
      expect(size.height, 36);
    });

    testWidgets('tap fires callback when enabled', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        model: _model(),
        density: SelectionDensity.comfortable,
        onTap: () => tapped = true,
      );

      await tester.tap(find.byType(SelectionActionChip));

      expect(tapped, isTrue);
    });

    testWidgets('disabled chip ignores tap', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        model: _model(enabled: false),
        density: SelectionDensity.comfortable,
        onTap: () => tapped = true,
      );

      await tester.tap(find.byType(SelectionActionChip));

      expect(tapped, isFalse);
    });
  });
}

SelectionInfoChipViewModel _model({bool enabled = true}) {
  return SelectionInfoChipViewModel(
    id: 'army',
    label: 'Armia',
    icon: GameIcons.army,
    tone: SelectionInfoChipTone.accent,
    enabled: enabled,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required SelectionInfoChipViewModel model,
  required SelectionDensity density,
  VoidCallback? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SelectionActionChip(
          model: model,
          active: false,
          density: density,
          onTap: onTap ?? () {},
        ),
      ),
    ),
  );
}
