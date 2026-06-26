import 'dart:async';

import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/application/use_cases/autosave_camera_use_case.dart';
import 'package:aonw/game/application/use_cases/detach_troop_use_case.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue_mapper.dart';
import 'package:aonw/game/presentation/engine/game_camera_effect_normalizer.dart';
import 'package:aonw/game/presentation/engine/game_renderer_effect_sequence_builder.dart';
import 'package:aonw/game/presentation/providers/audio/game_audio_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_feedback_provider.dart';
import 'package:aonw/game/presentation/providers/renderer/renderer_provider.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw/game/presentation/services/artifact_guidance_resolver.dart';
import 'package:aonw/game/presentation/services/game_map_focus_target_resolver.dart';
import 'package:aonw/game/presentation/services/turn_start_focus_coordinator.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/providers/language_settings_provider.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_actions_provider.g.dart';

/// Coordinates player commands with the active save and renderer view model.
@Riverpod(
  dependencies: [activeGameSession, activeRendererViewModel, GameStateNotifier],
)
class GameCommandController extends _$GameCommandController {
  Future<void> _commandQueue = Future<void>.value();
  final Set<String> _shownTurnStartProductionBubbleKeys = {};

  @override
  void build() {
    ref.onDispose(() {
      _shownTurnStartProductionBubbleKeys.clear();
    });
  }

  /// Returns all effects so callers can react to non-renderer work too.
  Future<List<UiEffect>> dispatch(GameCommand command) =>
      dispatchTransition(command).then((result) => result.uiEffects);

  Future<DispatchCommandResult> dispatchTransition(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _enqueueCommand(() => _dispatchAndHandle(command, context: context));
  }

  Future<HandoffPresentation> dispatchForHandoffPresentation(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _enqueueCommand(() async {
      final record = await _dispatchOnly(command, context: context);
      return HandoffPresentation(
        command: command,
        state: record.result.state,
        previousState: record.previousState,
        uiEffects: record.result.uiEffects,
        events: record.result.events,
      );
    });
  }

  Future<void> presentHandoffPresentation(HandoffPresentation presentation) {
    return _enqueueCommand(
      () => _presentDispatchRecord(
        _CommandDispatchRecord(
          command: presentation.command,
          previousState: presentation.previousState,
          result: DispatchCommandResult(
            state: presentation.state,
            uiEffects: presentation.uiEffects,
            events: presentation.events,
          ),
        ),
      ),
    );
  }

  void addHandoffNotifications(HandoffPresentation presentation) {
    if (!ref.mounted) return;
    if (!presentation.hasNotifications) return;
    ref
        .read(gameEventNotificationsProvider.notifier)
        .addAll(
          presentation.events,
          presentation.state,
          previousState: presentation.previousState,
          turn: _currentSaveTurn(),
        );
  }

  Future<void> detachTroop(TroopType troopType) async {
    if (!ref.mounted) return;
    await const DetachTroopUseCase().execute(
      state: _currentGameState(),
      troopType: troopType,
      dispatch: dispatch,
    );
  }

  Future<void> jumpToPlayerStart(String playerId) async {
    if (!ref.mounted) return;
    final target = GameMapFocusTargetResolver(
      _currentGameState(),
    ).playerStartTarget(playerId);
    if (target == null) return;
    await _handleRendererEffect(
      JumpCameraEffect(col: target.col, row: target.row),
    );
  }

  Future<void> focusUnitMapTarget(String unitId) {
    return _enqueueCommand(() async {
      if (!ref.mounted) return;
      final target = GameMapFocusTargetResolver(
        _currentGameState(),
      ).unitTarget(unitId);
      if (target == null) return;
      await _handleRendererEffect(
        SmoothCameraEffect(col: target.col, row: target.row),
      );
    });
  }

  Future<void> focusCityMapTarget(String cityId) {
    return _enqueueCommand(() async {
      if (!ref.mounted) return;
      final target = GameMapFocusTargetResolver(
        _currentGameState(),
      ).cityTarget(cityId);
      if (target == null) return;
      await _handleRendererEffect(
        SmoothCameraEffect(col: target.col, row: target.row),
      );
    });
  }

  Future<bool> focusTurnStartMapTarget(
    String playerId, {
    bool moveCamera = true,
  }) async {
    return _enqueueCommand(
      () => _focusTurnStartMapTarget(playerId, moveCamera: moveCamera),
    );
  }

