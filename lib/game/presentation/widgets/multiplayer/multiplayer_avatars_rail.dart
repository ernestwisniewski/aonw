import 'dart:async';

import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomacy_player_modal.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_side_menu_metrics.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail_layouts.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail_metrics.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_status_sheet.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'multiplayer_avatars_sheet.dart';

class MultiplayerAvatarsRailOverlay extends ConsumerStatefulWidget {
  static const double rightOffset = 12;
  static const double compactRightOffset = 8;

  final GameSave gameSave;

  const MultiplayerAvatarsRailOverlay({required this.gameSave, super.key});

  @override
  ConsumerState<MultiplayerAvatarsRailOverlay> createState() =>
      _MultiplayerAvatarsRailOverlayState();
}

class _MultiplayerAvatarsRailOverlayState
    extends ConsumerState<MultiplayerAvatarsRailOverlay> {
  final GlobalKey _requestedStatusSheetKey = GlobalKey();

  @override
  void didUpdateWidget(covariant MultiplayerAvatarsRailOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final save = widget.gameSave;
    if (save.id != oldWidget.gameSave.id ||
        save.gameMode != GameMode.multiplayer ||
        save.turn > oldWidget.gameSave.turn) {
      _dismissRequestedStatusSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameSave = widget.gameSave;
    if (gameSave.gameMode != GameMode.multiplayer || gameSave.players.isEmpty) {
      return const SizedBox.shrink();
    }

    final playerControl = PlayerControlCoordinator.normalize(
      current: ref.watch(gamePlayerControlControllerProvider),
      save: gameSave,
    );
    final gameState = ref.watch(gameStateProvider(gameSave.id)).value;
    ref.watch(_mapDataProvider(gameSave));
    final diplomacy = gameState?.diplomacy ?? DiplomacyState.empty;
    ref.listen<MultiplayerStatusSheetRequest?>(
      multiplayerStatusSheetRequestProvider,
      (previous, next) {
        if (next == null || next.save.id != gameSave.id) return;
        ref
            .read(multiplayerStatusSheetRequestProvider.notifier)
            .consume(next.id);
        final sheetGameState =
            ref.read(gameStateProvider(next.save.id)).value ?? gameState;
        final sheetDiplomacy = sheetGameState?.diplomacy ?? diplomacy;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !context.mounted || _requestIsStale(next)) return;
          unawaited(
            MultiplayerAvatarsRail.showPlayersSheet(
              context,
              gameSave: next.save,
              activePlayerId: next.activePlayerId,
              diplomacy: sheetDiplomacy,
              gameState: sheetGameState,
              sheetRouteKey: _requestedStatusSheetKey,
              onAvatarTapped: (playerId) => _handleAvatarTapped(
                context,
                gameSave: gameSave,
                gameState: sheetGameState,
                activePlayerId: playerControl.activePlayerId,
                playerId: playerId,
              ),
            ),
          );
        });
      },
    );
    final safePadding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final compact = MultiplayerAvatarsRailMetrics.useCompactLayout(
      width: size.width,
      height: size.height,
    );

    return Positioned(
      top: safePadding.top + _topOffset(compact),
      right: safePadding.right + _rightOffset(compact),
      child: MultiplayerAvatarsRail(
        gameSave: gameSave,
        activePlayerId: playerControl.activePlayerId,
        diplomacy: diplomacy,
        gameState: gameState,
        onAvatarTapped: (playerId) => _handleAvatarTapped(
          context,
          gameSave: gameSave,
          gameState: gameState,
          activePlayerId: playerControl.activePlayerId,
          playerId: playerId,
        ),
      ),
    );
  }

  void _handleAvatarTapped(
    BuildContext context, {
    required GameSave gameSave,
    required GameState? gameState,
    required String activePlayerId,
    required String playerId,
  }) {
    if (playerId == activePlayerId || gameState == null) {
      unawaited(
        ref
            .read(gameCommandControllerProvider.notifier)
            .jumpToPlayerStart(playerId),
      );
      return;
    }
    final mapData = ref.read(_mapDataProvider(gameSave)).value;
    if (mapData == null) return;
    if (!MultiplayerAvatarsRail._hasDiplomaticContact(
      gameState: gameState,
      diplomacy: gameState.diplomacy,
      playerId: activePlayerId,
      targetPlayerId: playerId,
    )) {
      return;
    }
    unawaited(
      showDiplomacyPlayerModal(
        context,
        gameSave: gameSave,
        gameState: gameState,
        mapData: mapData,
        activePlayerId: activePlayerId,
        targetPlayerId: playerId,
        onCommand: ref.read(gameCommandControllerProvider.notifier).dispatch,
      ),
    );
  }

  static ActiveMapProvider _mapDataProvider(GameSave save) => activeMapProvider(
    MapSelection(name: save.mapName, source: save.mapSource),
  );

  static double _topOffset(bool compact) => compact
      ? HudSideMenuMetrics.compactTopOffset
      : HudSideMenuMetrics.topOffset;

  static double _rightOffset(bool compact) => compact
      ? MultiplayerAvatarsRailOverlay.compactRightOffset
      : MultiplayerAvatarsRailOverlay.rightOffset;

  bool _requestIsStale(MultiplayerStatusSheetRequest request) =>
      widget.gameSave.id != request.save.id ||
      widget.gameSave.gameMode != GameMode.multiplayer ||
      widget.gameSave.turn > request.save.turn;

  void _dismissRequestedStatusSheet() {
    final sheetContext = _requestedStatusSheetKey.currentContext;
    if (sheetContext == null || !sheetContext.mounted) return;
    unawaited(Navigator.of(sheetContext).maybePop());
  }
}

