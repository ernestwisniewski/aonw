import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveSnapshot canonical boundary', () {
    test('memoizes a complete canonical view without changing raw state', () {
      final snapshot = _snapshot();

      expect(snapshot.rawPersistentState.runtimeState.turnStartedAt, isNull);

      final canonical = snapshot.canonical;

      expect(identical(snapshot.canonical, canonical), isTrue);
      expect(canonical.domain.participants, [
        _aiPlayer.copyWith(colorValue: _aiCanonicalColor),
        _humanPlayer.copyWith(country: PlayerCountry.canada),
      ]);
      expect(canonical.domain.participants.first.kind, PlayerKind.ai);
      expect(canonical.domain.participants.first.ai, _aiMetadata);
      expect(canonical.domain.participants.last.kind, PlayerKind.human);
      expect(canonical.domain.participants.last.ai, isNull);
      expect(canonical.domain.playerColors, {
        _aiPlayerId: _aiCanonicalColor,
        _humanPlayerId: _humanPlayer.colorValue,
      });
      expect(canonical.domain.playerCountries, {
        _aiPlayerId: _aiPlayer.country,
        _humanPlayerId: PlayerCountry.canada,
      });
      expect(canonical.session.turnStatesByPlayerId, _savePlayerStates);
      expect(canonical.session.submittedPlayerIds, {_aiPlayerId});
      expect(
        canonical.session.turnStatesByPlayerId[_humanPlayerId],
        PlayerTurnState.finished,
      );
      expect(canonical.session.hasSubmitted(_humanPlayerId), isFalse);
      expect(
        canonical.session.turnStatesByPlayerId[_aiPlayerId],
        PlayerTurnState.active,
      );
      expect(canonical.session.hasSubmitted(_aiPlayerId), isTrue);
      expect(canonical.interaction.cityFoundingDraft, _cityFoundingDraft);
      expect(canonical.interaction.pendingAction, _pendingAction);
      expect(canonical.eventLogOffset, _eventLogOffset);
      expect(canonical.session.turnStartedAt, _savedAt);
      expect(snapshot.rawPersistentState.runtimeState.turnStartedAt, isNull);
    });

    test('fromCanonical losslessly rebuilds and memoizes semantics', () {
      final seededCanonical = _snapshot().canonical;

      final snapshot = SaveSnapshot.fromCanonical(seededCanonical);

      expect(snapshot.canonical, seededCanonical);
      expect(identical(snapshot.canonical, snapshot.canonical), isTrue);
      expect(snapshot.save.players, seededCanonical.domain.participants);
      expect(
        snapshot.save.playerStates,
        seededCanonical.session.turnStatesByPlayerId,
      );
      expect(snapshot.runtimeState.submittedPlayerIds, {_aiPlayerId});
      expect(snapshot.runtimeState.cityFoundingDraft, _cityFoundingDraft);
      expect(snapshot.runtimeState.pendingAction, _pendingAction);
      expect(snapshot.eventLogOffset, _eventLogOffset);

      final rebuilt = SaveSnapshot.fromPersistentState(
        save: snapshot.save,
        state: snapshot.rawPersistentState,
        eventLogOffset: snapshot.eventLogOffset,
      );

      expect(rebuilt.canonical, seededCanonical);
      expect(snapshot.copyWith().canonical, seededCanonical);
    });

    test(
      'fromCanonical rejects snapshots that legacy state cannot preserve',
      () {
        final canonical = _snapshot().canonical;
        final nonLossless = canonical.copyWith(
          session: canonical.session.copyWith(turnStartedAt: null),
        );

        expect(
          () => SaveSnapshot.fromCanonical(nonLossless),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('cannot be represented losslessly'),
            ),
          ),
        );
      },
    );
  });
}

SaveSnapshot _snapshot() {
  return SaveSnapshot(
    save: GameSave(
      id: 'save_1',
      name: 'Canonical boundary fixture',
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      turn: 7,
      playerStates: _savePlayerStates,
      savedAt: _savedAt,
      camera: const CameraState(x: 1.5, y: -2, zoom: 0.75),
      players: const [_aiPlayer, _humanPlayer],
      gameMode: GameMode.multiplayer,
    ),
    playerColors: const {_aiPlayerId: _aiCanonicalColor},
    playerCountries: const {_humanPlayerId: PlayerCountry.canada},
    playerGold: const {_aiPlayerId: 11, _humanPlayerId: 17},
    runtimeState: GameRuntimeState.snapshot(
      cityFoundingDraft: _cityFoundingDraft,
      pendingAction: _pendingAction,
      submittedPlayerIds: const {_aiPlayerId},
    ),
    eventLogOffset: _eventLogOffset,
  );
}

const _aiPlayerId = 'ai';
const _humanPlayerId = 'human';
const _aiCanonicalColor = 0xFF0A0B0C;
const _eventLogOffset = 41;
final _savedAt = DateTime.utc(2026, 7, 28, 12, 30);
const _savePlayerStates = {
  _humanPlayerId: PlayerTurnState.finished,
  _aiPlayerId: PlayerTurnState.active,
};
const _aiMetadata = AiPlayer(strategyId: AiStrategyId.random, seed: 73);
const _aiPlayer = Player(
  id: _aiPlayerId,
  name: 'Strategist',
  colorValue: 0xFF111111,
  country: PlayerCountry.japan,
  kind: PlayerKind.ai,
  ai: _aiMetadata,
);
const _humanPlayer = Player(
  id: _humanPlayerId,
  name: 'Ada',
  colorValue: 0xFF222222,
  country: PlayerCountry.france,
);
final _cityFoundingDraft = CityFoundingDraft(
  unitId: 'settler_1',
  ownerPlayerId: _humanPlayerId,
  center: const CityHex(col: 2, row: 3),
  controlledHexes: const [CityHex(col: 3, row: 3)],
);
const _pendingAction = PendingResearchSelection(ownerPlayerId: _aiPlayerId);
