import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/game/presentation/engine/renderer_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

import 'presentation_parity_snapshots.dart';

final class MultiClientAnimationHarness {
  final Map<String, _HarnessClient> _clients = {};

  void attachClient(
    String clientId, {
    required String sourceId,
    required int nextEventOffset,
  }) {
    _clients[clientId] = _HarnessClient(
      sourceId: sourceId,
      nextEventOffset: nextEventOffset,
    );
  }

  Future<void> deliver(
    String clientId,
    ProjectedGameEffectBatch batch, {
    required int arrivalMicrosUtc,
    GameClientState? state,
  }) async {
    final client = _client(clientId);
    client.clock.advanceTo(arrivalMicrosUtc);
    final accepted = client.cursor.consumeProjectedBatch(batch);
    await client.renderer.applyProjectedTransition(
      state ?? GameClientState(),
      batch,
    );
    for (final animation in accepted) {
      client.record(animation);
    }
    client.verifyRendererParity();
  }

  List<Map<String, Object?>> trace(String clientId) =>
      List.unmodifiable(_client(clientId).trace);

  List<Map<String, Object?>> traceForOffset(String clientId, int offset) =>
      trace(clientId)
          .where((entry) => entry['eventOffset'] == offset)
          .toList(growable: false);

  void verifyExactlyOnceAndNoOverlap(String clientId) {
    final trace = this.trace(clientId);
    final ids = trace.map((entry) => entry['animationId']).toList();
    if (ids.toSet().length != ids.length) {
      throw StateError('$clientId contains duplicate animation IDs.');
    }
    for (var index = 1; index < trace.length; index += 1) {
      final previousEnd = trace[index - 1]['completedMicrosUtc']! as int;
      final currentStart = trace[index]['startedMicrosUtc']! as int;
      if (currentStart < previousEnd) {
        throw StateError(
          '$clientId overlaps ${trace[index - 1]['animationId']} and '
          '${trace[index]['animationId']}.',
        );
      }
    }
  }

  _HarnessClient _client(String clientId) {
    final client = _clients[clientId];
    if (client == null) throw StateError('Unknown harness client $clientId.');
    return client;
  }
}

final class _HarnessClient {
  _HarnessClient({required String sourceId, required int nextEventOffset}) {
    cursor.activateSource(sourceId, nextEventOffset: nextEventOffset);
    renderer.activateProjectedEffectSource(
      sourceId,
      nextEventOffset: nextEventOffset,
    );
  }

  final ProjectedGameEffectCursor cursor = ProjectedGameEffectCursor();
  final _RecordingRenderer renderer = _RecordingRenderer();
  final _VirtualClock clock = _VirtualClock();
  final List<Map<String, Object?>> trace = [];

  void record(ProjectedGameEffect animation) {
    final scheduledStart = animation.logicalStartMicrosUtc;
    final lateness = clock.nowMicrosUtc - scheduledStart;
    if (lateness > presentationFrameBudget.inMicroseconds) {
      throw StateError(
        '${animation.animationId} arrived $lateness µs after its start.',
      );
    }
    final started = clock.nowMicrosUtc > scheduledStart
        ? clock.nowMicrosUtc
        : scheduledStart;
    final completed = started + animation.duration.inMicroseconds;
    trace.add({
      ...projectedAnimationTraceSnapshot(animation),
      'startedMicrosUtc': started,
      'completedMicrosUtc': completed,
      'completed': true,
    });
    clock.advanceTo(completed);
  }

  void verifyRendererParity() {
    final tracedEffects = trace
        .map((entry) => entry['effect'])
        .toList(growable: false);
    final renderedEffects = renderer.applied
        .map(rendererEffectSnapshot)
        .toList(growable: false);
    if ('$tracedEffects' != '$renderedEffects') {
      throw StateError('Renderer transition bypassed the projected trace.');
    }
  }
}

final class _VirtualClock {
  int nowMicrosUtc = 0;

  void advanceTo(int value) {
    if (value > nowMicrosUtc) nowMicrosUtc = value;
  }
}

final class _RecordingRenderer implements RendererViewModel {
  final List<RendererEffect> applied = [];

  @override
  CameraState get cameraState => const CameraState(x: 0, y: 0, zoom: 1);

  @override
  AppLocalizations? get l10n => null;

  @override
  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) async {
    applied.addAll(effects);
  }

  @override
  void applyStateWithoutCameraFocus(
    GameClientState state, {
    int? currentTurn,
  }) {}

  @override
  Future<void> handleEffect(RendererEffect effect) async {
    applied.add(effect);
  }
}
