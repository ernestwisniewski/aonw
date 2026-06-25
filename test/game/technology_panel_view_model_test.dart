import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TechnologyPanelViewModelFactory', () {
    final l10n = AppLocalizationsEn();

    test('marks foundation techs as available and later techs as locked', () {
      final city = _city();
      final model = TechnologyPanelViewModelFactory.create(
        state: GameState(cities: [city]),
        playerId: 'player_1',
        ruleset: TechnologyRulesets.standard,
        mapData: _map(),
        currentTurn: 5,
      );

      expect(model.sciencePerTurn, 2);
      expect(
        _card(model, TechnologyId.agriculture).state,
        TechnologyCardState.available,
      );
      expect(
        _card(model, TechnologyId.mining).state,
        TechnologyCardState.available,
      );
      expect(
        _card(model, TechnologyId.hunting).state,
        TechnologyCardState.available,
      );
      expect(
        _card(model, TechnologyId.trade).state,
        TechnologyCardState.locked,
      );
      expect(
        _card(model, TechnologyId.storage).state,
        TechnologyCardState.locked,
      );
    });

    test('marks active technology with progress and turns remaining', () {
      final city = _city();
      final model = TechnologyPanelViewModelFactory.create(
        state: GameState(
          cities: [city],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
                progressByTechnologyId: {TechnologyId.agriculture: 3},
              ),
            },
          ),
        ),
        playerId: 'player_1',
        ruleset: TechnologyRulesets.standard,
        mapData: _map(),
        currentTurn: 5,
      );

      final agriculture = _card(model, TechnologyId.agriculture);
      expect(model.activeTechnology?.id, TechnologyId.agriculture);
      expect(agriculture.state, TechnologyCardState.active);
      expect(agriculture.progress, 3);
      expect(agriculture.totalCost, 6);
      expect(agriculture.turnsRemaining, 2);
      expect(agriculture.completionTurn, 7);
      expect(agriculture.eta.compactLabel(l10n), '2 turns • T7');
    });

    test('marks researched technologies as completed', () {
      final model = TechnologyPanelViewModelFactory.create(
        state: GameState(
          cities: [_city()],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {TechnologyId.agriculture},
              ),
            },
          ),
        ),
        playerId: 'player_1',
        ruleset: TechnologyRulesets.standard,
        mapData: _map(),
      );

      final agriculture = _card(model, TechnologyId.agriculture);
      expect(agriculture.state, TechnologyCardState.researched);
      expect(agriculture.progress, agriculture.totalCost);
    });

    test('exposes at most three selectable recommended technologies', () {
      final model = TechnologyPanelViewModelFactory.create(
        state: GameState(cities: [_city()]),
        playerId: 'player_1',
        ruleset: TechnologyRulesets.standard,
        mapData: _mapWithResource(ResourceType.wheat),
      );

      final recommended = model.recommendedTechnologies;

      expect(recommended, hasLength(3));
      expect(
        recommended.every(
          (card) => card.state == TechnologyCardState.available,
        ),
        isTrue,
      );
      expect(
        recommended.map((card) => card.id),
        contains(TechnologyId.agriculture),
      );
      expect(recommended.first.id, TechnologyId.agriculture);
    });
  });
}

TechnologyCardViewModel _card(
  TechnologyPanelViewModel model,
  TechnologyId technologyId,
) {
  return model.technologies.singleWhere((card) => card.id == technologyId);
}

GameCity _city() {
  return const GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: 0, row: 0),
  );
}

MapData _map() {
  return MapData(
    cols: 1,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

MapData _mapWithResource(ResourceType resource) {
  return MapData(
    cols: 1,
    rows: 1,
    tiles: [
      TileData(
        col: 0,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: [resource],
        height: 0,
      ),
    ],
  );
}
