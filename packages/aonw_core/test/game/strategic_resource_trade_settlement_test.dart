import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_resource_trade_economy_advancer.dart';
import 'package:test/test.dart';

void main() {
  group('strategic resource trade settlement', () {
    test('moves one stockpiled unit through an active agreement', () {
      final state = _economyState(
        playerGold: const {'exporter': 0, 'importer': 5},
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'exporter': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.oilOne,
            ),
          },
        ),
        agreements: const [
          ResourceTradeAgreement(
            id: 'oil_trade',
            exporterPlayerId: 'exporter',
            importerPlayerId: 'importer',
            resource: ResourceType.oil,
            goldPerTurn: 2,
            remainingTurns: 2,
          ),
        ],
      );

      final delivered = _advance(state, const ['importer']);

      expect(delivered.playerGold, {'exporter': 2, 'importer': 3});
      expect(_amount(delivered, 'exporter', ResourceType.oil), 0);
      expect(_amount(delivered, 'importer', ResourceType.oil), 1);
      expect(delivered.resourceTradeAgreements.single.remainingTurns, 1);
    });

    test('failed stockpile delivery does not charge the importer', () {
      final state = _economyState(
        playerGold: const {'exporter': 0, 'importer': 5},
        agreements: const [
          ResourceTradeAgreement(
            id: 'oil_trade',
            exporterPlayerId: 'exporter',
            importerPlayerId: 'importer',
            resource: ResourceType.oil,
            goldPerTurn: 2,
            remainingTurns: 1,
          ),
        ],
      );

      final failed = _advance(state, const ['importer']);

      expect(failed.playerGold, state.playerGold);
      expect(failed.strategicResources, state.strategicResources);
      expect(failed.resourceTradeAgreements, isEmpty);
    });

    test('moves the configured amount and reads legacy amount as one', () {
      const agreement = ResourceTradeAgreement(
        id: 'oil_trade',
        exporterPlayerId: 'exporter',
        importerPlayerId: 'importer',
        resource: ResourceType.oil,
        goldPerTurn: 0,
        remainingTurns: 1,
        amountPerTurn: 2,
      );
      final state = _economyState(
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'exporter': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.oilTwo,
            ),
          },
        ),
        agreements: const [agreement],
      );

      final delivered = _advance(state, const ['importer']);
      final legacy = ResourceTradeAgreement.fromJson({
        'id': 'legacy',
        'exporterPlayerId': 'exporter',
        'importerPlayerId': 'importer',
        'resource': 'oil',
        'remainingTurns': 1,
      });

      expect(_amount(delivered, 'importer', ResourceType.oil), 2);
      expect(legacy.amountPerTurn, 1);
      expect(legacy.exchangeGroupId, isNull);
      expect(ResourceTradeAgreement.fromJson(agreement.toJson()), agreement);
    });

    test('does not partially settle a grouped barter', () {
      final state = _economyState(
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'p1': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.oilOne,
            ),
          },
        ),
        agreements: const [
          ResourceTradeAgreement(
            id: 'barter_oil',
            exporterPlayerId: 'p1',
            importerPlayerId: 'p2',
            resource: ResourceType.oil,
            goldPerTurn: 0,
            remainingTurns: 1,
            exchangeGroupId: 'barter',
          ),
          ResourceTradeAgreement(
            id: 'barter_aluminium',
            exporterPlayerId: 'p2',
            importerPlayerId: 'p1',
            resource: ResourceType.aluminium,
            goldPerTurn: 0,
            remainingTurns: 1,
            exchangeGroupId: 'barter',
          ),
        ],
      );

      final blocked = _advance(state, const ['p1', 'p2']);

      expect(blocked.strategicResources, state.strategicResources);
      expect(blocked.resourceTradeAgreements, isEmpty);
    });

    test('settles grouped barter deterministically when fully funded', () {
      const agreements = [
        ResourceTradeAgreement(
          id: 'barter_oil',
          exporterPlayerId: 'p1',
          importerPlayerId: 'p2',
          resource: ResourceType.oil,
          goldPerTurn: 0,
          remainingTurns: 2,
          exchangeGroupId: 'barter',
        ),
        ResourceTradeAgreement(
          id: 'barter_aluminium',
          exporterPlayerId: 'p2',
          importerPlayerId: 'p1',
          resource: ResourceType.aluminium,
          goldPerTurn: 0,
          remainingTurns: 2,
          exchangeGroupId: 'barter',
        ),
      ];
      final accounts = StrategicResourceAccounts(
        byPlayerId: {
          'p1': StrategicResourceStockpile(
            onHand: StrategicResourceBundle.oilOne,
          ),
          'p2': StrategicResourceStockpile(
            onHand: StrategicResourceBundle.aluminiumOne,
          ),
        },
      );
      final forward = _advance(
        _economyState(strategicResources: accounts, agreements: agreements),
        const ['p1', 'p2'],
      );
      final reversed = _advance(
        _economyState(
          strategicResources: accounts,
          agreements: agreements.reversed.toList(),
        ),
        const ['p2', 'p1'],
      );

      expect(
        forward.strategicResources.forPlayer('p1').onHand,
        StrategicResourceBundle.aluminiumOne,
      );
      expect(
        forward.strategicResources.forPlayer('p2').onHand,
        StrategicResourceBundle.oilOne,
      );
      expect(
        forward.resourceTradeAgreements.map((value) => value.remainingTurns),
        everyElement(1),
      );
      expect(reversed.strategicResources, forward.strategicResources);
      expect(reversed.resourceTradeAgreements, forward.resourceTradeAgreements);
    });

    test('settles grouped barter only once in a sequential round', () {
      final state = _economyState(
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'a': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.oilTwo,
            ),
            'b': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.aluminiumOne,
            ),
          },
        ),
        agreements: const [
          ResourceTradeAgreement(
            id: 'barter_aluminium',
            exchangeGroupId: 'barter',
            exporterPlayerId: 'b',
            importerPlayerId: 'a',
            resource: ResourceType.aluminium,
            goldPerTurn: 0,
            remainingTurns: 2,
          ),
          ResourceTradeAgreement(
            id: 'barter_oil',
            exchangeGroupId: 'barter',
            exporterPlayerId: 'a',
            importerPlayerId: 'b',
            resource: ResourceType.oil,
            goldPerTurn: 0,
            remainingTurns: 2,
          ),
        ],
      );

      final firstPlayer = _advance(state, const ['a']);
      final secondPlayer = _advance(firstPlayer, const ['b']);

      expect(_amount(secondPlayer, 'a', ResourceType.oil), 1);
      expect(_amount(secondPlayer, 'a', ResourceType.aluminium), 1);
      expect(_amount(secondPlayer, 'b', ResourceType.oil), 1);
      expect(
        secondPlayer.resourceTradeAgreements.map(
          (agreement) => agreement.remainingTurns,
        ),
        everyElement(1),
      );
    });

    test('war blocks delivery and payment while the contract ages', () {
      final state = _economyState(
        playerGold: const {'exporter': 0, 'importer': 5},
        diplomacy: DiplomacyState.empty.setStatus(
          'exporter',
          'importer',
          DiplomaticRelationStatus.war,
        ),
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'exporter': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.oilOne,
            ),
          },
        ),
        agreements: const [
          ResourceTradeAgreement(
            id: 'oil_trade',
            exporterPlayerId: 'exporter',
            importerPlayerId: 'importer',
            resource: ResourceType.oil,
            goldPerTurn: 2,
            remainingTurns: 2,
          ),
        ],
      );

      final blocked = _advance(state, const ['importer']);

      expect(blocked.playerGold, state.playerGold);
      expect(blocked.strategicResources, state.strategicResources);
      expect(blocked.resourceTradeAgreements.single.remainingTurns, 1);
    });
  });
}

TurnEconomyState _advance(TurnEconomyState state, List<String> playerIds) =>
    TurnResourceTradeEconomyAdvancer.advance(
      state: state,
      playerIds: playerIds,
    );

int _amount(TurnEconomyState state, String playerId, ResourceType resource) =>
    state.strategicResources.forPlayer(playerId).amountFor(resource);

TurnEconomyState _economyState({
  Map<String, int> playerGold = const {},
  StrategicResourceAccounts strategicResources =
      StrategicResourceAccounts.empty,
  DiplomacyState diplomacy = DiplomacyState.empty,
  List<ResourceTradeAgreement> agreements = const [],
}) => TurnEconomyState(
  playerGold: playerGold,
  playerWarWeariness: const {},
  playerStabilityNet: const {},
  strategicResources: strategicResources,
  diplomacy: diplomacy,
  units: const [],
  cities: const [],
  artifacts: const [],
  fieldImprovements: const [],
  fogOfWar: FogOfWarState.empty,
  research: ResearchState.empty,
  wonderRegistry: WonderRegistry.empty,
  resourceTradeAgreements: agreements,
  mapObjectiveHoldStatesByObjectiveId: const {},
);
