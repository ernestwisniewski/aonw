import 'dart:async';

import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/civilization_met_popup_overlay.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomatic_message_popup_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/notifications/game_event_notifications_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/outcome/hud_game_outcome_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/outcome/hud_game_outcome_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/game_hud_overlay_host.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/game_hud_overlay_panels_host.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/hud_feedback_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/turn_start_banner_overlay.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/game_player_avatars_overlay.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/hot_seat_handoff_overlay.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail.dart';
import 'package:aonw/game/presentation/widgets/options/game_options_overlay.dart';
import 'package:aonw/game/presentation/widgets/screen/game_player_control_sync.dart';
import 'package:aonw/game/presentation/widgets/selection_info/providers.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_discovery_popup_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'game_hud_chrome.dart';

class GameHud extends ConsumerStatefulWidget {
  final GameSession session;
  final ValueListenable<Set<String>> animatingUnitIdsListenable;
  final ValueListenable<bool> initialCameraFocusReadyListenable;
  final bool allowGraphicMode;
  final ValueChanged<MapViewMode> onViewModeChanged;
  final FutureOr<void> Function() onClose;
  final GameSave? gameSave;
  final HexDisplaySettings displaySettings;
  final VoidCallback onToggleTerrain;
  final VoidCallback onToggleResources;
  final VoidCallback onToggleHeightBadge;
  final VoidCallback onToggleCitySites;
  final VoidCallback onToggleCityGrowth;
  final VoidCallback onToggleHexBorders;
  final VoidCallback onToggleHeightWalls;
  final ValueChanged<Color>? onHexBorderColorChanged;
  final ValueChanged<Color>? onWallTintColorChanged;
  final VoidCallback? onResetHexBorderColor;
  final VoidCallback? onResetWallTintColor;
  final bool showDiceRollTest;
  final VoidCallback? onToggleDiceRollTest;
  final bool showEntryHandoff;
  final bool aiAutopilotEnabled;

  const GameHud({
    required this.session,
    required this.animatingUnitIdsListenable,
    this.initialCameraFocusReadyListenable = const AlwaysStoppedAnimation<bool>(
      true,
    ),
    required this.allowGraphicMode,
    required this.onViewModeChanged,
    required this.onClose,
    required this.displaySettings,
    required this.onToggleTerrain,
    required this.onToggleResources,
    required this.onToggleHeightBadge,
    required this.onToggleCitySites,
    required this.onToggleCityGrowth,
    required this.onToggleHexBorders,
    required this.onToggleHeightWalls,
    this.onHexBorderColorChanged,
    this.onWallTintColorChanged,
    this.onResetHexBorderColor,
    this.onResetWallTintColor,
    this.showDiceRollTest = false,
    this.onToggleDiceRollTest,
    this.showEntryHandoff = true,
    this.aiAutopilotEnabled = false,
    this.gameSave,
    super.key,
  });

  @override
  ConsumerState<GameHud> createState() => _GameHudState();
}

class _GameHudState extends ConsumerState<GameHud> {
  final Set<String> _confirmedEntryHandoffs = {};
  bool _handoffTransitionInProgress = false;
  bool _resigning = false;
  bool _optionsOverlayPanelActive = false;

