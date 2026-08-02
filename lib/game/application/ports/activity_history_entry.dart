import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';

class LoggedActivityEntry {
  const LoggedActivityEntry({
    required this.eventIndex,
    required this.playerId,
    required this.event,
    required this.context,
  });

  final int eventIndex;
  final String playerId;
  final GameEvent event;
  final GameActivityContext context;

  factory LoggedActivityEntry.fromJson(Map<String, dynamic> json) {
    return LoggedActivityEntry(
      eventIndex: json['eventIndex'] as int,
      playerId: json['playerId'] as String,
      event: GameEventSerializer.fromJson(
        Map<String, dynamic>.from(json['event'] as Map),
      ),
      context: GameActivityContext.fromJson(
        Map<String, dynamic>.from(json['context'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventIndex': eventIndex,
      'playerId': playerId,
      'event': GameEventSerializer.toJson(event),
      'context': context.toJson(),
    };
  }
}

class GameActivityContext {
  const GameActivityContext({
    required this.activePlayerId,
    required this.units,
    required this.cities,
  });

  final String activePlayerId;
  final Map<String, GameActivityUnitSnapshot> units;
  final Map<String, GameActivityCitySnapshot> cities;

  static const empty = GameActivityContext(
    activePlayerId: '',
    units: {},
    cities: {},
  );

  factory GameActivityContext.capture({
    required GameEvent event,
    required GameClientState state,
    GameClientState? previousState,
  }) {
    final descriptor = GameEventDescriptor.forEvent(event);
    final unitIds = descriptor.unitIds;
    final cityIds = descriptor.cityIds;
    final units = <String, GameActivityUnitSnapshot>{};
    final cities = <String, GameActivityCitySnapshot>{};

    for (final unitId in unitIds) {
      final unit = state.unitById(unitId) ?? previousState?.unitById(unitId);
      if (unit != null) {
        units[unitId] = GameActivityUnitSnapshot.fromUnit(unit);
      }
    }
    for (final cityId in cityIds) {
      final city = state.cityById(cityId) ?? previousState?.cityById(cityId);
      if (city != null) {
        cities[cityId] = GameActivityCitySnapshot.fromCity(city);
      }
    }

    return GameActivityContext(
      activePlayerId: state.activePlayerId,
      units: Map.unmodifiable(units),
      cities: Map.unmodifiable(cities),
    );
  }

  factory GameActivityContext.fromJson(Map<String, dynamic> json) {
    return GameActivityContext(
      activePlayerId: json['activePlayerId'] as String? ?? '',
      units: Map.unmodifiable(
        (json['units'] as Map<String, dynamic>? ?? const {}).map(
          (key, value) => MapEntry(
            key,
            GameActivityUnitSnapshot.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          ),
        ),
      ),
      cities: Map.unmodifiable(
        (json['cities'] as Map<String, dynamic>? ?? const {}).map(
          (key, value) => MapEntry(
            key,
            GameActivityCitySnapshot.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activePlayerId': activePlayerId,
      'units': units.map((key, value) => MapEntry(key, value.toJson())),
      'cities': cities.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class GameActivityUnitSnapshot {
  const GameActivityUnitSnapshot({
    required this.id,
    required this.ownerPlayerId,
    required this.type,
    required this.name,
  });

  final String id;
  final String ownerPlayerId;
  final GameUnitType type;
  final String name;

  factory GameActivityUnitSnapshot.fromUnit(GameUnit unit) {
    return GameActivityUnitSnapshot(
      id: unit.id,
      ownerPlayerId: unit.ownerPlayerId,
      type: unit.type,
      name: unit.name,
    );
  }

  factory GameActivityUnitSnapshot.fromJson(Map<String, dynamic> json) {
    return GameActivityUnitSnapshot(
      id: json['id'] as String,
      ownerPlayerId: json['ownerPlayerId'] as String,
      type: GameUnitType.values.byName(json['type'] as String),
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerPlayerId': ownerPlayerId,
      'type': type.name,
      'name': name,
    };
  }
}

class GameActivityCitySnapshot {
  const GameActivityCitySnapshot({
    required this.id,
    required this.ownerPlayerId,
    required this.name,
  });

  final String id;
  final String ownerPlayerId;
  final String name;

  factory GameActivityCitySnapshot.fromCity(GameCity city) {
    return GameActivityCitySnapshot(
      id: city.id,
      ownerPlayerId: city.ownerPlayerId,
      name: city.name,
    );
  }

  factory GameActivityCitySnapshot.fromJson(Map<String, dynamic> json) {
    return GameActivityCitySnapshot(
      id: json['id'] as String,
      ownerPlayerId: json['ownerPlayerId'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'ownerPlayerId': ownerPlayerId, 'name': name};
  }
}
