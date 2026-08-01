import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class MapFocusVisibility {
  static FogVisibilityQuery queryFor(
    GameClientState state, {
    String? viewerPlayerId,
  }) {
    return FogVisibilityQuery(
      playerId: viewerPlayerId ?? state.activePlayerId,
      state: state.fogOfWar,
    );
  }

  static bool canRenderTransientAt(
    GameClientState state,
    int col,
    int row, {
    String? viewerPlayerId,
  }) {
    return canSeeDynamicAt(state, col, row, viewerPlayerId: viewerPlayerId);
  }

  static bool canAutoFocusAt(
    GameClientState state,
    int col,
    int row, {
    String? viewerPlayerId,
  }) {
    return canSeeDynamicAt(state, col, row, viewerPlayerId: viewerPlayerId);
  }

  static bool canFocusUnit(
    GameClientState state,
    GameUnit unit, {
    String? viewerPlayerId,
  }) {
    final viewerId = viewerPlayerId ?? state.activePlayerId;
    if (viewerId.isNotEmpty && unit.ownerPlayerId == viewerId) return true;
    return canSeeDynamicAt(
      state,
      unit.col,
      unit.row,
      viewerPlayerId: viewerPlayerId,
    );
  }

  static bool canFocusCity(
    GameClientState state,
    GameCity city, {
    String? viewerPlayerId,
  }) {
    final viewerId = viewerPlayerId ?? state.activePlayerId;
    if (viewerId.isNotEmpty && city.ownerPlayerId == viewerId) return true;
    return canRememberStaticAt(
      state,
      city.center.col,
      city.center.row,
      viewerPlayerId: viewerPlayerId,
    );
  }

  static bool canAutoFocusCity(
    GameClientState state,
    GameCity city, {
    String? viewerPlayerId,
  }) {
    final viewerId = viewerPlayerId ?? state.activePlayerId;
    if (viewerId.isNotEmpty && city.ownerPlayerId == viewerId) return true;
    return canSeeDynamicAt(
      state,
      city.center.col,
      city.center.row,
      viewerPlayerId: viewerPlayerId,
    );
  }

  static bool canSeeDynamicAt(
    GameClientState state,
    int col,
    int row, {
    String? viewerPlayerId,
  }) {
    final visibility = queryFor(state, viewerPlayerId: viewerPlayerId);
    if (!_hasFogForViewer(state, visibility)) return true;
    return visibility.canSeeDynamicAt(col, row);
  }

  static bool canRememberStaticAt(
    GameClientState state,
    int col,
    int row, {
    String? viewerPlayerId,
  }) {
    final visibility = queryFor(state, viewerPlayerId: viewerPlayerId);
    if (!_hasFogForViewer(state, visibility)) return true;
    return visibility.canRememberStaticAt(col, row);
  }

  static bool _hasFogForViewer(
    GameClientState state,
    FogVisibilityQuery visibility,
  ) {
    return visibility.isEnabled &&
        state.fogOfWar.playerIds.contains(visibility.playerId);
  }
}
