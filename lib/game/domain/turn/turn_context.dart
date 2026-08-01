import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'turn_context.freezed.dart';

@freezed
abstract class TurnContext with _$TurnContext {
  const TurnContext._();

  const factory TurnContext({
    required GameClientState state,
    GameSave? save,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
    required String playerId,
    DateTime? savedAt,
    @Default(<GameEvent>[]) List<GameEvent> events,
    @Default(<UiEffect>[]) List<UiEffect> uiEffects,
    @Default(ScienceYieldBreakdown.empty) ScienceYieldBreakdown bonusScience,
  }) = _TurnContext;
}
