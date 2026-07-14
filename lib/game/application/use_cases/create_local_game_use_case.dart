import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';

final class InvalidLocalGameMapException implements Exception {
  final MapValidationResult validation;

  const InvalidLocalGameMapException(this.validation);

  @override
  String toString() =>
      'InvalidLocalGameMapException(${validation.errors.length} errors)';
}

/// Creates a local game without exposing persistence request assembly to UI.
class CreateLocalGameUseCase {
  final GameRepository repository;
  final Clock clock;

  const CreateLocalGameUseCase({required this.repository, required this.clock});

  String defaultNameFor(MapSelection selection) {
    return repository.defaultSaveName(selection.displayName, clock.now());
  }

  Future<String> execute({
    required MapSelection selection,
    required MapData mapData,
    required GameMode gameMode,
    required MatchRules matchRules,
    required List<Player> players,
    String? name,
    int? startPositionSeed,
  }) {
    final validation = MapValidator.validate(
      mapData: mapData,
      playerCount: players.length,
      gameLength: matchRules.gameLength,
    );
    if (!validation.isValid) {
      throw InvalidLocalGameMapException(validation);
    }
    final requestedName = name?.trim() ?? '';
    return repository.create(
      NewGameRequest(
        name: requestedName.isEmpty ? defaultNameFor(selection) : requestedName,
        mapName: selection.name,
        mapSource: selection.source,
        gameMode: gameMode,
        matchRules: matchRules,
        players: players,
        mapData: mapData,
        startPositionSeed: startPositionSeed,
      ),
    );
  }
}
