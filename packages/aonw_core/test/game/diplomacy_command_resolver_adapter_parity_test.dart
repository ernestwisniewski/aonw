import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _player1 = 'p1';
const _player2 = 'p2';
const _observer = 'p3';

void main() {
  group('diplomacy kernel and state adapters', () {
    test('paid truce has exact state and event parity', () {
      final diplomacy = DiplomacyState.empty
          .addContact(_player1, _player2)
          .setStatus(_player1, _player2, DiplomaticRelationStatus.war)
          .addProposal(
            const DiplomaticProposal(
              id: 'paid_truce',
              fromPlayerId: _player1,
              toPlayerId: _player2,
              kind: DiplomaticProposalKind.truce,
              createdTurn: 4,
              expiresOnTurn: 9,
              goldPayment: 7,
            ),
          );
      final units = [
        GameUnit.produced(
          id: 'attacker',
          ownerPlayerId: _player1,
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        ),
        GameUnit.produced(
          id: 'defender',
          ownerPlayerId: _player2,
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
      ];
      const attacks = [
        IntendedAttack(
          attackerUnitId: 'attacker',
          defenderCol: 1,
          defenderRow: 0,
          declaredAtTick: 3,
          declaringPlayerId: _player1,
        ),
      ];
      final states = _states(
        diplomacy: diplomacy,
        units: units,
        intendedAttacks: attacks,
      );
      const command = RespondDiplomaticProposalCommand(
        playerId: _player2,
        proposalId: 'paid_truce',
        accepted: true,
      );

      final results = _resolveAll(states, command, actorPlayerId: _player2);

      _expectAcceptedParity(results);
      expect(results.kernel.playerGold, {
        _player1: 13,
        _player2: 10,
        _observer: 9,
      });
      expect(results.kernel.intendedAttacks, isEmpty);
      expect(
        results.kernel.diplomacy.statusBetween(_player1, _player2),
        DiplomaticRelationStatus.truce,
      );
      expect(
        results.kernel.resourceTradeAgreements,
        same(states.domain.resourceTradeAgreements),
      );
      expect(
        results.persistent.state.runtimeState.resourceTradeAgreements,
        same(states.persistent.runtimeState.resourceTradeAgreements),
      );
      expect(
        results.domain.state.resourceTradeAgreements,
        same(states.domain.resourceTradeAgreements),
      );
    });

    test('war removes only pair trades at both state boundaries', () {
      final states = _states(
        diplomacy: DiplomacyState.empty
            .addContact(_player1, _player2)
            .addContact(_player1, _observer)
            .addContact(_player2, _observer),
        resourceTradeAgreements: const [
          ResourceTradeAgreement(
            id: 'pair_trade',
            exporterPlayerId: _player2,
            importerPlayerId: _player1,
            resource: ResourceType.horses,
            goldPerTurn: 3,
            remainingTurns: 5,
          ),
          ResourceTradeAgreement(
            id: 'observer_trade',
            exporterPlayerId: _observer,
            importerPlayerId: _player1,
            resource: ResourceType.iron,
            goldPerTurn: 2,
            remainingTurns: 6,
          ),
        ],
      );
      const command = DeclareWarCommand(
        playerId: _player1,
        targetPlayerId: _player2,
      );

      final results = _resolveAll(states, command, actorPlayerId: _player1);

      _expectAcceptedParity(results);
      expect(results.kernel.resourceTradeAgreements.map((trade) => trade.id), [
        'observer_trade',
      ]);
      expect(results.kernel.playerGold, same(states.domain.playerGold));
      expect(
        results.persistent.state.playerGold,
        same(states.persistent.playerGold),
      );
      expect(results.domain.state.playerGold, same(states.domain.playerGold));
      expect(
        results.kernel.intendedAttacks,
        same(states.domain.intendedAttacks),
      );
    });

    test('diplomacy-only acceptance preserves all other slice identities', () {
      final states = _states();
      const command = SendDiplomaticProposalCommand(
        playerId: _player1,
        targetPlayerId: _player2,
        kind: DiplomaticProposalKind.friendship,
        proposalId: 'friendship',
      );

      final results = _resolveAll(states, command, actorPlayerId: _player1);

      _expectAcceptedParity(results);
      _expectUnchangedSliceIdentities(states, results);
      expect(results.kernel.diplomacy, isNot(same(states.domain.diplomacy)));
      expect(
        results.persistent.state.runtimeState.diplomacy,
        isNot(same(states.persistent.runtimeState.diplomacy)),
      );
      expect(
        results.domain.state.diplomacy,
        isNot(same(states.domain.diplomacy)),
      );
      expect(
        results.persistent.state.playerWarWeariness,
        same(states.persistent.playerWarWeariness),
      );
      expect(
        results.domain.state.playerWarWeariness,
        same(states.domain.playerWarWeariness),
      );
    });

    test(
      'rejection preserves all kernel slices and complete state identities',
      () {
        final states = _states();
        const command = SendGoldGiftCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          amount: 10,
        );

        final results = _resolveAll(states, command, actorPlayerId: _player2);

        expect(results.kernel.accepted, isFalse);
        expect(results.persistent.accepted, isFalse);
        expect(results.domain.accepted, isFalse);
        expect(results.kernel.reason, 'diplomacy_player_not_controlled');
        expect(results.persistent.reason, results.kernel.reason);
        expect(results.domain.reason, results.kernel.reason);
        expect(results.kernel.events, isEmpty);
        expect(results.persistent.events, isEmpty);
        expect(results.domain.events, isEmpty);
        expect(results.kernel.playerGold, same(states.domain.playerGold));
        expect(results.kernel.diplomacy, same(states.domain.diplomacy));
        expect(
          results.kernel.intendedAttacks,
          same(states.domain.intendedAttacks),
        );
        expect(
          results.kernel.resourceTradeAgreements,
          same(states.domain.resourceTradeAgreements),
        );
        expect(results.persistent.state, same(states.persistent));
        expect(results.domain.state, same(states.domain));
      },
    );

    test('compatibility router preserves resolver injection', () {
      final states = _states();
      final resolver = _RecordingPersistentDiplomacyResolver();
      const command = SendDiplomaticProposalCommand(
        playerId: _player1,
        targetPlayerId: _player2,
        kind: DiplomaticProposalKind.friendship,
      );

      final result = DiplomacyCommandRouter(resolver: resolver).route(
        state: states.persistent,
        command: command,
        actorPlayerId: _player1,
        turn: 5,
      );

      expect(result.accepted, isTrue);
      expect(resolver.sendProposalCalls, 1);
    });
  });
}

