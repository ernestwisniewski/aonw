import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';

class TurnContext {
  final GameState state;
  final GameSave? save;
  final MapData mapData;
  final GameRuleset ruleset;
  final String playerId;
  final DateTime? savedAt;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;
  final ScienceYieldBreakdown bonusScience;

  const TurnContext({
    required this.state,
    required this.mapData,
    required this.ruleset,
    required this.playerId,
    this.save,
    this.savedAt,
    this.events = const [],
    this.uiEffects = const [],
    this.bonusScience = ScienceYieldBreakdown.empty,
  });

  TurnContext copyWith({
    GameState? state,
    GameSave? save,
    MapData? mapData,
    GameRuleset? ruleset,
    String? playerId,
    DateTime? savedAt,
    List<GameEvent>? events,
    List<UiEffect>? uiEffects,
    ScienceYieldBreakdown? bonusScience,
  }) {
    return TurnContext(
      state: state ?? this.state,
      save: save ?? this.save,
      mapData: mapData ?? this.mapData,
      ruleset: ruleset ?? this.ruleset,
      playerId: playerId ?? this.playerId,
      savedAt: savedAt ?? this.savedAt,
      events: events ?? this.events,
      uiEffects: uiEffects ?? this.uiEffects,
      bonusScience: bonusScience ?? this.bonusScience,
    );
  }
}
