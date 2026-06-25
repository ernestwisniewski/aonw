import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/worker_action_selection_detail_content.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('keeps build confirmation pinned below the scrolling options', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: const Key('workerBuildHarness'),
              width: 360,
              height: 260,
              child: WorkerActionSelectionDetailContent(
                model: _workerBuildDetail(l10n),
                compact: false,
              ),
            ),
          ),
        ),
      ),
    );

    final confirmFinder = find.byKey(
      const Key('selectionInfo.workerBuild.confirm'),
    );
    final cancelFinder = find.byKey(
      const Key('selectionInfo.workerBuild.cancel'),
    );
    final listFinder = find.byKey(
      const Key('selectionInfo.workerBuild.optionsList'),
    );
    final harnessRect = tester.getRect(
      find.byKey(const Key('workerBuildHarness')),
    );
    final initialButtonRect = tester.getRect(confirmFinder);

    expect(find.text('Build Farm'), findsOneWidget);
    expect(cancelFinder, findsOneWidget);
    expect(listFinder, findsOneWidget);
    expect(initialButtonRect.bottom, lessThanOrEqualTo(harnessRect.bottom));

    await tester.drag(listFinder, const Offset(0, -160));
    await tester.pump();

    final scrolledButtonRect = tester.getRect(confirmFinder);
    expect(
      find.text(l10n.workerActionSelectedImprovement('Farm')),
      findsOneWidget,
    );
    expect(scrolledButtonRect.top, closeTo(initialButtonRect.top, 1));
    expect(scrolledButtonRect.bottom, lessThanOrEqualTo(harnessRect.bottom));
  });

  testWidgets('cancel button reports the worker id', (tester) async {
    String? cancelledUnitId;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WorkerActionSelectionDetailContent(
            model: _workerBuildDetail(l10n),
            compact: false,
            onCancelWorkerActionSelection: (unitId) {
              cancelledUnitId = unitId;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('selectionInfo.workerBuild.cancel')));

    expect(cancelledUnitId, 'worker_1');
  });
}

WorkerActionSelectionDetail _workerBuildDetail(AppLocalizations l10n) {
  return WorkerActionSelectionDetail(
    chipId: 'workerBuildGuide',
    title: 'Tile improvement',
    contentKey: 'workerBuild:worker_1:farm:test',
    workerAction: WorkerActionPanelViewModel(
      unitId: 'worker_1',
      unitName: 'Worker',
      currentHex: const CityHex(col: 0, row: 0),
      movementPoints: 1,
      selectionActive: true,
      selectedImprovementType: FieldImprovementType.farm,
      activeJob: null,
      options: [
        for (final type in FieldImprovementType.values.take(12))
          WorkerImprovementOptionViewModel(
            improvementType: type,
            title: GameDisplayNames.fieldImprovement(l10n, type),
            yield: const TileYield(food: 1, production: 1, gold: 0, defense: 0),
            buildTurns: 4,
            state: type == FieldImprovementType.farm
                ? WorkerImprovementOptionState.selected
                : WorkerImprovementOptionState.available,
            reason: '',
            canSelect: true,
            score: 1,
          ),
      ],
    ),
  );
}
