import 'dart:async';

import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/civilization_met_popup_overlay.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomatic_message_popup_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_input_layer.dart';
import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_ring.dart';
import 'package:aonw/game/presentation/widgets/hud/notifications/game_event_notifications_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/outcome/hud_game_outcome_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/outcome/hud_game_outcome_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/game_hud_overlay_host.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/game_hud_overlay_panels_host.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/hud_feedback_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/turn_start_banner_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdown_controller.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/game_player_avatars_overlay.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/hot_seat_handoff_overlay.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail.dart';
import 'package:aonw/game/presentation/widgets/options/game_options_overlay.dart';
import 'package:aonw/game/presentation/widgets/screen/game_player_control_sync.dart';
import 'package:aonw/game/presentation/widgets/selection_info/providers.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_discovery_popup_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'game_hud_chrome.dart';
part 'game_hud_contract.dart';
part 'game_hud_handoff.dart';

class _GameHudState extends ConsumerState<GameHud> {
  final Set<String> _confirmedEntryHandoffs = {};
  bool _handoffTransitionInProgress = false;
  bool _resigning = false;
  bool _optionsOverlayPanelActive = false;

  void _setResigning(bool resigning) {
    if (!mounted || _resigning == resigning) return;
    setState(() => _resigning = resigning);
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
    final networkSession = ref.watch(networkSessionProvider);
    final multiplayerMatch = gameSave?.gameMode == GameMode.multiplayer
        ? ref.watch(
            multiplayerMatchProvider.select(
              (matches) => matches[widget.session.saveId],
            ),
          )
        : null;
    final networkBackedMultiplayer =
        gameSave?.gameMode == GameMode.multiplayer &&
        (networkSession?.matchId == widget.session.saveId ||
            multiplayerMatch != null);
    final outcomeSummary = gameSave == null
        ? null
        : HudGameOutcomeSummary.from(
            l10n: l10n,
            gameSave: gameSave,
            gameState: gameState,
            mapData: widget.session.mapData,
            multiplayerMatch: multiplayerMatch,
            networkBackedMultiplayer: networkBackedMultiplayer,
            activePlayerId: _outcomePerspectivePlayerId(
              gameSave: gameSave,
              gameStateActivePlayerId: gameState?.activePlayerId,
              playerControl: playerControl,
              networkBackedMultiplayer: networkBackedMultiplayer,
              networkPlayerId: networkSession?.matchId == widget.session.saveId
                  ? networkSession?.playerId
                  : null,
            ),
          );
    final pendingHandoff = ref.watch(gameHandoffProvider);
    final entryHandoff = pendingHandoff == null && outcomeSummary == null
        ? _entryHandoffFor(gameSave)
        : null;
    final handoff = outcomeSummary == null
        ? pendingHandoff ?? entryHandoff
        : null;
    final handoffBlocksHud = handoff != null || _handoffTransitionInProgress;
    final hudFocusTargets = HudGamepadFocusTargetRegistry.flatten(
      ref.watch(hudGamepadFocusTargetRegistryProvider),
    );
    final focusedHudTargetId = ref.watch(
      hudGamepadFocusControllerProvider.select(
        (state) => state.active ? state.targetId : null,
      ),
    );
    final hudAvailable =
        gameSave != null && !handoffBlocksHud && outcomeSummary == null;
    final hudGamepadFocusEnabled = hudAvailable && hudFocusTargets.isNotEmpty;
    void onReturnToMenu() => unawaited(_onClose(context));
    _syncReturnMenuGamepadFocusTarget(
      l10n.returnToMenuAction,
      onReturnToMenu,
      enabled: hudAvailable,
    );
    final openResourceBreakdown = gameSave == null
        ? null
        : ref.watch(hudResourceBreakdownControllerProvider);
    return HudGamepadFocusInputLayer(
      input: widget.gamepadInputListenable,
      enabled: hudGamepadFocusEnabled,
      targets: hudFocusTargets,
      resourceBreakdownOpen: openResourceBreakdown != null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!handoffBlocksHud) GamePlayerControlSync(gameSave: gameSave),
          if (widget.aiAutopilotEnabled && outcomeSummary == null)
            GameAiTurnAutoPilot(
              key: const ValueKey('game-ai-turn-auto-pilot'),
              gameSave: gameSave,
            ),
          const _HudTopFade(),
          if (gameSave != null)
            MultiplayerAvatarsRailOverlay(
              gameSave: gameSave,
              gamepadInputListenable: widget.gamepadInputListenable,
            ),
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
          if (gameSave != null)
            ..._overlayHosts(gameSave, visible: !handoffBlocksHud),
          _HudMenuButton(
            onPressed: onReturnToMenu,
            gamepadFocused:
                focusedHudTargetId == HudGamepadFocusTargetIds.menuReturn,
          ),
          GameEventNotificationsOverlay(gameSave: gameSave),
          const HudFeedbackOverlay(),
          if (gameSave != null)
            TurnStartBannerOverlay(turnNumber: gameSave.turn),
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
      ),
    );
  }

  List<Widget> _overlayHosts(GameSave gameSave, {required bool visible}) => [
    GameHudOverlayHost(
      key: const ValueKey('game-hud-overlay-host'),
      session: widget.session,
      animatingUnitIdsListenable: widget.animatingUnitIdsListenable,
      initialCameraFocusReadyListenable:
          widget.initialCameraFocusReadyListenable,
      gamepadInputListenable: widget.gamepadInputListenable,
      gameSave: gameSave,
      visible: visible,
      optionsOverlayOpenOverride: _optionsOverlayPanelActive,
    ),
    GameHudOverlayPanelsHost(
      key: const ValueKey('game-hud-overlay-panels-host'),
      session: widget.session,
      gameSave: gameSave,
      visible: visible,
      gamepadInputListenable: widget.gamepadInputListenable,
    ),
  ];

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
    final player = save.playerById(control.activePlayerId);
    if (player == null) return null;
    if (player.isAi) return null;

    return HandoffData(
      playerId: player.id,
      playerName: GameDisplayNames.player(AppLocalizations.of(context), player),
      playerColorValue: player.colorValue,
      turnNumber: save.turn,
    );
  }

  Future<void> _prepareHandoffControlAndCamera(HandoffData handoff) async {
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
          .confirmHandoff(handoff.playerId);
      if (!mounted) return;
    }

    await ref
        .read(hudCommandDispatcherProvider)
        .focusTurnStartMapTarget(
          activePlayerId: handoff.playerId,
          state: ref.read(gameStateProvider(widget.session.saveId)).value,
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
      await _prepareHandoffControlAndCamera(handoff);
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
