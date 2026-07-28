import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/wire_player_domain_mapper.dart';
import 'package:test/test.dart';

void main() {
  test('maps human and AI roster entries into canonical participants', () {
    const human = WirePlayer(
      id: 'human-id',
      userId: 'private-human-user',
      name: 'Human',
      colorValue: 101,
      country: PlayerCountry.france,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.reconnecting,
      ready: true,
    );
    const ai = WirePlayer(
      id: 'ai-id',
      userId: 'private-ai-user',
      name: 'Sentinel AI',
      colorValue: 202,
      country: PlayerCountry.japan,
      kind: WirePlayerKind.ai,
      connectionState: WirePlayerConnectionState.offline,
      ready: false,
      ai: WireAiPlayer(
        strategyId: AiStrategyId.mcts,
        difficulty: AiDifficulty.veryHard,
        persona: AiPersona.scientific,
      ),
    );

    expect(
      domainPlayerFromWire(human),
      const Player(
        id: 'human-id',
        name: 'Human',
        colorValue: 101,
        country: PlayerCountry.france,
        kind: PlayerKind.human,
      ),
    );
    expect(
      domainPlayerFromWire(ai),
      Player(
        id: 'ai-id',
        name: 'Sentinel AI',
        colorValue: 202,
        country: PlayerCountry.japan,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.mcts,
          difficulty: AiDifficulty.veryHard,
          persona: AiPersona.scientific,
          seed: StartingPositionSeed.fromParts(const [
            'ai-id',
            'Sentinel AI',
            'japan',
          ]),
        ),
      ),
    );
  });
}