final class _RecordingPersistentDiplomacyResolver
    extends PersistentDiplomacyResolver {
  int sendProposalCalls = 0;

  @override
  PersistentDiplomacyResult sendProposal({
    required PersistentGameState state,
    required SendDiplomaticProposalCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    sendProposalCalls++;
    return super.sendProposal(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      turn: turn,
      canAct: canAct,
    );
  }
}

typedef _DiplomacyStates = ({
  PersistentGameState persistent,
  DomainState domain,
});

typedef _DiplomacyResults = ({
  DiplomacyCommandResult kernel,
  PersistentDiplomacyResult persistent,
  DomainDiplomacyCommandResult domain,
});

_DiplomacyStates _states({
  Map<String, int> playerGold = const {_player1: 20, _player2: 3, _observer: 9},
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  DiplomacyState? diplomacy,
  List<IntendedAttack> intendedAttacks = const [],
  List<ResourceTradeAgreement> resourceTradeAgreements = const [],
}) {
  final resolvedDiplomacy =
      diplomacy ?? DiplomacyState.empty.addContact(_player1, _player2);
  final persistentRuntime = GameRuntimeState.snapshot(
    submittedPlayerIds: const {'sentinel'},
    timeoutStreaksByPlayerId: const {'sentinel': 2},
    intendedAttacks: intendedAttacks,
    diplomacy: resolvedDiplomacy,
    resourceTradeAgreements: resourceTradeAgreements,
    turnStartedAt: DateTime.utc(2026, 7, 22),
  );
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {_player1: 1, _player2: 2, _observer: 3},
      playerCountries: const {
        _player1: PlayerCountry.poland,
        _player2: PlayerCountry.japan,
        _observer: PlayerCountry.egypt,
      },
      playerGold: playerGold,
      playerWarWeariness: const {'sentinel': 4},
      playerStabilityNet: const {'sentinel': 5},
      units: units,
      cities: cities,
      runtimeState: persistentRuntime,
    ),
    domain: DomainState.snapshot(
      turn: 5,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: _player1, name: 'One', colorValue: 1),
        Player(
          id: _player2,
          name: 'Two',
          colorValue: 2,
          country: PlayerCountry.japan,
        ),
        Player(
          id: _observer,
          name: 'Observer',
          colorValue: 3,
          country: PlayerCountry.egypt,
        ),
      ],
      playerGold: playerGold,
      playerWarWeariness: const {'sentinel': 4},
      playerStabilityNet: const {'sentinel': 5},
      units: units,
      cities: cities,
      intendedAttacks: intendedAttacks,
      diplomacy: resolvedDiplomacy,
      resourceTradeAgreements: resourceTradeAgreements,
    ),
  );
}