  Future<T> _enqueueCommand<T>(Future<T> Function() operation) {
    final keepAlive = ref.keepAlive();
    final next = _commandQueue.then((_) async {
      try {
        return await operation();
      } finally {
        keepAlive.close();
      }
    });
    _commandQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<bool> _focusTurnStartMapTarget(
    String playerId, {
    required bool moveCamera,
  }) async {
    return TurnStartFocusCoordinator(
      isMounted: () => ref.mounted,
      readState: _currentGameState,
      dispatchWithPresentation: _dispatchAndHandle,
      dispatchWithoutRendererEffects: _dispatchWithoutRendererEffects,
      handleRendererEffect: _handleRendererEffect,
    ).focus(playerId: playerId, moveCamera: moveCamera);
  }

  Future<void> _handleRendererEffect(RendererEffect effect) async {
    if (!ref.mounted) return;
    await ref.read(activeRendererViewModelProvider)?.handleEffect(effect);
  }

  Future<void> saveCamera() async {
    if (!ref.mounted) return;
    final session = ref.read(activeGameSessionProvider);
    final renderer = ref.read(activeRendererViewModelProvider);
    if (session == null || renderer == null || session.saveId.isEmpty) return;
    final networkSession = ref.read(networkSessionProvider);
    if (networkSession?.matchId == session.saveId) return;
    final camera = renderer.cameraState;

    final logger = ref.read(gameLoggerProvider);
    try {
      final saved = await AutosaveCameraUseCase(
        repository: ref.read(gameRepositoryProvider),
      ).execute(saveId: session.saveId, camera: camera);
      if (!ref.mounted) return;
      if (saved) _invalidateSave(session.saveId);
    } catch (error, stackTrace) {
      logger.warn(
        'GameCommandController',
        'camera autosave failed',
        error,
        stackTrace,
      );
    }
  }

  void _invalidateSave(String saveId) {
    if (!ref.mounted) return;
    ref.invalidate(gameSaveSnapshotProvider(saveId));
  }

  GameState? _currentGameState() {
    if (!ref.mounted) return null;
    final session = ref.read(activeGameSessionProvider);
    if (session == null || session.saveId.isEmpty) return null;
    return ref.read(gameStateProvider(session.saveId)).value;
  }

  int? _currentSaveTurn() {
    if (!ref.mounted) return null;
    final session = ref.read(activeGameSessionProvider);
    if (session == null || session.saveId.isEmpty) return null;
    return ref.read(gameSaveProvider(session.saveId)).value?.turn;
  }

  int? _turnFor(DispatchCommandResult result) =>
      result.snapshot?.save.turn ?? _currentSaveTurn();

  Future<DispatchCommandResult> _dispatchAndHandle(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (!ref.mounted) return const DispatchCommandResult(state: GameState());
    final record = await _dispatchOnly(command, context: context);
    if (!ref.mounted) return record.result;
    await _presentDispatchRecord(record);
    return record.result;
  }

  Future<_CommandDispatchRecord> _dispatchOnly(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (!ref.mounted) {
      return _CommandDispatchRecord(
        command: command,
        previousState: null,
        result: const DispatchCommandResult(state: GameState()),
      );
    }
    final session = ref.read(activeGameSessionProvider);
    if (session == null || session.saveId.isEmpty) {
      return _CommandDispatchRecord(
        command: command,
        previousState: null,
        result: const DispatchCommandResult(state: GameState()),
      );
    }

    final previousState = _currentGameState();
    final notifier = ref.read(gameStateProvider(session.saveId).notifier);
    late final DispatchCommandResult result;
    try {
      result = await notifier.dispatchTransition(command, context: context);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        ref
            .read(gameLoggerProvider)
            .warn(
              'GameCommandController',
              'command dispatch failed',
              error,
              stackTrace,
            );
        _invalidateSave(session.saveId);
      }
      return _CommandDispatchRecord(
        command: command,
        previousState: previousState,
        result: DispatchCommandResult(
          state: previousState ?? const GameState(),
        ),
      );
    }
    return _CommandDispatchRecord(
      command: command,
      previousState: previousState,
      result: result,
    );
  }

  Future<void> _presentDispatchRecord(_CommandDispatchRecord record) async {
    if (!ref.mounted) return;
    final command = record.command;
    final previousState = record.previousState;
    final result = record.result;
    final session = ref.read(activeGameSessionProvider);
    if (session == null || session.saveId.isEmpty) return;
    final renderer = ref.read(activeRendererViewModelProvider);
    if (renderer != null) {
      final commandRendererEffects = GameCameraEffectNormalizer.forCommand(
        command: command,
        effects: result.uiEffects.rendererEffects,
      );
      final visibleCommandRendererEffects =
          await _dedupeTurnStartProductionBubbles(
            command: command,
            saveId: session.saveId,
            effects: commandRendererEffects,
          );
      final rendererEffects = GameRendererEffectSequenceBuilder.build(
        commandEffects: visibleCommandRendererEffects,
        events: result.events,
        state: result.state,
        previousState: previousState,
        l10n: renderer.l10n,
      );
      _playCommandAndTransitionSounds(
        command: command,
        previousState: previousState,
        result: result,
        rendererEffects: rendererEffects,
      );
      await renderer.applyTransition(result.state, rendererEffects);
    } else {
      _playCommandAndTransitionSounds(
        command: command,
        previousState: previousState,
        result: result,
        rendererEffects: const [],
      );
    }
    ref
        .read(gameEventNotificationsProvider.notifier)
        .addAll(
          result.events,
          result.state,
          previousState: previousState,
          turn: _turnFor(result),
        );
    _showHudFeedbackEffects(result.uiEffects);
    _showArtifactGuidance(record);
  }

