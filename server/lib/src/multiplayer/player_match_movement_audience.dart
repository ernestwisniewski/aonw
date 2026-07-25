import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

/// Owns server-only recipients for complete authoritative movement chains.
///
/// Annotation and projection both preserve the canonical execution order.
/// Invalid evidence is removed per unit rather than clipped to a partial path.
abstract final class PlayerMatchMovementAudience {
  static WireMovementExecutionList? annotateForStorage({
    required Iterable<MovementCommandExecution>? executions,
    required Iterable<String> participantPlayerIds,
    required Iterable<GameUnit> previousUnits,
    required Iterable<GameUnit> nextUnits,
    required FogOfWarState previousFog,
    required FogOfWarState nextFog,
  }) {
    if (executions == null) return null;
    final ordered = List<MovementCommandExecution>.unmodifiable(executions);
    final chains = _domainChains(ordered);
    final audiences = _audiencesByUnit(
      chains: chains,
      participantPlayerIds: participantPlayerIds,
      previousUnits: _UnitIndex(previousUnits),
      nextUnits: _UnitIndex(nextUnits),
      previousFog: previousFog,
      nextFog: nextFog,
    );
    return WireMovementExecutionList(_annotatedExecutions(ordered, audiences));
  }

  static WireMovementExecutionList? projectForRecipient(
    WireMovementExecutionList? canonical, {
    required String recipientPlayerId,
  }) {
    if (canonical == null) return null;
    final audits = _wireChainAudits(canonical.values);
    return WireMovementExecutionList(
      _projectedExecutions(
        canonical.values,
        audits: audits,
        recipientPlayerId: recipientPlayerId,
      ),
    );
  }
}

Map<String, _DomainMovementChain> _domainChains(
  Iterable<MovementCommandExecution> executions,
) {
  final chains = <String, _DomainMovementChain>{};
  for (final execution in executions) {
    chains
        .putIfAbsent(execution.unitId, _DomainMovementChain.new)
        .add(execution);
  }
  return chains;
}

Map<String, List<String>> _audiencesByUnit({
  required Map<String, _DomainMovementChain> chains,
  required Iterable<String> participantPlayerIds,
  required _UnitIndex previousUnits,
  required _UnitIndex nextUnits,
  required FogOfWarState previousFog,
  required FogOfWarState nextFog,
}) {
  final participants = _canonicalPlayerIds(participantPlayerIds);
  final audiences = <String, List<String>>{};
  for (final entry in chains.entries) {
    final beforeUnit = previousUnits[entry.key];
    final afterUnit = nextUnits[entry.key];
    final audience = entry.value.audience(
      participants: participants,
      beforeUnit: beforeUnit,
      afterUnit: afterUnit,
      previousFog: previousFog,
      nextFog: nextFog,
    );
    if (audience.isNotEmpty) audiences[entry.key] = audience;
  }
  return audiences;
}

List<String> _canonicalPlayerIds(Iterable<String> values) {
  final unique = <String>{};
  for (final value in values) {
    if (value.trim().isNotEmpty) unique.add(value);
  }
  return unique.toList()..sort();
}

Iterable<WireMovementExecution> _annotatedExecutions(
  Iterable<MovementCommandExecution> executions,
  Map<String, List<String>> audiences,
) sync* {
  for (final execution in executions) {
    final audience = audiences[execution.unitId];
    if (audience == null) continue;
    final wire = MovementExecutionWireMapper.encode(execution);
    yield WireMovementExecution(
      unitId: wire.unitId,
      fromCol: wire.fromCol,
      fromRow: wire.fromRow,
      steps: wire.steps,
      serverAudiencePlayerIds: audience,
    );
  }
}

Map<String, _WireMovementChainAudit> _wireChainAudits(
  Iterable<WireMovementExecution> executions,
) {
  final audits = <String, _WireMovementChainAudit>{};
  for (final execution in executions) {
    audits
        .putIfAbsent(execution.unitId, _WireMovementChainAudit.new)
        .add(execution);
  }
  return audits;
}

