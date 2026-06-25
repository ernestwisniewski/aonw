import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_management_overlay.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';

class CityManagementOverlayLayer extends Component with LayerAttachment {
  CityManagementOverlay? _component;
  List<CityManagementOverlayHex> _overlayHexes = const [];

  CityManagementOverlayLayer() {
    priority = MapPriority.cityManagementOverlay;
  }

  List<CityManagementOverlayHex> get overlayHexesForTesting => _overlayHexes;

  void sync({
    required Component parent,
    required GameState state,
    required MapData mapData,
    required CityRuleset cityRuleset,
    bool Function(CityHex hex)? canShowHex,
    bool dimmed = false,
  }) {
    ensureAttachedTo(parent);

    final pending = state.pendingAction;
    final cityId = switch (pending) {
      PendingCityWorkedHexSelection(:final cityId) => cityId,
      PendingCityExpansionSelection(:final cityId) => cityId,
      _ => null,
    };

    final overlayHexes = cityId == null
        ? _selectedWorkerImprovementHexes(
            state: state,
            mapData: mapData,
            cityRuleset: cityRuleset,
            canShowHex: canShowHex,
          )
        : _cityWorkedHexes(
            cityId: cityId,
            pending: pending!,
            state: state,
            mapData: mapData,
            cityRuleset: cityRuleset,
            canShowHex: canShowHex,
          );

    if (overlayHexes.isEmpty) {
      clear();
      return;
    }
    _overlayHexes = overlayHexes;
    final existing = _component;
    if (existing != null) {
      existing.updateHexes(hexes: overlayHexes, dimmed: dimmed);
      return;
    }

    final component = CityManagementOverlay(
      hexes: overlayHexes,
      dimmed: dimmed,
    );
    _component = component;
    unawaited(Future<void>.value(add(component)));
  }

