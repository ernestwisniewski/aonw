import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/hud/hud_feedback_provider.dart';
import 'package:aonw/game/presentation/services/artifact_guidance_resolver.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final resolver = ArtifactGuidanceResolver(l10n: AppLocalizationsEn());

  test('describes an artifact stored in the active player city', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 3, row: 4),
    );
    const previousArtifact = WorldArtifact(
      id: _artifactId,
      type: WorldArtifactType.heroSword,
      location: WorldArtifactLocation.carried(unitId: 'worker_1'),
    );
    const storedArtifact = WorldArtifact(
      id: _artifactId,
      type: WorldArtifactType.heroSword,
      location: WorldArtifactLocation.stored(cityId: 'city_1'),
    );

    final content = resolver.resolve(
      previousState: const GameState(
        activePlayerId: _playerId,
        cities: [city],
        artifacts: [previousArtifact],
      ),
      state: const GameState(cities: [city], artifacts: [storedArtifact]),
      events: const [],
    );

    expect(content?.kind, HudFeedbackKind.artifactGuidance);
    expect(content?.title, 'Artifact stored');
    expect(content?.body, contains("Hero's Sword"));
    expect(content?.body, contains('Capital'));
  });

  test('describes an artifact newly carried by an active player unit', () {
    final previousUnit = _worker(carriedArtifactId: null);
    final carryingUnit = _worker(carriedArtifactId: _artifactId);
    const artifact = WorldArtifact(
      id: _artifactId,
      type: WorldArtifactType.queensMirror,
      location: WorldArtifactLocation.carried(unitId: _unitId),
    );

    final content = resolver.resolve(
      previousState: GameState(
        activePlayerId: _playerId,
        units: [previousUnit],
      ),
      state: GameState(units: [carryingUnit], artifacts: [artifact]),
      events: const [],
    );

    expect(content?.kind, HudFeedbackKind.artifactGuidance);
    expect(content?.title, 'Artifact carried');
    expect(content?.body, contains("Queen's Mirror"));
  });

  test('describes a map artifact reached by a moved active player unit', () {
    final unit = _worker(col: 5, row: 2);
    const artifact = WorldArtifact(
      id: _artifactId,
      type: WorldArtifactType.astronomersTablets,
      location: WorldArtifactLocation.map(col: 5, row: 2),
    );

    final content = resolver.resolve(
      previousState: const GameState(activePlayerId: _playerId),
      state: GameState(units: [unit], artifacts: [artifact]),
      events: const [
        UnitMovedEvent(
          unitId: _unitId,
          fromCol: 4,
          fromRow: 2,
          toCol: 5,
          toRow: 2,
        ),
      ],
    );

    expect(content?.kind, HudFeedbackKind.artifactGuidance);
    expect(content?.title, 'Artifact discovered');
    expect(content?.body, contains("Astronomers' Tablets"));
  });

  test(
    'returns no guidance when the active player did not change artifacts',
    () {
      const artifact = WorldArtifact(
        id: _artifactId,
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.map(col: 5, row: 2),
      );

      final content = resolver.resolve(
        previousState: const GameState(
          activePlayerId: _playerId,
          artifacts: [artifact],
        ),
        state: const GameState(artifacts: [artifact]),
        events: const [],
      );

      expect(content, isNull);
    },
  );
}

const _playerId = 'player_1';
const _unitId = 'worker_1';
const _artifactId = 'artifact.hero_sword';

GameUnit _worker({
  int col = 0,
  int row = 0,
  String? carriedArtifactId,
  String? excavatingArtifactId,
}) {
  return GameUnit(
    id: _unitId,
    ownerPlayerId: _playerId,
    type: GameUnitType.worker,
    name: 'Worker',
    col: col,
    row: row,
    carriedArtifactId: carriedArtifactId,
    excavatingArtifactId: excavatingArtifactId,
  );
}
