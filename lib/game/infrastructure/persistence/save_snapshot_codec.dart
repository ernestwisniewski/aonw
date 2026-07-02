import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/migrations/game_fog_of_war_state_migrator.dart';
import 'package:aonw/game/infrastructure/persistence/migrations/game_research_state_migrator.dart';
import 'package:aonw/game/infrastructure/persistence/migrations/game_runtime_state_migrator.dart';
import 'package:aonw/game/infrastructure/persistence/migrations/game_save_migrator.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';

abstract final class SaveSnapshotCodec {
  static Map<String, dynamic> toJson(SaveSnapshot snapshot) {
    return {
      'save': snapshot.save.toJson(),
      ...snapshot.persistentState.toJson(),
      'eventLogOffset': snapshot.eventLogOffset,
    };
  }

  static SaveSnapshot fromJson(Map<String, dynamic> json) {
    final rawPlayerColors =
        json['playerColors'] as Map<String, dynamic>? ?? const {};
    final rawPlayerCountries =
        json['playerCountries'] as Map<String, dynamic>? ?? const {};
    final rawPlayerGold =
        json['playerGold'] as Map<String, dynamic>? ?? const {};
    final rawPlayerWarWeariness =
        json['playerWarWeariness'] as Map<String, dynamic>? ?? const {};
    final rawPlayerStabilityNet =
        json['playerStabilityNet'] as Map<String, dynamic>? ?? const {};
    final rawUnits = json['units'] as List<dynamic>? ?? const <dynamic>[];
    final rawCities = json['cities'] as List<dynamic>? ?? const <dynamic>[];
    final rawArtifacts =
        json['artifacts'] as List<dynamic>? ?? const <dynamic>[];
    final rawFieldImprovements =
        json['fieldImprovements'] as List<dynamic>? ?? const <dynamic>[];

    final persistentState = PersistentGameState.fromJson({
      'playerColors': rawPlayerColors,
      'playerCountries': rawPlayerCountries,
      'playerGold': rawPlayerGold,
      'playerWarWeariness': rawPlayerWarWeariness,
      'playerStabilityNet': rawPlayerStabilityNet,
      'units': rawUnits,
      'cities': rawCities,
      'artifacts': rawArtifacts,
      'fieldImprovements': rawFieldImprovements,
      'fogOfWar': GameFogOfWarStateMigrator.migrate(json['fogOfWar']),
      'research': switch (json['research']) {
        final Map<String, dynamic> value => GameResearchStateMigrator.migrate(
          value,
        ),
        _ => ResearchState.empty.toJson(),
      },
      'runtimeState': switch (json['runtimeState']) {
        final Map<String, dynamic> value => GameRuntimeStateMigrator.migrate(
          value,
        ),
        _ => GameRuntimeState.empty.toJson(),
      },
    });

    return SaveSnapshot.fromPersistentState(
      save: GameSave.fromJson(
        GameSaveMigrator.migrate(json['save'] as Map<String, dynamic>),
      ),
      state: persistentState,
      eventLogOffset: json['eventLogOffset'] as int? ?? 0,
    );
  }
}
