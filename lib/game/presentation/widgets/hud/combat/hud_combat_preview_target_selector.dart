part of 'hud_combat_preview_factory.dart';

final class _PreviewTargetSelector {
  const _PreviewTargetSelector(this.request);

  final _PreviewRequest request;

  _PreviewTarget? select() {
    final pendingAction = request.pendingAction;
    if (pendingAction.hasDefenderTarget) {
      return _targetAt(pendingAction.defenderCol!, pendingAction.defenderRow!);
    }
    return _bestVisibleTarget();
  }

  _PreviewTarget? _targetAt(int col, int row) {
    final defender = request.state.unitAt(col, row);
    if (defender != null && defender.id != request.attacker.id) {
      return _unitTarget(defender);
    }
    final city = request.state.cityAt(col, row);
    return city == null ? null : _cityTarget(city);
  }

  _PreviewTarget? _bestVisibleTarget() {
    final candidates = [
      for (final unit in request.state.units) ?_unitTarget(unit),
      for (final city in request.state.cities) ?_cityTarget(city),
    ]..sort(_compareTargets);
    return candidates.isEmpty ? null : candidates.first;
  }

  _PreviewTarget? _unitTarget(GameUnit defender) {
    if (defender.id == request.attacker.id ||
        !_canPreviewOwner(defender.ownerPlayerId) ||
        !_isVisible(defender.col, defender.row)) {
      return null;
    }
    final tile = request.mapData.tileAt(defender.col, defender.row);
    if (tile == null) return null;

    final distance = _distanceTo(defender.col, defender.row);
    if (distance > request.targetSearchRange) return null;
    return _PreviewTarget.unit(
      defender: defender,
      tile: tile,
      distance: distance,
    );
  }

  _PreviewTarget? _cityTarget(GameCity city) {
    if (!_canPreviewOwner(city.ownerPlayerId) ||
        !_isVisible(city.center.col, city.center.row) ||
        _isBlockedByAnotherUnit(city)) {
      return null;
    }
    final tile = request.mapData.tileAt(city.center.col, city.center.row);
    if (tile == null) return null;

    final distance = _distanceTo(city.center.col, city.center.row);
    if (distance > request.targetSearchRange) return null;
    return _PreviewTarget.city(city: city, tile: tile, distance: distance);
  }

  bool _canPreviewOwner(String targetOwnerPlayerId) {
    final attackerOwnerPlayerId = request.attacker.ownerPlayerId;
    if (targetOwnerPlayerId == attackerOwnerPlayerId) return false;
    final status = request.state.diplomacy.statusBetween(
      attackerOwnerPlayerId,
      targetOwnerPlayerId,
    );
    return status != DiplomaticRelationStatus.friendly &&
        status != DiplomaticRelationStatus.truce;
  }

  bool _isVisible(int col, int row) {
    return request.state.activePlayerVisibility.canSeeDynamicAt(col, row);
  }

  bool _isBlockedByAnotherUnit(GameCity city) {
    final occupant = request.state.unitAt(city.center.col, city.center.row);
    return occupant != null && occupant.id != request.attacker.id;
  }

  int _distanceTo(int col, int row) {
    return HexDistance.between(
      HexCoordinate(col: request.attacker.col, row: request.attacker.row),
      HexCoordinate(col: col, row: row),
    );
  }

  static int _compareTargets(_PreviewTarget left, _PreviewTarget right) {
    final distance = left.distance.compareTo(right.distance);
    if (distance != 0) return distance;
    final col = left.col.compareTo(right.col);
    if (col != 0) return col;
    final row = left.row.compareTo(right.row);
    return row != 0 ? row : left.id.compareTo(right.id);
  }
}

final class _PreviewTarget {
  const _PreviewTarget.unit({
    required GameUnit this.defender,
    required this.tile,
    required this.distance,
  }) : city = null;

  const _PreviewTarget.city({
    required GameCity this.city,
    required this.tile,
    required this.distance,
  }) : defender = null;

  final GameUnit? defender;
  final GameCity? city;
  final TileData tile;
  final int distance;

  bool get isCity => city != null;

  String get id => defender?.id ?? city!.id;

  String get ownerPlayerId => defender?.ownerPlayerId ?? city!.ownerPlayerId;

  String get name => defender?.name ?? city!.name;

  int get col => defender?.col ?? city!.center.col;

  int get row => defender?.row ?? city!.center.row;

  int currentHp(CombatStats effectiveStats) {
    final unit = defender;
    if (unit != null) {
      return UnitCombatHealth.currentHp(unit, effectiveStats: effectiveStats);
    }
    return CityCombatHealth.currentHp(city!, effectiveStats: effectiveStats);
  }
}
