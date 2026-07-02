import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/stability/stability_band.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'city_events.dart';
part 'combat_events.dart';
part 'unit_events.dart';
part 'turn_events.dart';
part 'research_events.dart';
part 'resource_events.dart';
part 'objective_events.dart';
part 'system_events.dart';
part 'diplomacy_events.dart';
part 'stability_events.dart';

sealed class GameEvent {
  const GameEvent();
}
