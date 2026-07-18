import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('persistent and domain adapters forward the standard pace', () {
    final research = ResearchState(
      players: {'player_1': PlayerResearchState(scienceOverflow: 10)},
    );
    final persistent = PersistentGameState.snapshot(research: research);
    final domain = DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: const [
        Player(
          id: 'player_1',
          name: 'Player',
          colorValue: 1,
          country: PlayerCountry.poland,
        ),
      ],
      research: research,
    );
    const command = SelectTechnologyCommand(
      'player_1',
      TechnologyId.agriculture,
    );

    final persistentResult = const PersistentResearchCommandResolver()
        .selectTechnology(
          state: persistent,
          command: command,
          actorPlayerId: 'player_1',
          paceBalance: PaceBalance.standard60,
        );
    final domainResult = const DomainResearchCommandResolver().selectTechnology(
      state: domain,
      command: command,
      actorPlayerId: 'player_1',
      paceBalance: PaceBalance.standard60,
    );

    final persistentResearch = persistentResult.state.research.forPlayer(
      'player_1',
    );
    final domainResearch = domainResult.state.research.forPlayer('player_1');
    expect(persistentResult.accepted, isTrue);
    expect(domainResult.accepted, isTrue);
    expect(persistentResearch.progressFor(TechnologyId.agriculture), 2);
    expect(domainResearch, persistentResearch);
  });

  test('kernel forwards owned field improvements to boost evaluation', () {
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.agriculture},
          scienceOverflow: 10,
        ),
      },
    );

    final result = SelectTechnologyResolver.selectTechnology(
      research: research,
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        ),
      ],
      fieldImprovements: const [
        FieldImprovement(
          hex: CityHex(col: 1, row: 0),
          type: FieldImprovementType.farm,
          builtByCityId: 'city_1',
        ),
        FieldImprovement(
          hex: CityHex(col: 0, row: 1),
          type: FieldImprovementType.farm,
          builtByCityId: 'city_1',
        ),
      ],
      command: const SelectTechnologyCommand('player_1', TechnologyId.storage),
      actorPlayerId: 'player_1',
      mapTiles: const _EmptyMapTiles(),
    );

    expect(result.accepted, isTrue);
    expect(
      result.research.forPlayer('player_1').progressFor(TechnologyId.storage),
      4,
    );
  });
}

final class _EmptyMapTiles implements MapTileLookup {
  const _EmptyMapTiles();

  @override
  MapTileView? tileAt(int col, int row) => null;
}