class MultiplayerAvatarsRail extends StatelessWidget {
  static const double itemWidth = MultiplayerAvatarsRailMetrics.itemWidth;
  static const double itemHeight = MultiplayerAvatarsRailMetrics.itemHeight;
  static const double compactItemSize =
      MultiplayerAvatarsRailMetrics.compactItemSize;

  final GameSave gameSave;
  final String activePlayerId;
  final ValueChanged<String> onAvatarTapped;
  final Map<String, String> timerLabels;
  final Set<String> timedOutPlayerIds;
  final DiplomacyState diplomacy;
  final GameState? gameState;

  const MultiplayerAvatarsRail({
    required this.gameSave,
    required this.activePlayerId,
    required this.onAvatarTapped,
    this.timerLabels = const {},
    this.timedOutPlayerIds = const {},
    this.diplomacy = DiplomacyState.empty,
    this.gameState,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (gameSave.gameMode != GameMode.multiplayer || gameSave.players.isEmpty) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.sizeOf(context);
    final compact = MultiplayerAvatarsRailMetrics.useCompactLayout(
      width: size.width,
      height: size.height,
    );
    final tiles = tileDataFor(
      context: context,
      gameSave: gameSave,
      activePlayerId: activePlayerId,
      diplomacy: diplomacy,
      gameState: gameState,
      timerLabels: timerLabels,
      timedOutPlayerIds: timedOutPlayerIds,
    );

    if (compact) {
      return CompactMultiplayerAvatarsRail(
        tiles: tiles,
        onAvatarTapped: onAvatarTapped,
        onOpenFullList: () => unawaited(_showFullListSheet(context, tiles)),
      );
    }

    return ExpandedMultiplayerAvatarsRail(
      key: const Key('multiplayerAvatarsRail'),
      tiles: tiles,
      onAvatarTapped: onAvatarTapped,
      onOpenFullList: () => unawaited(_showFullListSheet(context, tiles)),
    );
  }

  MultiplayerAvatarStatus statusFor(Player player) {
    return statusForPlayer(
      player: player,
      gameSave: gameSave,
      activePlayerId: activePlayerId,
      timedOutPlayerIds: timedOutPlayerIds,
    );
  }

  static MultiplayerAvatarStatus statusForPlayer({
    required Player player,
    required GameSave gameSave,
    required String activePlayerId,
    Set<String> timedOutPlayerIds = const {},
  }) {
    if (timedOutPlayerIds.contains(player.id)) {
      return MultiplayerAvatarStatus.timeout;
    }
    if (gameSave.playerStates[player.id] == PlayerTurnState.finished) {
      return MultiplayerAvatarStatus.submitted;
    }
    if (player.isAi) return MultiplayerAvatarStatus.thinking;
    if (player.id == activePlayerId) return MultiplayerAvatarStatus.active;
    return MultiplayerAvatarStatus.waiting;
  }

  static List<MultiplayerAvatarTileData> tileDataFor({
    required BuildContext context,
    required GameSave gameSave,
    required String activePlayerId,
    DiplomacyState diplomacy = DiplomacyState.empty,
    GameState? gameState,
    Map<String, String> timerLabels = const {},
    Set<String> timedOutPlayerIds = const {},
  }) {
    final l10n = AppLocalizations.of(context);
    return [
      for (final player in gameSave.players)
        MultiplayerAvatarTileData(
          player: player,
          playerName: GameDisplayNames.player(l10n, player),
          status: statusForPlayer(
            player: player,
            gameSave: gameSave,
            activePlayerId: activePlayerId,
            timedOutPlayerIds: timedOutPlayerIds,
          ),
          timerLabel: timerLabels[player.id],
          relationStatus:
              activePlayerId.isEmpty ||
                  player.id == activePlayerId ||
                  !_hasDiplomaticContact(
                    gameState: gameState,
                    diplomacy: diplomacy,
                    playerId: activePlayerId,
                    targetPlayerId: player.id,
                  )
              ? null
              : diplomacy.statusBetween(activePlayerId, player.id),
        ),
    ];
  }

  static Future<void> showPlayersSheet(
    BuildContext context, {
    required GameSave gameSave,
    required String activePlayerId,
    required ValueChanged<String> onAvatarTapped,
    DiplomacyState diplomacy = DiplomacyState.empty,
    Map<String, String> timerLabels = const {},
    Set<String> timedOutPlayerIds = const {},
    GameState? gameState,
    Key? sheetRouteKey,
  }) {
    return _showPlayersSheet(
      context,
      tiles: tileDataFor(
        context: context,
        gameSave: gameSave,
        activePlayerId: activePlayerId,
        diplomacy: diplomacy,
        gameState: gameState,
        timerLabels: timerLabels,
        timedOutPlayerIds: timedOutPlayerIds,
      ),
      gameState: gameState,
      onAvatarTapped: onAvatarTapped,
      sheetRouteKey: sheetRouteKey,
    );
  }

  Future<void> _showFullListSheet(
    BuildContext context,
    List<MultiplayerAvatarTileData> tiles,
  ) {
    return _showPlayersSheet(
      context,
      tiles: tiles,
      gameState: gameState,
      onAvatarTapped: onAvatarTapped,
    );
  }

  static bool _hasDiplomaticContact({
    required GameState? gameState,
    required DiplomacyState diplomacy,
    required String playerId,
    required String targetPlayerId,
  }) {
    if (playerId.isEmpty ||
        targetPlayerId.isEmpty ||
        playerId == targetPlayerId) {
      return false;
    }
    if (diplomacy.hasContact(playerId, targetPlayerId)) return true;
    if (gameState == null) return false;
    return DiplomaticContact.hasContact(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      fogOfWar: gameState.fogOfWar,
      units: gameState.units,
      cities: gameState.cities,
    );
  }
}
