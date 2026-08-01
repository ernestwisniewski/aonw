part of '../player_match_view_projector_test.dart';

void _registerPlayerMatchProjectionGuardTests({
  required PlayerMatchViewProjector projector,
  required MatchRecipient owner,
  required MatchRecipient guest,
}) {
  test('fails closed when snapshot schema gains an unreviewed field', () {
    final canonical = playerMatchViewProjectionFixture;
    final withUnknownField = canonical.copyWith(
      state: {...canonical.state, 'futureSecret': 'must-not-pass-through'},
    );

    expect(
      () => projector.snapshotFor(withUnknownField, owner),
      throwsFormatException,
    );
  });

  test('fails closed when runtime schema gains an unreviewed field', () {
    final canonical = playerMatchViewProjectionFixture;
    final runtime = Map<String, dynamic>.from(
      canonical.state['lifecycle'] as Map,
    );
    final withUnknownField = canonical.copyWith(
      state: {
        ...canonical.state,
        'lifecycle': {...runtime, 'futureRuntimeSecret': true},
      },
    );

    expect(
      () => projector.snapshotFor(withUnknownField, owner),
      throwsFormatException,
    );
  });

  test('rejects an unknown game save field before canonical decode', () {
    var snapshotDecodes = 0;
    final countingProjector = PlayerMatchViewProjector(
      decodeSnapshot: (snapshot) {
        snapshotDecodes += 1;
        return const LosslessMatchSnapshotDecoder().decode(snapshot);
      },
    );
    final canonical = playerMatchViewProjectionFixture;
    final withUnknownField = canonical.copyWith(
      save: {...canonical.save, 'futureSaveSecret': true},
    );

    expect(
      () => countingProjector.prepareSnapshot(withUnknownField),
      throwsFormatException,
    );
    expect(snapshotDecodes, 0);
  });

  test('omits a serialized null turnStartedAt from the projected wire', () {
    final canonical = playerMatchViewProjectionFixture;
    final runtime = Map<String, dynamic>.from(
      canonical.state['lifecycle']! as Map,
    )..['turnStartedAt'] = null;
    final withExplicitNull = canonical.copyWith(
      state: {...canonical.state, 'lifecycle': runtime},
    );

    final projected = projector.snapshotFor(withExplicitNull, owner);
    final projectedRuntime = projected.state['lifecycle']! as Map;

    expect(projectedRuntime, isNot(contains('turnStartedAt')));
  });

  test('restores complete public identity maps from canonical roster', () {
    final canonical = playerMatchViewProjectionFixture;
    final colors = Map<String, dynamic>.from(
      canonical.state['playerColors']! as Map,
    )..remove('player-ai');
    final incompleteRoster = canonical.copyWith(
      state: {...canonical.state, 'playerColors': colors},
    );

    final projected = projector.snapshotFor(incompleteRoster, owner);

    expect(projected.state['playerColors'], canonical.state['playerColors']);
  });

  test('retains canonical roster identity for diplomacy contacts', () {
    final canonical = playerMatchViewProjectionFixture;
    final colors = Map<String, dynamic>.from(
      canonical.state['playerColors']! as Map,
    )..remove('player-ai');
    final countries = Map<String, dynamic>.from(
      canonical.state['playerCountries']! as Map,
    )..remove('player-ai');
    final sparseRoster = canonical.copyWith(
      state: {
        ...canonical.state,
        'playerColors': colors,
        'playerCountries': countries,
      },
    );

    final projected = projector.snapshotFor(sparseRoster, owner);
    final state = CanonicalGameSnapshotCodec.decodeDomainState(projected.state);

    expect(state.playerColors, contains('player-ai'));
    expect(state.playerCountries, contains('player-ai'));
    expect(
      state.diplomacy.contactKeys,
      isNot(contains(DiplomacyState.relationKey('player-owner', 'player-ai'))),
    );
  });

  test('fails closed when private state references a phantom player', () {
    final canonical = playerMatchViewProjectionFixture;
    final runtime = Map<String, dynamic>.from(
      canonical.state['lifecycle']! as Map,
    );
    final pendingAction = Map<String, dynamic>.from(
      runtime['pendingAction']! as Map,
    )..['ownerPlayerId'] = 'phantom-private-player';
    final phantomOwner = canonical.copyWith(
      state: {
        ...canonical.state,
        'lifecycle': {...runtime, 'pendingAction': pendingAction},
      },
    );

    expect(
      () => projector.prepareSnapshot(phantomOwner),
      throwsFormatException,
    );
  });

  test('fails closed when diplomacy references a phantom player', () {
    final canonical = playerMatchViewProjectionFixture;
    final runtime = Map<String, dynamic>.from(
      canonical.state['lifecycle']! as Map,
    );
    final diplomacy = Map<String, dynamic>.from(runtime['diplomacy']! as Map);
    final proposals = [
      for (final proposal in diplomacy['pendingProposals']! as List)
        Map<String, dynamic>.from(proposal as Map),
    ];
    proposals.first['fromPlayerId'] = 'phantom-diplomacy-player';
    final phantomDiplomacy = canonical.copyWith(
      state: {
        ...canonical.state,
        'lifecycle': {
          ...runtime,
          'diplomacy': {...diplomacy, 'pendingProposals': proposals},
        },
      },
    );

    expect(
      () => projector.prepareSnapshot(phantomDiplomacy),
      throwsFormatException,
    );
  });

  test('fails closed when diplomacy contains an unknown contact', () {
    final canonical = playerMatchViewProjectionFixture;
    final runtime = Map<String, dynamic>.from(
      canonical.state['lifecycle']! as Map,
    );
    final diplomacy = Map<String, dynamic>.from(runtime['diplomacy']! as Map);
    final unknownContact = canonical.copyWith(
      state: {
        ...canonical.state,
        'lifecycle': {
          ...runtime,
          'diplomacy': {
            ...diplomacy,
            'contacts': [
              ...diplomacy['contacts']! as List,
              DiplomacyState.relationKey(
                'player-owner',
                'phantom-contact-player',
              ),
            ],
          },
        },
      },
    );

    expect(
      () => projector.prepareSnapshot(unknownContact),
      throwsFormatException,
    );
  });

  test('restores an absent public identity map from canonical roster', () {
    final canonical = playerMatchViewProjectionFixture;
    final stateWithoutCountries = Map<String, dynamic>.from(canonical.state)
      ..remove('playerCountries');

    final projected = projector.snapshotFor(
      canonical.copyWith(state: stateWithoutCountries),
      owner,
    );

    expect(
      projected.state['playerCountries'],
      canonical.state['playerCountries'],
    );
  });

  test('messageFor prepares and projects a snapshot once', () {
    final canonical = playerMatchViewProjectionFixture;
    final projected = projector.messageFor(
      MultiplayerServerMessage(
        serverMessageId: 'one-shot',
        matchId: canonical.matchId,
        offset: canonical.offset,
        snapshot: canonical,
      ),
      owner,
    );

    expect(
      CanonicalGameSnapshotCodec.decodeDomainState(
        projected.snapshot!.state,
      ).playerGold,
      {'player-owner': 111},
    );
  });

  final preparedSnapshot = playerMatchViewProjectionFixture;
  final distinctAckSnapshot = preparedSnapshot.copyWith(
    offset: preparedSnapshot.offset + 1,
  );
  const lifecycleSnapshot = WireSnapshot(
    matchId: 'match-1',
    offset: 0,
    save: {},
    state: {'phase': 'lobby', 'mapName': 'test-map'},
  );
  WireCommandAck ackFor(WireSnapshot snapshot) => WireCommandAck(
    matchId: snapshot.matchId,
    accepted: true,
    offset: snapshot.offset,
    snapshot: snapshot,
    movementExecutions: WireMovementExecutionList(const []),
  );

  final preparationScenarios =
      <
        ({
          String name,
          MultiplayerServerMessage message,
          int expectedDecodes,
          bool? sharedPreparedSnapshot,
        })
      >[
        (
          name: 'lifecycle snapshot',
          message: MultiplayerServerMessage(
            serverMessageId: 'lifecycle',
            matchId: 'match-1',
            offset: 0,
            snapshot: lifecycleSnapshot,
          ),
          expectedDecodes: 0,
          sharedPreparedSnapshot: null,
        ),
        (
          name: 'snapshot only',
          message: MultiplayerServerMessage(
            serverMessageId: 'snapshot-only',
            matchId: preparedSnapshot.matchId,
            offset: preparedSnapshot.offset,
            snapshot: preparedSnapshot,
          ),
          expectedDecodes: 1,
          sharedPreparedSnapshot: null,
        ),
        (
          name: 'ack only',
          message: MultiplayerServerMessage(
            serverMessageId: 'ack-only',
            matchId: preparedSnapshot.matchId,
            offset: preparedSnapshot.offset,
            ack: ackFor(preparedSnapshot),
          ),
          expectedDecodes: 1,
          sharedPreparedSnapshot: null,
        ),
        (
          name: 'shared snapshot and ack',
          message: MultiplayerServerMessage(
            serverMessageId: 'shared',
            matchId: preparedSnapshot.matchId,
            offset: preparedSnapshot.offset,
            snapshot: preparedSnapshot,
            ack: ackFor(preparedSnapshot),
          ),
          expectedDecodes: 1,
          sharedPreparedSnapshot: true,
        ),
        (
          name: 'distinct snapshot and ack',
          message: MultiplayerServerMessage(
            serverMessageId: 'distinct',
            matchId: preparedSnapshot.matchId,
            offset: distinctAckSnapshot.offset,
            snapshot: preparedSnapshot,
            ack: ackFor(distinctAckSnapshot),
          ),
          expectedDecodes: 2,
          sharedPreparedSnapshot: false,
        ),
      ];

  for (final scenario in preparationScenarios) {
    test(
      'prepares ${scenario.name} once before multi-recipient projection',
      () {
        var snapshotDecodes = 0;
        final countingProjector = PlayerMatchViewProjector(
          decodeSnapshot: (snapshot) {
            snapshotDecodes += 1;
            return const LosslessMatchSnapshotDecoder().decode(snapshot);
          },
        );

        final prepared = countingProjector.prepareMessage(scenario.message);
        expect(snapshotDecodes, scenario.expectedDecodes);
        if (scenario.sharedPreparedSnapshot case final expected?) {
          expect(identical(prepared.snapshot, prepared.ackSnapshot), expected);
        }

        for (var index = 0; index < 64; index += 1) {
          countingProjector.projectMessage(
            prepared,
            index.isEven ? owner : guest,
          );
        }
        expect(snapshotDecodes, scenario.expectedDecodes);
      },
    );
  }

  test(
    'malformed running snapshots fail instead of returning canonical data',
    () {
      const malformed = WireSnapshot(
        matchId: 'match-1',
        offset: 1,
        save: {'id': 'incomplete'},
        state: {'secret': 'must-not-pass-through'},
      );

      expect(() => projector.snapshotFor(malformed, owner), throwsA(anything));
    },
  );
}
