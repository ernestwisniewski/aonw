import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/services/map_focus_visibility.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class GameEventRendererEffectMapper {
  static const Duration _combatResultCueDelay = Duration(milliseconds: 180);
  static const int _damageTextColor = 0xFFF87171;
  static const int _combatCueColor = 0xFFFBBF24;

  static List<RendererEffect> effectsFor({
    required Iterable<GameEvent> events,
    required GameState state,
    GameState? previousState,
    Set<String> skipUnitMoveIds = const {},
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
  }) {
    final effects = <RendererEffect>[];
    for (final event in events) {
      effects.addAll(
        _effectsForEvent(
          event,
          state,
          previousState,
          skipUnitMoveIds: skipUnitMoveIds,
          l10n: l10n,
          viewerPlayerId: viewerPlayerId,
          turn: turn,
        ),
      );
    }
    return effects;
  }

  static List<RendererEffect> _effectsForEvent(
    GameEvent event,
    GameState state,
    GameState? previousState, {
    required Set<String> skipUnitMoveIds,
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
  }) {
    final localizations = l10n;
    return switch (event) {
      UnitMovedEvent(
        :final unitId,
        :final fromCol,
        :final fromRow,
        :final toCol,
        :final toRow,
      ) =>
        skipUnitMoveIds.contains(unitId) ||
                (fromCol == toCol && fromRow == toRow)
            ? const []
            : [
                AnimateUnitMoveEffect(
                  unitId: unitId,
                  fromCol: fromCol,
                  fromRow: fromRow,
                  steps: [
                    UnitMovementStep(
                      col: toCol,
                      row: toRow,
                      enterCost: 0,
                      cumulativeCost: 0,
                    ),
                  ],
                ),
              ],
      CityFoundedEvent(:final cityId, :final ownerPlayerId) => _single(
        _cityFoundedEffect(
          state,
          cityId,
          ownerPlayerId,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      CityProducedUnitEvent(:final cityId) => _single(
        _cityProducedUnitEffect(state, cityId, viewerPlayerId: viewerPlayerId),
      ),
      CityClaimedHexEvent(:final cityId, :final col, :final row) => _single(
        _claimedHexEffect(
          state,
          cityId,
          col,
          row,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      CityDestroyedEvent() => const [],
      UnitKilledEvent(:final unitId, :final ownerPlayerId) =>
        _unitKilledEffects(
          state,
          previousState,
          unitId,
          ownerPlayerId,
          viewerPlayerId: viewerPlayerId,
        ),
      UnitRetreatedEvent(:final toCol, :final toRow) =>
        _canRenderTransientAt(
              state,
              toCol,
              toRow,
              viewerPlayerId: viewerPlayerId,
            )
            ? [
                ShowFloatingTextEffect(
                  text: localizations == null
                      ? '↩'
                      : localizations.modeBannerAttackRetreatProgress,
                  col: toCol,
                  row: toRow,
                  colorValue: _combatCueColor,
                  delay: _combatResultCueDelay,
                ),
              ]
            : const [],
      CombatResolvedEvent() => _combatResolvedEffects(
        state,
        previousState,
        event,
        viewerPlayerId: viewerPlayerId,
        turn: turn,
      ),
      WorkerCompletedJobEvent(:final unitId) => _single(
        _workerCompletedJobEffect(
          state,
          previousState,
          unitId,
          l10n: l10n,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      TechnologyResearchedEvent(:final playerId) => _single(
        _technologyResearchedEffect(
          state,
          playerId,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      _ => const [],
    };
  }

  static List<RendererEffect> _single(RendererEffect? effect) {
    return effect == null ? const [] : [effect];
  }

  static List<RendererEffect> _combatResolvedEffects(
    GameState state,
    GameState? previousState,
    CombatResolvedEvent event, {
    String? viewerPlayerId,
    int? turn,
  }) {
    final effects = <RendererEffect>[const ShakeCameraEffect()];
    var defenderDamage = 0;
    var attackerDamage = 0;
    for (final step in event.outcome.steps) {
      switch (step) {
        case AttackStep(:final damage):
          defenderDamage += damage;
        case RetaliationStep(:final damage):
          attackerDamage += damage;
        case ModifierAppliedStep() || RollStep():
          break;
      }
    }

    final attacker =
        _unitById(previousState ?? state, event.attackerUnitId) ??
        _unitById(state, event.attackerUnitId);
    final defender =
        _unitById(previousState ?? state, event.defenderUnitId) ??
        _unitById(state, event.defenderUnitId);
    final attackerAlertUnit = _unitById(state, event.attackerUnitId);
    final defenderAlertUnit = _unitById(state, event.defenderUnitId);
    final defenderCity =
        _cityById(previousState ?? state, event.defenderUnitId) ??
        _cityById(state, event.defenderUnitId);

    if (attackerAlertUnit != null &&
        _canRenderTransientAt(
          state,
          attackerAlertUnit.col,
          attackerAlertUnit.row,
          viewerPlayerId: viewerPlayerId,
        )) {
      effects.add(
        _combatHexAlertEffect(
          id: 'attacker:${event.attackerUnitId}',
          unitId: event.attackerUnitId,
          ownerPlayerId: attackerAlertUnit.ownerPlayerId,
          col: attackerAlertUnit.col,
          row: attackerAlertUnit.row,
          kind: CombatHexAlertKind.attacker,
          state: state,
          turn: turn,
        ),
      );
    }

    if (defenderAlertUnit != null &&
        _canRenderTransientAt(
          state,
          defenderAlertUnit.col,
          defenderAlertUnit.row,
          viewerPlayerId: viewerPlayerId,
        )) {
      effects.add(
        _combatHexAlertEffect(
          id: 'defender:${event.defenderUnitId}',
          unitId: event.defenderUnitId,
          ownerPlayerId: defenderAlertUnit.ownerPlayerId,
          col: defenderAlertUnit.col,
          row: defenderAlertUnit.row,
          kind: CombatHexAlertKind.attacked,
          state: state,
          turn: turn,
        ),
      );
    } else if (defenderCity != null &&
        _canRenderTransientAt(
          state,
          defenderCity.center.col,
          defenderCity.center.row,
          viewerPlayerId: viewerPlayerId,
        )) {
      effects.add(
        _combatHexAlertEffect(
          id: 'city:${defenderCity.id}',
          cityId: defenderCity.id,
          ownerPlayerId: defenderCity.ownerPlayerId,
          col: defenderCity.center.col,
          row: defenderCity.center.row,
          kind: CombatHexAlertKind.attacked,
          state: state,
          turn: turn,
        ),
      );
    }

    if (defenderDamage > 0) {
      if (defender != null &&
          _canRenderTransientAt(
            state,
            defender.col,
            defender.row,
            viewerPlayerId: viewerPlayerId,
          )) {
        effects.add(_damageTextEffect(defender, defenderDamage));
      } else {
        if (defenderCity != null) {
          final defenderCityVisible = _canRenderTransientAt(
            state,
            defenderCity.center.col,
            defenderCity.center.row,
            viewerPlayerId: viewerPlayerId,
          );
          if (_isViewerCity(
            state,
            defenderCity,
            viewerPlayerId: viewerPlayerId,
          )) {
            effects.insert(
              0,
              SmoothCameraEffect(
                col: defenderCity.center.col,
                row: defenderCity.center.row,
                duration: 0.36,
              ),
            );
            if (defenderCityVisible) {
              effects.add(
                SpawnParticleBurstEffect(
                  kind: ParticleBurstKind.cityAttacked,
                  col: defenderCity.center.col,
                  row: defenderCity.center.row,
                  colorValue: _damageTextColor,
                ),
              );
            }
          }
          if (defenderCityVisible) {
            effects.add(_cityDamageTextEffect(defenderCity, defenderDamage));
          }
        }
      }
    }

    if (attackerDamage > 0) {
      if (attacker != null &&
          _canRenderTransientAt(
            state,
            attacker.col,
            attacker.row,
            viewerPlayerId: viewerPlayerId,
          )) {
        effects.add(_damageTextEffect(attacker, attackerDamage));
      }
    }

    return effects;
  }

  static ShowFloatingTextEffect _damageTextEffect(GameUnit unit, int damage) {
    return ShowFloatingTextEffect(
      text: '-$damage HP',
      col: unit.col,
      row: unit.row,
      colorValue: _damageTextColor,
    );
  }

  static ShowCombatHexAlertEffect _combatHexAlertEffect({
    required String id,
    required String ownerPlayerId,
    required int col,
    required int row,
    required CombatHexAlertKind kind,
    required GameState state,
    required int? turn,
    String? unitId,
    String? cityId,
  }) {
    return ShowCombatHexAlertEffect(
      id: id,
      unitId: unitId,
      cityId: cityId,
      ownerPlayerId: ownerPlayerId,
      col: col,
      row: row,
      kind: kind,
      turn: turn,
      ownerSubmittedAtAttack: state.submittedPlayerIds.contains(ownerPlayerId),
    );
  }

  static ShowFloatingTextEffect _cityDamageTextEffect(
    GameCity city,
    int damage,
  ) {
    return ShowFloatingTextEffect(
      text: '-$damage HP',
      col: city.center.col,
      row: city.center.row,
      colorValue: _damageTextColor,
    );
  }

  static RendererEffect? _workerCompletedJobEffect(
    GameState state,
    GameState? previousState,
    String unitId, {
    AppLocalizations? l10n,
    String? viewerPlayerId,
  }) {
    if (previousState == null) return null;
    final job = _unitById(previousState, unitId)?.workerJob;
    if (job == null) return null;
    final yieldLabel = _yieldLabelFor(job.improvementType, l10n: l10n);
    if (yieldLabel == null && l10n == null) return null;
    if (!_canRenderTransientAt(
      state,
      job.targetHex.col,
      job.targetHex.row,
      viewerPlayerId: viewerPlayerId,
    )) {
      return null;
    }
    final label =
        yieldLabel ??
        '+${GameDisplayNames.fieldImprovement(l10n!, job.improvementType)}';
    return ShowFloatingTextEffect(
      text: label,
      col: job.targetHex.col,
      row: job.targetHex.row,
      colorValue: 0xFF86EFAC,
    );
  }

  static RendererEffect? _cityFoundedEffect(
    GameState state,
    String cityId,
    String ownerPlayerId, {
    String? viewerPlayerId,
  }) {
    final city = _cityById(state, cityId);
    if (city == null) return null;
    if (!_canRenderTransientAt(
      state,
      city.center.col,
      city.center.row,
      viewerPlayerId: viewerPlayerId,
    )) {
      return null;
    }
    return SpawnParticleBurstEffect(
      kind: ParticleBurstKind.cityFounded,
      col: city.center.col,
      row: city.center.row,
      colorValue: _colorForPlayer(state, ownerPlayerId),
    );
  }

  static RendererEffect? _cityProducedUnitEffect(
    GameState state,
    String cityId, {
    String? viewerPlayerId,
  }) {
    final city = _cityById(state, cityId);
    if (city == null) return null;
    if (!_canRenderTransientAt(
      state,
      city.center.col,
      city.center.row,
      viewerPlayerId: viewerPlayerId,
    )) {
      return null;
    }
    return SpawnParticleBurstEffect(
      kind: ParticleBurstKind.unitProduced,
      col: city.center.col,
      row: city.center.row,
      colorValue: _colorForPlayer(state, city.ownerPlayerId),
    );
  }

  static RendererEffect? _claimedHexEffect(
    GameState state,
    String cityId,
    int col,
    int row, {
    String? viewerPlayerId,
  }) {
    final city = _cityById(state, cityId);
    if (city == null) return null;
    if (!_canRenderTransientAt(
      state,
      col,
      row,
      viewerPlayerId: viewerPlayerId,
    )) {
      return null;
    }
    return SpawnParticleBurstEffect(
      kind: ParticleBurstKind.hexClaimed,
      col: col,
      row: row,
      colorValue: _colorForPlayer(state, city.ownerPlayerId),
    );
  }

  static List<RendererEffect> _unitKilledEffects(
    GameState state,
    GameState? previousState,
    String unitId,
    String ownerPlayerId, {
    String? viewerPlayerId,
  }) {
    final unit =
        _unitById(previousState ?? state, unitId) ?? _unitById(state, unitId);
    if (unit == null) return const [];
    if (!_canRenderTransientAt(
      state,
      unit.col,
      unit.row,
      viewerPlayerId: viewerPlayerId,
    )) {
      return const [];
    }
    return [
      SpawnParticleBurstEffect(
        kind: ParticleBurstKind.unitKilled,
        col: unit.col,
        row: unit.row,
        colorValue: _colorForPlayer(state, ownerPlayerId),
      ),
      ShowFloatingTextEffect(
        text: 'KO',
        col: unit.col,
        row: unit.row,
        colorValue: _damageTextColor,
        delay: _combatResultCueDelay,
      ),
    ];
  }

  static RendererEffect? _technologyResearchedEffect(
    GameState state,
    String playerId, {
    String? viewerPlayerId,
  }) {
    final anchor = _playerAnchor(state, playerId);
    if (anchor == null) return null;
    if (!_canRenderTransientAt(
      state,
      anchor.col,
      anchor.row,
      viewerPlayerId: viewerPlayerId,
    )) {
      return null;
    }
    return SpawnParticleBurstEffect(
      kind: ParticleBurstKind.technologyResearched,
      col: anchor.col,
      row: anchor.row,
      colorValue: _colorForPlayer(state, playerId),
    );
  }

  static ({int col, int row})? _playerAnchor(GameState state, String playerId) {
    for (final city in state.cities) {
      if (city.ownerPlayerId == playerId) {
        return (col: city.center.col, row: city.center.row);
      }
    }
    for (final unit in state.units) {
      if (unit.ownerPlayerId == playerId) {
        return (col: unit.col, row: unit.row);
      }
    }
    return null;
  }

  static GameUnit? _unitById(GameState state, String unitId) {
    for (final unit in state.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  static GameCity? _cityById(GameState state, String cityId) {
    for (final city in state.cities) {
      if (city.id == cityId) return city;
    }
    return null;
  }

  static bool _isViewerCity(
    GameState state,
    GameCity city, {
    String? viewerPlayerId,
  }) {
    final playerId = viewerPlayerId ?? state.activePlayerId;
    return playerId.isNotEmpty && city.ownerPlayerId == playerId;
  }

  static bool _canRenderTransientAt(
    GameState state,
    int col,
    int row, {
    String? viewerPlayerId,
  }) {
    return MapFocusVisibility.canRenderTransientAt(
      state,
      col,
      row,
      viewerPlayerId: viewerPlayerId,
    );
  }

  static int _colorForPlayer(GameState state, String playerId) {
    return PlayerColorTheme.resolveValue(
      state.colorForPlayer(playerId) ?? Player.palette.first,
    );
  }

  static String? _yieldLabelFor(
    FieldImprovementType improvementType, {
    AppLocalizations? l10n,
  }) {
    final yield = FieldImprovementCatalog.standard[improvementType]?.tileYield;
    if (yield == null) return null;
    final foodLabel = _localizedYieldLabel(
      l10n,
      (value) => value.yieldFoodShort,
    );
    final productionLabel = _localizedYieldLabel(
      l10n,
      (value) => value.yieldProductionShort,
    );
    final goldLabel = _localizedYieldLabel(
      l10n,
      (value) => value.yieldGoldShort,
    );
    final defenseLabel = _localizedYieldLabel(
      l10n,
      (value) => value.yieldDefenseShort,
    );
    final parts = [
      if (yield.food > 0) _yieldPart(yield.food, foodLabel),
      if (yield.production > 0) _yieldPart(yield.production, productionLabel),
      if (yield.gold > 0) _yieldPart(yield.gold, goldLabel),
      if (yield.defense > 0) _yieldPart(yield.defense, defenseLabel),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static String _yieldPart(int value, String? label) {
    if (label == null || label.isEmpty) return '+$value';
    return '+$value $label';
  }

  static String? _localizedYieldLabel(
    AppLocalizations? l10n,
    String Function(AppLocalizations value) labelFor,
  ) {
    return switch (l10n) {
      final AppLocalizations value => labelFor(value),
      null => null,
    };
  }
}