  Future<void> _onClose(BuildContext context) async {
    await ref.read(gameCommandControllerProvider.notifier).saveCamera();
    if (!context.mounted) return;
    await widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gameSave = widget.gameSave;
    final gameState = gameSave == null
        ? null
        : ref.watch(gameStateProvider(widget.session.saveId)).value;
    final playerControl = gameSave == null
        ? null
        : PlayerControlCoordinator.normalize(
            current: ref.watch(gamePlayerControlControllerProvider),
            save: gameSave,
          );
    final outcomeSummary = gameSave == null
        ? null
        : HudGameOutcomeSummary.from(
            l10n: l10n,
            gameSave: gameSave,
            gameState: gameState,
            mapData: widget.session.mapData,
            activePlayerId: _outcomePerspectivePlayerId(
              gameSave: gameSave,
              gameStateActivePlayerId: gameState?.activePlayerId,
              playerControl: playerControl,
            ),
          );
    final networkSession = ref.watch(networkSessionProvider);
    final pendingHandoff = ref.watch(gameHandoffProvider);
    final entryHandoff = pendingHandoff == null && outcomeSummary == null
        ? _entryHandoffFor(gameSave)
        : null;
    final handoff = outcomeSummary == null
        ? pendingHandoff ?? entryHandoff
        : null;
    final handoffBlocksHud = handoff != null || _handoffTransitionInProgress;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!handoffBlocksHud) GamePlayerControlSync(gameSave: gameSave),
        if (widget.aiAutopilotEnabled && outcomeSummary == null)
          GameAiTurnAutoPilot(
            key: const ValueKey('game-ai-turn-auto-pilot'),
            gameSave: gameSave,
          ),
        const _HudTopFade(),
        if (gameSave != null) MultiplayerAvatarsRailOverlay(gameSave: gameSave),
        GameOptionsOverlay(
          session: widget.session,
          gameSave: gameSave,
          allowGraphicMode: widget.allowGraphicMode,
          onViewModeChanged: widget.onViewModeChanged,
          displaySettings: widget.displaySettings,
          onToggleTerrain: widget.onToggleTerrain,
          onToggleResources: widget.onToggleResources,
          onToggleHeightBadge: widget.onToggleHeightBadge,
          onToggleCitySites: widget.onToggleCitySites,
          onToggleCityGrowth: widget.onToggleCityGrowth,
          onToggleHexBorders: widget.onToggleHexBorders,
          onToggleHeightWalls: widget.onToggleHeightWalls,
          onHexBorderColorChanged: widget.onHexBorderColorChanged,
          onWallTintColorChanged: widget.onWallTintColorChanged,
          onResetHexBorderColor: widget.onResetHexBorderColor,
          onResetWallTintColor: widget.onResetWallTintColor,
          showDiceRollTest: widget.showDiceRollTest,
          onToggleDiceRollTest: widget.onToggleDiceRollTest,
          onResignMatch: _canResign(gameSave, networkSession)
              ? () => unawaited(_onResignMatch(context))
              : null,
          resigning: _resigning,
          closedContent:
              gameSave != null &&
                  gameSave.gameMode != GameMode.multiplayer &&
                  gameSave.players.isNotEmpty
              ? GamePlayerAvatarsOverlay(
                  gameSave: gameSave,
                  diplomacy: gameState?.diplomacy ?? DiplomacyState.empty,
                )
              : null,
          onOverlayPanelActiveChanged: _setOptionsOverlayPanelActive,
        ),
        if (gameSave != null && !handoffBlocksHud)
          GameHudOverlayHost(
            session: widget.session,
            animatingUnitIdsListenable: widget.animatingUnitIdsListenable,
            initialCameraFocusReadyListenable:
                widget.initialCameraFocusReadyListenable,
            gameSave: gameSave,
            optionsOverlayOpenOverride: _optionsOverlayPanelActive,
          ),
        if (gameSave != null && !handoffBlocksHud)
          GameHudOverlayPanelsHost(session: widget.session, gameSave: gameSave),
        _HudMenuButton(onPressed: () => unawaited(_onClose(context))),
        GameEventNotificationsOverlay(gameSave: gameSave),
        const HudFeedbackOverlay(),
        if (gameSave != null) TurnStartBannerOverlay(turnNumber: gameSave.turn),
        CivilizationMetPopupOverlay(gameSave: gameSave),
        DiplomaticMessagePopupOverlay(gameSave: gameSave),
        TechnologyDiscoveryPopupOverlay(gameSave: gameSave),
        if (handoff != null)
          Positioned.fill(
            child: HotSeatHandoffOverlay(
              handoff: handoff,
              onConfirm: () => unawaited(
                _onHandoffConfirmed(
                  handoff,
                  clearPending: pendingHandoff != null,
                  entrySaveId: entryHandoff != null ? gameSave?.id : null,
                ),
              ),
            ),
          ),
        if (outcomeSummary != null)
          Positioned.fill(
            child: HudGameOutcomeOverlay(
              summary: outcomeSummary,
              onReturnToMenu: () => _onClose(context),
            ),
          ),
      ],
    );
  }

  bool _canResign(GameSave? save, NetworkSession? networkSession) {
    return save?.gameMode == GameMode.multiplayer &&
        networkSession != null &&
        networkSession.isConnected &&
        networkSession.matchId == widget.session.saveId;
  }

  Future<void> _onResignMatch(BuildContext context) async {
    if (_resigning) return;
    final l10n = AppLocalizations.of(context);
    final session = ref.read(networkSessionProvider);
    final matchId = session?.matchId;
    if (session == null || matchId == null) return;

    final confirmed = await showGameConfirmation(
      context: context,
      title: l10n.resignMatchTitle,
      message: l10n.resignMatchMessage,
      confirmLabel: l10n.resignAction,
      cancelLabel: l10n.selectionActionCancel,
      tone: GameConfirmationTone.danger,
    );
    if (!confirmed || !mounted || !context.mounted) return;

    setState(() => _resigning = true);
    try {
      await NetworkSessionClient(
        serverpodHost: ref.read(apiConfigProvider).baseUrl.toString(),
      ).resignMatch(token: session.token, matchId: matchId);
      await const NetworkSessionStore().saveMatchId(null);
      ref
          .read(networkSessionStateProvider.notifier)
          .set(
            NetworkSession(
              userId: session.userId,
              token: session.token,
              connectionState: session.connectionState.copyWith(
                changedAt: ref.read(gameClockProvider).nowUtc(),
              ),
            ),
          );
      if (!mounted) return;
      widget.onClose();
    } catch (_) {
      if (!mounted || !context.mounted) return;
      GameToast.show(
        context,
        message: l10n.resignMatchError,
        tone: GameToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _resigning = false);
    }
  }

  void _setOptionsOverlayPanelActive(bool active) {
    if (!mounted || _optionsOverlayPanelActive == active) return;
    setState(() => _optionsOverlayPanelActive = active);
  }

  HandoffData? _entryHandoffFor(GameSave? save) {
    if (!widget.showEntryHandoff) return null;
    if (save == null || save.gameMode != GameMode.hotSeat) return null;
    if (_confirmedEntryHandoffs.contains(save.id)) return null;

    final control = PlayerControlCoordinator.initial(save);
    if (control.activePlayerId.isEmpty) return null;
    final player = save.players
        .where((p) => p.id == control.activePlayerId)
        .firstOrNull;
    if (player == null) return null;
    if (player.isAi) return null;

    return HandoffData(
      playerId: player.id,
      playerName: GameDisplayNames.player(AppLocalizations.of(context), player),
      playerColorValue: player.colorValue,
      turnNumber: save.turn,
    );
  }

  String _handoffPreparationKey(
    HandoffData handoff, {
    required bool clearPending,
    required String? entrySaveId,
  }) {
    final saveId = entrySaveId ?? widget.gameSave?.id ?? widget.session.saveId;
    return [
      saveId,
      handoff.playerId,
      handoff.turnNumber,
      handoff.freshTurn,
      clearPending,
    ].join('|');
  }

  Future<void> _prepareHandoffControlAndCamera(
    HandoffData handoff, {
    required bool resetMovement,
  }) async {
    final control = ref.read(gamePlayerControlControllerProvider);
    final gameState = ref.read(gameStateProvider(widget.session.saveId)).value;
    final alreadyConfirmed =
        control.activePlayerId == handoff.playerId &&
        control.canAct &&
        gameState?.activePlayerId == handoff.playerId &&
        (gameState?.activePlayerCanAct ?? false);

    if (!alreadyConfirmed) {
      await ref
          .read(gamePlayerControlControllerProvider.notifier)
          .confirmHandoff(handoff.playerId, resetMovement: resetMovement);
      if (!mounted) return;
    } else if (handoff.freshTurn) {
      await ref
          .read(gameCommandControllerProvider.notifier)
          .dispatch(ResetUnitMovementCommand(playerId: handoff.playerId));
      if (!mounted) return;
    }

    await ref
        .read(hudCommandDispatcherProvider)
        .focusTurnStartMapTarget(
          activePlayerId: handoff.playerId,
          moveCamera: true,
        );
  }

  Future<void> _onHandoffConfirmed(
    HandoffData handoff, {
    required bool clearPending,
    required String? entrySaveId,
  }) async {
    if (_handoffTransitionInProgress) return;
    ref.read(openSelectionDetailControllerProvider.notifier).close();
    final preparationKey = _handoffPreparationKey(
      handoff,
      clearPending: clearPending,
      entrySaveId: entrySaveId,
    );
    final suppressEntrySaveId =
        entrySaveId ?? (clearPending ? widget.gameSave?.id : null);
    setState(() {
      _handoffTransitionInProgress = true;
    });

    try {
      await _prepareHandoffControlAndCamera(
        handoff,
        resetMovement: clearPending,
      );
      if (!mounted) return;
      if (_handoffPreparationKey(
            handoff,
            clearPending: clearPending,
            entrySaveId: entrySaveId,
          ) !=
          preparationKey) {
        return;
      }
      if (clearPending) {
        ref.read(gameHandoffProvider.notifier).clear();
      }
      if (suppressEntrySaveId != null) {
        _confirmedEntryHandoffs.add(suppressEntrySaveId);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        ref
            .read(gameLoggerProvider)
            .warn('GameHud', 'handoff confirmation failed', error, stackTrace);
      }
    } finally {
      if (mounted) {
        setState(() => _handoffTransitionInProgress = false);
      }
    }
  }
}
