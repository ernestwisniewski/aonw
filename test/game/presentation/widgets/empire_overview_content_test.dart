import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_content.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders compact empire content and routes row taps', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'unit_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Guard',
      col: 0,
      row: 0,
      movementPoints: 2,
    );
    final scout = GameUnit(
      id: 'unit_2',
      ownerPlayerId: 'player_1',
      type: GameUnitType.scout,
      name: GameUnitType.scout.defaultNameToken,
      col: 2,
      row: 0,
      movementPoints: 1,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      population: 3,
      center: CityHex(col: 1, row: 1),
    );
    const artifact = WorldArtifact(
      id: 'artifact.hero',
      type: WorldArtifactType.heroSword,
      location: WorldArtifactLocation.stored(cityId: 'city_1'),
    );
    final viewModel = EmpireOverviewViewModel.fromState(
      GameState(units: [unit, scout], cities: [city], artifacts: [artifact]),
      activePlayerId: 'player_1',
    );
    GameUnit? selectedUnit;
    GameCity? selectedCity;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return EmpireOverviewContent(
                viewModel: viewModel,
                l10n: AppLocalizations.of(context),
                compact: true,
                onUnitSelected: (value) => selectedUnit = value,
                onCitySelected: (value) => selectedCity = value,
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Cities'), findsOneWidget);
    expect(find.text('CITY COMPARISON'), findsOneWidget);
    expect(
      find.byKey(const Key('empireSectionHeader.Units.icon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('empireSectionHeader.Cities.icon')),
      findsOneWidget,
    );
    expect(find.text('Guard'), findsOneWidget);
    expect(find.text('Scout'), findsWidgets);
    expect(find.text('Capital'), findsWidgets);
    expect(find.textContaining("Artifact: Hero's Sword"), findsWidgets);

    await tester.ensureVisible(find.text('Guard'));
    await tester.pump();
    await tester.tap(find.text('Guard'));
    await tester.pump();
    expect(selectedUnit, unit);

    await tester.ensureVisible(find.text('Capital').last);
    await tester.pump();
    await tester.tap(find.text('Capital').last);
    await tester.pump();
    expect(selectedCity, city);
  });

  testWidgets('renders empty unit and city states', (tester) async {
    const viewModel = EmpireOverviewViewModel(
      units: [],
      cities: [],
      unitGroups: [],
      cityComparisons: [],
      readyUnitCount: 0,
      totalPopulation: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return EmpireOverviewContent(
                viewModel: viewModel,
                l10n: AppLocalizations.of(context),
                compact: false,
                onUnitSelected: (_) {},
                onCitySelected: (_) {},
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('No units'), findsOneWidget);
    expect(find.text('No cities'), findsOneWidget);
    expect(find.textContaining('New units will appear here'), findsOneWidget);
    expect(find.textContaining('Found your first city'), findsOneWidget);
  });

  testWidgets('keeps unit and city sections as separate ordered groups', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'unit_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Guard',
      col: 0,
      row: 0,
      movementPoints: 2,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      population: 3,
      center: CityHex(col: 1, row: 1),
    );
    final viewModel = EmpireOverviewViewModel.fromState(
      GameState(units: [unit], cities: [city]),
      activePlayerId: 'player_1',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return SizedBox(
                width: 820,
                height: 980,
                child: EmpireOverviewContent(
                  viewModel: viewModel,
                  l10n: AppLocalizations.of(context),
                  compact: false,
                  onUnitSelected: (_) {},
                  onCitySelected: (_) {},
                ),
              );
            },
          ),
        ),
      ),
    );

    final unitsTop = tester.getTopLeft(find.text('Units')).dy;
    final citiesTop = tester.getTopLeft(find.text('Cities')).dy;

    expect(unitsTop, lessThan(citiesTop));
  });
}