_DiplomacyResults _resolveAll(
  _DiplomacyStates states,
  DiplomaticCommand command, {
  required String actorPlayerId,
  int turn = 5,
  bool canAct = true,
}) {
  final domain = states.domain;
  return (
    kernel: DiplomacyCommandResolver.resolve(
      state: DiplomacyCommandState(
        playerColors: domain.playerColors,
        playerCountries: domain.playerCountries,
        playerGold: domain.playerGold,
        units: domain.units,
        cities: domain.cities,
        fogOfWar: domain.fogOfWar,
        diplomacy: domain.diplomacy,
        intendedAttacks: domain.intendedAttacks,
        resourceTradeAgreements: domain.resourceTradeAgreements,
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      turn: turn,
      canAct: canAct,
    ),
    persistent: PersistentDiplomacyResolver.resolve(
      state: states.persistent,
      command: command,
      actorPlayerId: actorPlayerId,
      turn: turn,
      canAct: canAct,
    ),
    domain: const DomainDiplomacyCommandResolver().resolve(
      state: domain,
      command: command,
      actorPlayerId: actorPlayerId,
      turn: turn,
      canAct: canAct,
    ),
  );
}

void _expectAcceptedParity(_DiplomacyResults results) {
  expect(results.kernel.accepted, isTrue);
  expect(results.persistent.accepted, isTrue);
  expect(results.domain.accepted, isTrue);
  expect(results.kernel.reason, isNull);
  expect(results.persistent.reason, isNull);
  expect(results.domain.reason, isNull);
  expect(results.persistent.state.playerGold, results.kernel.playerGold);
  expect(results.domain.state.playerGold, results.kernel.playerGold);
  expect(
    results.persistent.state.runtimeState.diplomacy,
    results.kernel.diplomacy,
  );
  expect(results.domain.state.diplomacy, results.kernel.diplomacy);
  expect(
    results.persistent.state.runtimeState.intendedAttacks,
    results.kernel.intendedAttacks,
  );
  expect(results.domain.state.intendedAttacks, results.kernel.intendedAttacks);
  expect(
    results.persistent.state.runtimeState.resourceTradeAgreements,
    results.kernel.resourceTradeAgreements,
  );
  expect(
    results.domain.state.resourceTradeAgreements,
    results.kernel.resourceTradeAgreements,
  );
  final kernelEvents = results.kernel.events.map(GameEventSerializer.toJson);
  final persistentEvents = results.persistent.events.map(
    GameEventSerializer.toJson,
  );
  final domainEvents = results.domain.events.map(GameEventSerializer.toJson);
  expect(persistentEvents, kernelEvents);
  expect(domainEvents, kernelEvents);
}

void _expectUnchangedSliceIdentities(
  _DiplomacyStates states,
  _DiplomacyResults results,
) {
  expect(results.kernel.playerGold, same(states.domain.playerGold));
  expect(results.kernel.intendedAttacks, same(states.domain.intendedAttacks));
  expect(
    results.kernel.resourceTradeAgreements,
    same(states.domain.resourceTradeAgreements),
  );
  expect(
    results.persistent.state.playerGold,
    same(states.persistent.playerGold),
  );
  expect(
    results.persistent.state.runtimeState.intendedAttacks,
    same(states.persistent.runtimeState.intendedAttacks),
  );
  expect(
    results.persistent.state.runtimeState.resourceTradeAgreements,
    same(states.persistent.runtimeState.resourceTradeAgreements),
  );
  expect(results.domain.state.playerGold, same(states.domain.playerGold));
  expect(
    results.domain.state.intendedAttacks,
    same(states.domain.intendedAttacks),
  );
  expect(
    results.domain.state.resourceTradeAgreements,
    same(states.domain.resourceTradeAgreements),
  );
}
