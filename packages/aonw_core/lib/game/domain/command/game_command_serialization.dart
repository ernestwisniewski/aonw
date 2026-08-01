import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat/city_conquest_action.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/util/wire_json.dart';

part 'game_command_json_decoding.dart';
part 'game_command_json_encoding.dart';

/// JSON codec for the authoritative [DomainCommand] hierarchy.
///
/// Client-only [GameIntent] values have no entry point at this boundary.
abstract final class DomainCommandCodec {
  /// Serializes [command] with a stable `type` discriminator.
  static Map<String, dynamic> toJson(DomainCommand command) =>
      _encodeDomainCommand(command);

  /// Deserializes an authoritative command from its wire representation.
  static DomainCommand fromJson(Map<String, dynamic> json) =>
      _decodeDomainCommand(json);
}
