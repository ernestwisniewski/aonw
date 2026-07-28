import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

/// Maps the authoritative server roster into one canonical domain participant.
Player domainPlayerFromWire(WirePlayer player) {
  return Player(
    id: player.id,
    name: player.name,
    colorValue: player.colorValue,
    country: player.country,
    kind: switch (player.kind) {
      WirePlayerKind.human => PlayerKind.human,
      WirePlayerKind.ai => PlayerKind.ai,
    },
    ai: player.ai == null
        ? null
        : AiPlayer(
            strategyId: player.ai!.strategyId,
            difficulty: player.ai!.difficulty,
            persona: player.ai!.persona,
            seed: StartingPositionSeed.fromParts([
              player.id,
              player.name,
              player.country.name,
            ]),
          ),
  );
}
