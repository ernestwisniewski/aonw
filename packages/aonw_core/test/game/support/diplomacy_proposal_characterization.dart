part of '../diplomacy_command_router_characterization_test.dart';

enum _KnownTargetSource { colors, countries, gold, fog, unitOwner, cityOwner }

void _registerProposalCharacterizationTests() {
  _registerProposalValidationTests();
  _registerProposalDiscoveryCatalogTests();
  _registerProposalPhysicalContactTests();
  _registerProposalRelationPolicyTests();
}

void _registerProposalValidationTests() {
  group('proposal validation precedence and identity', () {
    test('canAct=false wins before actor, target, and relation checks', () {
      final state = _diplomacyState(diplomacy: DiplomacyState.empty);
      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: _player1,
          targetPlayerId: _player1,
          kind: DiplomaticProposalKind.truce,
        ),
        actorPlayerId: 'spoofed_actor',
        canAct: false,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('actor mismatch wins before target validation', () {
      final state = _diplomacyState(diplomacy: DiplomacyState.empty);
      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: _player1,
          targetPlayerId: '',
          kind: DiplomaticProposalKind.friendship,
        ),
        actorPlayerId: _player2,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('an undiscovered target is rejected without changing snapshots', () {
      final state = _diplomacyState(
        playerColors: const {_player1: 1},
        playerCountries: const {},
        playerGold: const {_player1: 10},
        diplomacy: DiplomacyState.empty,
      );
      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          kind: DiplomaticProposalKind.friendship,
        ),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_target_not_discovered',
      );
    });

    test('proposal policy wins before duplicate detection', () {
      final diplomacy = DiplomacyState.empty
          .setStatus(_player1, _player2, DiplomaticRelationStatus.friendly)
          .addProposal(_proposal(kind: DiplomaticProposalKind.friendship));
      final state = _diplomacyState(diplomacy: diplomacy);
      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          kind: DiplomaticProposalKind.friendship,
        ),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(result, state, 'diplomacy_proposal_not_allowed');
    });

    test('duplicate is the final proposal rejection and keeps identity', () {
      final diplomacy = DiplomacyState.empty
          .addContact(_player1, _player2)
          .addProposal(_proposal(kind: DiplomaticProposalKind.friendship));
      final state = _diplomacyState(diplomacy: diplomacy);
      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          kind: DiplomaticProposalKind.friendship,
          proposalId: 'different_id',
        ),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(result, state, 'diplomacy_duplicate_proposal');
    });
  });
}

void _registerProposalDiscoveryCatalogTests() {
  group('proposal target discovery sources', () {
    for (final source in _KnownTargetSource.values) {
      test('${source.name} contributes the target player id', () {
        final state = _stateWithKnownTargetFrom(source);
        final result = _route(
          state,
          const SendDiplomaticProposalCommand(
            playerId: _player1,
            targetPlayerId: _player2,
            kind: DiplomaticProposalKind.friendship,
            proposalId: 'known_target',
          ),
          actorPlayerId: _player1,
        );

        expect(result.accepted, isTrue);
        expect(
          result.state.diplomacy.pendingProposals,
          contains('known_target'),
        );
      });
    }

    test('broader DomainState.knownPlayerIds is not consulted', () {
      final state = _diplomacyState(
        playerColors: const {_player1: 1},
        playerCountries: const {},
        playerGold: const {_player1: 10},
        playerWarWeariness: const {_player2: 3},
        playerStabilityNet: const {_player2: 4},
        diplomacy: DiplomacyState.empty.addContact(_player1, _player2),
        submittedPlayerIds: const {_player2},
        dominationHoldTurnsByPlayerId: const {_player2: 2},
      );
      expect(state.knownPlayerIds, contains(_player2));

      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          kind: DiplomaticProposalKind.friendship,
        ),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_target_not_discovered',
      );
    });
  });
}