  void clear() {
    _component?.removeFromParent();
    _component = null;
    _overlayHexes = const [];
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  CityManagementOverlay? get componentForTesting => _component;

  List<CityManagementOverlayHex> _cityWorkedHexes({
    required String cityId,
    required PendingPlayerAction pending,
    required GameState state,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required bool Function(CityHex hex)? canShowHex,
  }) {
    final city = state.cities.where((city) => city.id == cityId).firstOrNull;
    if (city == null) return const [];

    return switch (pending) {
      PendingCityWorkedHexSelection() => _workedHexes(
        city: city,
        state: state,
        mapData: mapData,
        cityRuleset: cityRuleset,
        canShowHex: canShowHex,
      ),
      PendingCityExpansionSelection() => _cityExpansionHexes(
        city: city,
        state: state,
        mapData: mapData,
        cityRuleset: cityRuleset,
        canShowHex: canShowHex,
      ),
      _ => const <CityManagementOverlayHex>[],
    };
  }

  List<CityManagementOverlayHex> _cityExpansionHexes({
    required GameCity city,
    required GameState state,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required bool Function(CityHex hex)? canShowHex,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: state.research,
      ruleset: TechnologyRulesets.standard,
    );
    final recommended = CityExpansionSelector.preferredOrBestHex(
      city: city,
      mapData: mapData,
      cities: state.cities,
      allowCoast: true,
      allowOcean: true,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
    );
    final candidates =
        CityExpansionSelector.candidatesFor(
            city: city,
            mapData: mapData,
            cities: state.cities,
            allowCoast: true,
            allowOcean: true,
            ruleset: cityRuleset,
            technologyEffects: technologyEffects,
          ).where((candidate) {
            final visible = canShowHex?.call(candidate.hex) ?? true;
            return visible;
          }).toList()
          ..sort((a, b) {
            final aRecommended = a.hex == recommended;
            final bRecommended = b.hex == recommended;
            if (aRecommended != bRecommended) return aRecommended ? -1 : 1;
            final score = b.score.compareTo(a.score);
            if (score != 0) return score;
            final distance = a.distance.compareTo(b.distance);
            if (distance != 0) return distance;
            final col = a.hex.col.compareTo(b.hex.col);
            if (col != 0) return col;
            return a.hex.row.compareTo(b.hex.row);
          });

    return [
      for (final candidate in candidates)
        CityManagementOverlayHex(
          hex: candidate.hex,
          kind: candidate.hex == recommended
              ? CityManagementOverlayHexKind.growthRecommended
              : CityManagementOverlayHexKind.growthCandidate,
          label: candidate.hex == recommended ? 'N' : '+',
          tileYield: switch (mapData.tileAt(
            candidate.hex.col,
            candidate.hex.row,
          )) {
            final tile? => CityTileYieldRules.forTile(
              tile,
              ruleset: cityRuleset,
            ),
            _ => null,
          },
        ),
    ];
  }

  List<CityManagementOverlayHex> _selectedWorkerImprovementHexes({
    required GameState state,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required bool Function(CityHex hex)? canShowHex,
  }) {
    final worker = _selectedControllableWorker(state);
    if (worker == null) return const [];

    final result = <CityManagementOverlayHex>[];
    for (final tile in mapData.tiles) {
      final hex = CityHex(col: tile.col, row: tile.row);
      if (canShowHex?.call(hex) == false) continue;

      final workerOverlay = _workerImprovementOverlay(
        worker: worker,
        hex: hex,
        state: state,
        mapData: mapData,
        cityRuleset: cityRuleset,
      );
      if (workerOverlay == null) continue;

      result.add(
        CityManagementOverlayHex(
          hex: hex,
          kind: workerOverlay.kind,
          label: workerOverlay.label,
          tileYield: workerOverlay.tileYield,
        ),
      );
    }

    result.sort((a, b) {
      final kind = _workerKindPriority(
        a.kind,
      ).compareTo(_workerKindPriority(b.kind));
      if (kind != 0) return kind;
      final col = a.hex.col.compareTo(b.hex.col);
      if (col != 0) return col;
      return a.hex.row.compareTo(b.hex.row);
    });
    return List.unmodifiable(result);
  }

  GameUnit? _selectedControllableWorker(GameState state) {
    final unit = state.selectedUnit;
    if (unit == null ||
        !unit.isWorker ||
        unit.isWorking ||
        !state.canControlUnit(unit)) {
      return null;
    }
    return unit;
  }

  ({CityManagementOverlayHexKind kind, String label, TileYield tileYield})?
  _workerImprovementOverlay({
    required GameUnit worker,
    required CityHex hex,
    required GameState state,
    required MapData mapData,
    required CityRuleset cityRuleset,
  }) {
    if (_isOwnCityCenter(worker.ownerPlayerId, hex, state.cities)) {
      return null;
    }
    final tile = mapData.tileAt(hex.col, hex.row);
    final city = _controlledCityForHex(worker.ownerPlayerId, hex, state.cities);
    if (city != null) {
      if (_hasFieldImprovement(hex, state.fieldImprovements)) {
        final yield = CityTileYieldRules.forCityHex(
          city: city,
          hex: hex,
          tile: tile,
          fieldImprovements: state.fieldImprovements,
          ruleset: cityRuleset,
        );
        return (
          kind: CityManagementOverlayHexKind.workerImprovementExisting,
          label: _yieldLabel(yield),
          tileYield: yield,
        );
      }
      final yield =
          _bestImprovedYieldFor(
            worker: worker,
            hex: hex,
            state: state,
            mapData: mapData,
            cityRuleset: cityRuleset,
          ) ??
          (tile == null
              ? TileYield.zero
              : CityTileYieldRules.forTile(tile, ruleset: cityRuleset));
      return (
        kind: CityManagementOverlayHexKind.workerImprovementMissingInCity,
        label: _yieldLabel(yield),
        tileYield: yield,
      );
    }

    return null;
  }

  int _workerKindPriority(CityManagementOverlayHexKind kind) => switch (kind) {
    CityManagementOverlayHexKind.workerImprovementMissingInCity => 0,
    CityManagementOverlayHexKind.workerImprovementExisting => 1,
    _ => 3,
  };

  bool _isOwnCityCenter(
    String playerId,
    CityHex hex,
    Iterable<GameCity> cities,
  ) {
    for (final city in cities) {
      if (city.ownerPlayerId == playerId && city.center == hex) return true;
    }
    return false;
  }

  GameCity? _controlledCityForHex(
    String playerId,
    CityHex hex,
    Iterable<GameCity> cities,
  ) {
    for (final city in cities) {
      if (city.ownerPlayerId == playerId && city.controlsHex(hex)) {
        return city;
      }
    }
    return null;
  }

  bool _hasFieldImprovement(
    CityHex hex,
    Iterable<FieldImprovement> fieldImprovements,
  ) {
    for (final improvement in fieldImprovements) {
      if (improvement.hex == hex) return true;
    }
    return false;
  }

  TileYield? _bestImprovedYieldFor({
    required GameUnit worker,
    required CityHex hex,
    required GameState state,
    required MapData mapData,
    required CityRuleset cityRuleset,
  }) {
    final tile = mapData.tileAt(hex.col, hex.row);
    if (tile == null) return null;

    TileYield? bestYield;
    var bestScore = -1;
    FieldImprovementType? bestType;
    for (final type in FieldImprovementType.values) {
      final legality = WorkerImprovementRules.evaluate(
        unit: worker,
        improvementType: type,
        cities: state.cities,
        fieldImprovements: state.fieldImprovements,
        mapData: mapData,
        research: state.research,
        targetHex: hex,
        requireReadyWorker: false,
        cityRuleset: cityRuleset,
      );
      if (!legality.allowed) continue;

      final yield = CityTileYieldRules.forTile(
        tile,
        improvement: type,
        ruleset: cityRuleset,
      );
      final score = _yieldScore(yield);
      if (bestYield == null ||
          score > bestScore ||
          (score == bestScore &&
              (bestType == null || type.index < bestType.index))) {
        bestYield = yield;
        bestScore = score;
        bestType = type;
      }
    }
    return bestYield;
  }

  int _yieldScore(TileYield yield) {
    return yield.food * 1000 +
        yield.production * 400 +
        yield.defense * 250 +
        yield.gold * 150;
  }

  String _yieldLabel(TileYield yield) {
    final parts = <String>[
      if (yield.food > 0) '${yield.food}F',
      if (yield.production > 0) '${yield.production}P',
      if (yield.defense > 0) '${yield.defense}D',
      if (yield.gold > 0) '${yield.gold}G',
    ];
    return parts.isEmpty ? '0' : parts.join(' ');
  }

  List<CityManagementOverlayHex> _workedHexes({
    required GameCity city,
    required GameState state,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required bool Function(CityHex hex)? canShowHex,
  }) {
    final manualWorked = _manualWorkedHexes(city, cityRuleset).toSet();
    final effectiveWorked = CityWorkedHexSelector.effectiveWorkedHexes(
      city: city,
      mapData: mapData,
      fieldImprovements: state.fieldImprovements,
      ruleset: cityRuleset,
    ).toSet();

    final candidates =
        CityWorkedHexSelector.candidatesFor(
            city: city,
            mapData: mapData,
            fieldImprovements: state.fieldImprovements,
            ruleset: cityRuleset,
          ).where((candidate) {
            final visible = canShowHex?.call(candidate.hex) ?? true;
            return visible;
          }).toList()
          ..sort((a, b) {
            final aKind = _workedKind(a.hex, manualWorked, effectiveWorked);
            final bKind = _workedKind(b.hex, manualWorked, effectiveWorked);
            final kind = _workedKindPriority(
              aKind,
            ).compareTo(_workedKindPriority(bKind));
            if (kind != 0) return kind;
            final score = b.score.compareTo(a.score);
            if (score != 0) return score;
            final col = a.hex.col.compareTo(b.hex.col);
            if (col != 0) return col;
            return a.hex.row.compareTo(b.hex.row);
          });

    return [
      for (final candidate in candidates)
        CityManagementOverlayHex(
          hex: candidate.hex,
          kind: _workedKind(candidate.hex, manualWorked, effectiveWorked),
          label: switch (_workedKind(
            candidate.hex,
            manualWorked,
            effectiveWorked,
          )) {
            CityManagementOverlayHexKind.workedManual => 'R',
            CityManagementOverlayHexKind.workedAuto => 'A',
            _ => '+',
          },
        ),
    ];
  }

  List<CityHex> _manualWorkedHexes(GameCity city, CityRuleset cityRuleset) {
    final limit = cityRuleset.progression.workedHexLimitForPopulation(
      city.population,
    );
    if (limit <= 0) return const [];

    final selected = <CityHex>[];
    final seen = <CityHex>{};
    for (final hex in city.workedHexes) {
      if (selected.length >= limit) break;
      if (hex == city.center) continue;
      if (!city.controlledHexes.contains(hex)) continue;
      if (!seen.add(hex)) continue;
      selected.add(hex);
    }
    return selected;
  }

  CityManagementOverlayHexKind _workedKind(
    CityHex hex,
    Set<CityHex> manualWorked,
    Set<CityHex> effectiveWorked,
  ) {
    if (manualWorked.contains(hex)) {
      return CityManagementOverlayHexKind.workedManual;
    }
    if (effectiveWorked.contains(hex)) {
      return CityManagementOverlayHexKind.workedAuto;
    }
    return CityManagementOverlayHexKind.workedIdle;
  }

  int _workedKindPriority(CityManagementOverlayHexKind kind) => switch (kind) {
    CityManagementOverlayHexKind.workedManual => 0,
    CityManagementOverlayHexKind.workedAuto => 1,
    CityManagementOverlayHexKind.workedIdle => 2,
    _ => 3,
  };
}