Iterable<WireMovementExecution> _projectedExecutions(
  Iterable<WireMovementExecution> executions, {
  required Map<String, _WireMovementChainAudit> audits,
  required String recipientPlayerId,
}) sync* {
  for (final execution in executions) {
    final audit = audits[execution.unitId];
    if (audit == null || !audit.isVisibleTo(recipientPlayerId)) continue;
    yield WireMovementExecution(
      unitId: execution.unitId,
      fromCol: execution.fromCol,
      fromRow: execution.fromRow,
      steps: execution.steps,
    );
  }
}

final class _DomainMovementChain {
  final List<HexCoordinate> _coordinates = [];
  HexCoordinate? _destination;
  bool _continuous = true;

  void add(MovementCommandExecution execution) {
    final origin = HexCoordinate(
      col: execution.fromCol,
      row: execution.fromRow,
    );
    if (_destination == null) {
      _coordinates.add(origin);
    } else if (_destination != origin) {
      _continuous = false;
    }
    for (final step in execution.steps) {
      final coordinate = HexCoordinate(col: step.col, row: step.row);
      _coordinates.add(coordinate);
      _destination = coordinate;
    }
  }

  List<String> audience({
    required List<String> participants,
    required GameUnit? beforeUnit,
    required GameUnit? afterUnit,
    required FogOfWarState previousFog,
    required FogOfWarState nextFog,
  }) {
    if (!_matchesTransition(beforeUnit, afterUnit)) return const [];
    final ownerPlayerId = beforeUnit?.ownerPlayerId ?? afterUnit?.ownerPlayerId;
    if (ownerPlayerId == null || ownerPlayerId.isEmpty) return const [];
    return List.unmodifiable([
      for (final playerId in participants)
        if (playerId == ownerPlayerId ||
            _isVisibleTo(playerId, previousFog: previousFog, nextFog: nextFog))
          playerId,
    ]);
  }

  bool _matchesTransition(GameUnit? beforeUnit, GameUnit? afterUnit) {
    if (!_continuous ||
        _coordinates.isEmpty ||
        beforeUnit == null ||
        afterUnit == null) {
      return false;
    }
    if (beforeUnit.ownerPlayerId != afterUnit.ownerPlayerId) return false;
    final origin = _coordinates.first;
    final destination = _destination!;
    return origin.col == beforeUnit.col &&
        origin.row == beforeUnit.row &&
        destination.col == afterUnit.col &&
        destination.row == afterUnit.row;
  }

  bool _isVisibleTo(
    String playerId, {
    required FogOfWarState previousFog,
    required FogOfWarState nextFog,
  }) {
    for (final coordinate in _coordinates) {
      if (!previousFog.isVisible(playerId, coordinate) ||
          !nextFog.isVisible(playerId, coordinate)) {
        return false;
      }
    }
    return true;
  }
}

final class _UnitIndex {
  _UnitIndex(Iterable<GameUnit> units) {
    for (final unit in units) {
      if (_duplicates.contains(unit.id)) continue;
      if (_units.containsKey(unit.id)) {
        _units.remove(unit.id);
        _duplicates.add(unit.id);
      } else {
        _units[unit.id] = unit;
      }
    }
  }

  final Map<String, GameUnit> _units = {};
  final Set<String> _duplicates = {};

  GameUnit? operator [](String unitId) => _units[unitId];
}

final class _WireMovementChainAudit {
  List<String>? _audience;
  HexCoordinate? _destination;
  var _seen = false;
  var _valid = true;

  void add(WireMovementExecution execution) {
    final origin = HexCoordinate(
      col: execution.fromCol,
      row: execution.fromRow,
    );
    if (_destination != null && _destination != origin) _valid = false;
    final audience = execution.serverAudiencePlayerIds;
    if (!_seen) {
      _audience = audience;
      _seen = true;
    } else if (!_sameStrings(_audience, audience)) {
      _valid = false;
    }
    if (audience == null) _valid = false;
    final last = execution.steps.last;
    _destination = HexCoordinate(col: last.col, row: last.row);
  }

  bool isVisibleTo(String playerId) =>
      _valid && (_audience?.contains(playerId) ?? false);
}

bool _sameStrings(List<String>? first, List<String>? second) {
  if (identical(first, second)) return true;
  if (first == null || second == null || first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
