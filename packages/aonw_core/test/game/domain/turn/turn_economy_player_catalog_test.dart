import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_player_catalog.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:test/test.dart';

void main() {
  test('matches legacy identity sources and intentional omissions', () {
    final diplomacy = DiplomacyState.empty.setStatus(
      'diplomacy_a',
      'diplomacy_b',
      DiplomaticRelationStatus.friendly,
    );
    final state = TurnEconomyState(
      playerGold: const {'gold_only': 1, '': 99},
      playerWarWeariness: const {'war_only': 1},
      playerStabilityNet: const {'stability_only': 1},
      units: [
        GameUnit.startingWarrior(ownerPlayerId: 'unit_owner', col: 0, row: 0),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'city_owner',
          foundingOwnerPlayerId: 'city_founder',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        ),
      ],
      artifacts: const [],
      fieldImprovements: const [],
      fogOfWar: FogOfWarState(
        players: {'fog_only': PlayerFogOfWar(playerId: 'fog_only')},
      ),
      research: ResearchState(
        players: const {'research_only': PlayerResearchState.empty},
      ),
      wonderRegistry: WonderRegistry(
        completedBy: const {WonderType.grandCathedral: 'wonder_owner'},
      ),
      diplomacy: diplomacy,
      resourceTradeAgreements: const [
        ResourceTradeAgreement(
          id: 'trade_1',
          exporterPlayerId: 'trade_exporter',
          importerPlayerId: 'trade_importer',
          resource: ResourceType.horses,
          goldPerTurn: 1,
          remainingTurns: 1,
        ),
      ],
      mapObjectiveHoldStatesByObjectiveId: const {
        'objective_1': MapObjectiveHoldState(
          objectiveId: 'objective_1',
          playerId: 'objective_only',
          holdTurns: 1,
        ),
      },
    );

    final playerIds = TurnEconomyPlayerCatalog.knownPlayerIds(
      state: state,
      basePlayerIds: const ['base_only', '', 'base_only'],
    );

    expect(playerIds, {
      'base_only',
      'gold_only',
      'war_only',
      'stability_only',
      'fog_only',
      'wonder_owner',
      'unit_owner',
      'city_owner',
      'city_founder',
      'diplomacy_a',
      'diplomacy_b',
    });
    expect(
      playerIds.intersection(const {
        '',
        'research_only',
        'trade_exporter',
        'trade_importer',
        'objective_only',
      }),
      isEmpty,
      reason: 'These sources were intentionally absent from legacy known IDs',
    );
  });
}