  Future<DispatchCommandResult> _dispatchWithoutRendererEffects(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (!ref.mounted) return const DispatchCommandResult(state: GameState());
    final record = await _dispatchOnly(command, context: context);
    if (!ref.mounted) return record.result;

    ref
        .read(activeRendererViewModelProvider)
        ?.applyStateWithoutCameraFocus(record.result.state);
    _playCommandAndTransitionSounds(
      command: command,
      previousState: record.previousState,
      result: record.result,
      rendererEffects: const [],
    );
    ref
        .read(gameEventNotificationsProvider.notifier)
        .addAll(
          record.result.events,
          record.result.state,
          previousState: record.previousState,
          turn: _turnFor(record.result),
        );
    _showHudFeedbackEffects(record.result.uiEffects);
    return record.result;
  }

  void _playCommandAndTransitionSounds({
    required GameCommand command,
    required GameState? previousState,
    required DispatchCommandResult result,
    required Iterable<RendererEffect> rendererEffects,
  }) {
    if (!ref.mounted) return;
    final cues = [
      ...GameSoundCueMapper.forCommand(
        command: command,
        previousState: previousState,
        state: result.state,
        events: result.events,
        uiEffects: result.uiEffects,
      ),
      ...GameSoundCueMapper.forRendererEffects(
        effects: rendererEffects,
        state: result.state,
        previousState: previousState,
      ),
      ...GameSoundCueMapper.forEvents(
        events: result.events,
        state: result.state,
        previousState: previousState,
      ),
    ];
    if (cues.isEmpty) return;
    ref.read(gameAudioControllerProvider).playAll(cues);
  }

  Future<List<RendererEffect>> _dedupeTurnStartProductionBubbles({
    required GameCommand command,
    required String saveId,
    required Iterable<RendererEffect> effects,
  }) async {
    final pending = effects.toList(growable: false);
    if (pending.whereType<ShowCityProductionBubbleEffect>().isEmpty ||
        command is! FocusTurnStartActionCommand) {
      return pending;
    }

    final key = await _turnStartProductionBubbleKey(
      saveId: saveId,
      playerId: command.playerId,
    );
    if (key == null || _shownTurnStartProductionBubbleKeys.add(key)) {
      return pending;
    }

    return [
      for (final effect in pending)
        if (effect is! ShowCityProductionBubbleEffect) effect,
    ];
  }

  Future<String?> _turnStartProductionBubbleKey({
    required String saveId,
    required String playerId,
  }) async {
    if (!ref.mounted) return null;
    if (saveId.isEmpty || playerId.isEmpty) return null;
    try {
      final snapshot = await ref.read(gameRepositoryProvider).load(saveId);
      return '$saveId|${snapshot.save.turn}|$playerId';
    } catch (_) {
      return null;
    }
  }

  void _showArtifactGuidance(_CommandDispatchRecord record) {
    if (!ref.mounted) return;
    final previousState = record.previousState;
    if (previousState == null) return;
    final l10n = lookupAppLocalizations(
      ref.read(languageSettingsProvider).locale,
    );
    final content = ArtifactGuidanceResolver(l10n: l10n).resolve(
      previousState: previousState,
      state: record.result.state,
      events: record.result.events,
    );
    if (content == null) return;
    ref.read(hudFeedbackProvider.notifier).show(content);
  }

  void _showHudFeedbackEffects(Iterable<UiEffect> effects) {
    if (!ref.mounted) return;
    for (final effect in effects.whereType<ShowHudFeedbackEffect>()) {
      ref
          .read(hudFeedbackProvider.notifier)
          .show(
            HudFeedbackContent(
              kind: HudFeedbackKind.actionBlocked,
              reason: effect.reason,
              title: effect.title,
              body: effect.body,
            ),
          );
      return;
    }
  }
}

class _CommandDispatchRecord {
  final GameCommand command;
  final GameState? previousState;
  final DispatchCommandResult result;

  const _CommandDispatchRecord({
    required this.command,
    required this.previousState,
    required this.result,
  });
}
