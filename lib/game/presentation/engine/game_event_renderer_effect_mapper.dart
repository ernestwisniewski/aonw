import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_event_renderer_combat_effects.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/services/map_focus_visibility.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city/field_improvement_catalog.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';

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
    return switch (GameEventDescriptor.forEvent(event).rendererEffectKind) {
      GameEventRendererEffectKind.unitMoved =>
        skipUnitMoveIds.contains((event as UnitMovedEvent).unitId) ||
                (event.fromCol == event.toCol && event.fromRow == event.toRow)
            ? const []
            : [
                AnimateUnitMoveEffect(
                  unitId: event.unitId,
                  fromCol: event.fromCol,
                  fromRow: event.fromRow,
                  steps: [
                    UnitMovementStep(
                      col: event.toCol,
                      row: event.toRow,
                      enterCost: 0,
                      cumulativeCost: 0,
                    ),
                  ],
                ),
              ],
      GameEventRendererEffectKind.cityFounded => _single(
        _cityFoundedEffect(
          state,
          (event as CityFoundedEvent).cityId,
          event.ownerPlayerId,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.cityProducedUnit => _single(
        _cityProducedUnitEffect(
          state,
          (event as CityProducedUnitEvent).cityId,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.cityClaimedHex => _single(
        _claimedHexEffect(
          state,
          (event as CityClaimedHexEvent).cityId,
          event.col,
          event.row,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.unitKilled => _unitKilledEffects(
        state,
        previousState,
        (event as UnitKilledEvent).unitId,
        event.ownerPlayerId,
        viewerPlayerId: viewerPlayerId,
      ),
      GameEventRendererEffectKind.unitRetreated =>
        _canRenderTransientAt(
              state,
              (event as UnitRetreatedEvent).toCol,
              event.toRow,
              viewerPlayerId: viewerPlayerId,
            )
            ? [
                ShowFloatingTextEffect(
                  text: localizations == null
                      ? '↩'
                      : localizations.modeBannerAttackRetreatProgress,
                  col: event.toCol,
                  row: event.toRow,
                  colorValue: _combatCueColor,
                  delay: _combatResultCueDelay,
                ),
              ]
            : const [],
      GameEventRendererEffectKind.combatResolved =>
        GameEventRendererCombatEffects.combatResolvedEffects(
          state,
          previousState,
          event as CombatResolvedEvent,
          viewerPlayerId: viewerPlayerId,
          turn: turn,
        ),
      GameEventRendererEffectKind.workerCompletedJob => _single(
        _workerCompletedJobEffect(
          state,
          previousState,
          (event as WorkerCompletedJobEvent).unitId,
          l10n: l10n,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.technologyResearched => _single(
        _technologyResearchedEffect(
          state,
          (event as TechnologyResearchedEvent).playerId,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.none => const [],
    };
  }

  static List<RendererEffect> _single(RendererEffect? effect) {
    return effect == null ? const [] : [effect];
  }

  static RendererEffect? _workerCompletedJobEffect(
    GameState state,
    GameState? previousState,
    String unitId, {
    AppLocalizations? l10n,
    String? viewerPlayerId,
  }) {
    if (previousState == null) return null;
    final job = previousState.unitById(unitId)?.workerJob;
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
    final city = state.cityById(cityId);
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
    final city = state.cityById(cityId);
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
    final city = state.cityById(cityId);
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
        (previousState ?? state).unitById(unitId) ?? state.unitById(unitId);
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