void _registerProposalPhysicalContactTests() {
  group('proposal physical contact', () {
    test('known target without stored or physical contact is rejected', () {
      final state = _diplomacyState(
        playerColors: const {_player1: 1, _player2: 2},
        playerCountries: const {},
        playerGold: const {},
        diplomacy: DiplomacyState.empty,
      );
      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          kind: DiplomaticProposalKind.friendship,
        ),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_target_not_discovered',
      );
    });

    test('a visible target unit establishes physical contact', () {
      final state = _diplomacyState(
        playerColors: const {},
        playerCountries: const {},
        playerGold: const {},
        fogOfWar: FogOfWarState(
          players: {
            _player1: PlayerFogOfWar(
              playerId: _player1,
              visibleHexes: {const HexCoordinate(col: 2, row: 0)},
            ),
          },
        ),
        units: [
          GameUnit.produced(
            id: 'visible_target',
            ownerPlayerId: _player2,
            type: GameUnitType.warrior,
            col: 2,
            row: 0,
          ),
        ],
        diplomacy: DiplomacyState.empty,
      );
      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          kind: DiplomaticProposalKind.friendship,
          proposalId: 'unit_contact',
        ),
        actorPlayerId: _player1,
      );

      expect(result.accepted, isTrue);
    });

    test('a remembered target city establishes physical contact', () {
      final state = _diplomacyState(
        playerColors: const {},
        playerCountries: const {},
        playerGold: const {},
        fogOfWar: FogOfWarState(
          players: {
            _player1: PlayerFogOfWar(
              playerId: _player1,
              discoveredHexes: {const HexCoordinate(col: 3, row: 0)},
            ),
          },
        ),
        cities: const [
          GameCity(
            id: 'remembered_target',
            ownerPlayerId: _player2,
            name: 'Remembered City',
            center: CityHex(col: 3, row: 0),
          ),
        ],
        diplomacy: DiplomacyState.empty,
      );
      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          kind: DiplomaticProposalKind.friendship,
          proposalId: 'city_contact',
        ),
        actorPlayerId: _player1,
      );

      expect(result.accepted, isTrue);
    });
  });
}

void _registerProposalRelationPolicyTests() {
  group('proposal relation policy', () {
    const cases = <(DiplomaticProposalKind, DiplomaticRelationStatus, bool)>[
      (
        DiplomaticProposalKind.friendship,
        DiplomaticRelationStatus.neutral,
        true,
      ),
      (
        DiplomaticProposalKind.friendship,
        DiplomaticRelationStatus.hostile,
        true,
      ),
      (DiplomaticProposalKind.friendship, DiplomaticRelationStatus.truce, true),
      (
        DiplomaticProposalKind.friendship,
        DiplomaticRelationStatus.friendly,
        false,
      ),
      (DiplomaticProposalKind.friendship, DiplomaticRelationStatus.war, false),
      (DiplomaticProposalKind.truce, DiplomaticRelationStatus.hostile, true),
      (DiplomaticProposalKind.truce, DiplomaticRelationStatus.war, true),
      (DiplomaticProposalKind.truce, DiplomaticRelationStatus.neutral, false),
      (DiplomaticProposalKind.truce, DiplomaticRelationStatus.friendly, false),
      (DiplomaticProposalKind.truce, DiplomaticRelationStatus.truce, false),
    ];

    for (final (kind, status, accepted) in cases) {
      test('${kind.name} from ${status.name} => $accepted', () {
        final diplomacy = status == DiplomaticRelationStatus.neutral
            ? DiplomacyState.empty.addContact(_player1, _player2)
            : DiplomacyState.empty.setStatus(_player1, _player2, status);
        final state = _diplomacyState(diplomacy: diplomacy);
        final result = _route(
          state,
          SendDiplomaticProposalCommand(
            playerId: _player1,
            targetPlayerId: _player2,
            kind: kind,
            proposalId: 'policy_case',
          ),
          actorPlayerId: _player1,
        );

        expect(result.accepted, accepted);
        if (!accepted) {
          _expectRejectedDiplomacy(
            result,
            state,
            'diplomacy_proposal_not_allowed',
          );
        }
      });
    }
  });
}

DomainState _stateWithKnownTargetFrom(_KnownTargetSource source) {
  return _diplomacyState(
    playerColors: source == _KnownTargetSource.colors
        ? const {_player2: 2}
        : const {},
    playerCountries: source == _KnownTargetSource.countries
        ? const {_player2: PlayerCountry.japan}
        : const {},
    playerGold: source == _KnownTargetSource.gold
        ? const {_player2: 1}
        : const {},
    fogOfWar: source == _KnownTargetSource.fog
        ? FogOfWarState(players: {_player2: PlayerFogOfWar(playerId: _player2)})
        : FogOfWarState.empty,
    units: source == _KnownTargetSource.unitOwner
        ? [
            GameUnit.produced(
              id: 'target_unit',
              ownerPlayerId: _player2,
              type: GameUnitType.warrior,
              col: 2,
              row: 0,
            ),
          ]
        : const [],
    cities: source == _KnownTargetSource.cityOwner
        ? const [
            GameCity(
              id: 'target_city',
              ownerPlayerId: _player2,
              name: 'Target City',
              center: CityHex(col: 2, row: 0),
            ),
          ]
        : const [],
    diplomacy: DiplomacyState.empty.addContact(_player1, _player2),
  );
}
