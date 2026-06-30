import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('DiplomacyAiPolicy', () {
    test('warns a contacted player threatening a city', () {
      final view = _view(
        diplomacy: DiplomacyState.empty.addContact('ai', 'rival'),
        pendingCityAttackThreats: const [
          PendingCityAttackThreat(
            attackerPlayerId: 'rival',
            attackerUnitId: 'rival_warrior',
            attackerHex: HexCoordinate(col: 1, row: 0),
            cityId: 'ai_city',
            cityCenter: CityHex(col: 0, row: 0),
          ),
        ],
      );

      final commands = const DiplomacyAiPolicy().commandsFor(view, _context());

      expect(commands, [
        const SendDiplomaticMessageCommand(
          playerId: 'ai',
          targetPlayerId: 'rival',
          topic: DiplomaticMessageTopic.troopsNearCities,
        ),
      ]);
    });

    test('complains when a rival city is too close', () {
      final view = _view(
        diplomacy: DiplomacyState.empty.addContact('ai', 'rival'),
        rememberedEnemyCities: const [
          GameCity(
            id: 'rival_city',
            ownerPlayerId: 'rival',
            name: 'Forward',
            center: CityHex(col: 2, row: 0),
          ),
        ],
      );

      final commands = const DiplomacyAiPolicy().commandsFor(view, _context());

      expect(commands, [
        const SendDiplomaticMessageCommand(
          playerId: 'ai',
          targetPlayerId: 'rival',
          topic: DiplomaticMessageTopic.citiesTooClose,
        ),
      ]);
    });

    test('respects outgoing message category cooldown', () {
      final diplomacy = DiplomacyState.empty
          .addContact('ai', 'rival')
          .addMessage(
            DiplomaticMessage.create(
              id: 'message_1',
              fromPlayerId: 'ai',
              toPlayerId: 'rival',
              topic: DiplomaticMessageTopic.troopsNearCities,
              createdTurn: 10,
              expiresOnTurn: 15,
            ),
          );
      final view = _view(
        diplomacy: diplomacy,
        pendingCityAttackThreats: const [
          PendingCityAttackThreat(
            attackerPlayerId: 'rival',
            attackerUnitId: 'rival_warrior',
            attackerHex: HexCoordinate(col: 1, row: 0),
            cityId: 'ai_city',
            cityCenter: CityHex(col: 0, row: 0),
          ),
        ],
      );

      final commands = const DiplomacyAiPolicy().commandsFor(view, _context());

      expect(commands, isEmpty);
    });
  });
}

GameView _view({
  required DiplomacyState diplomacy,
  List<GameCity> rememberedEnemyCities = const [],
  List<PendingCityAttackThreat> pendingCityAttackThreats = const [],
}) {
  return GameView(
    forPlayerId: 'ai',
    turn: 12,
    ownUnits: const [],
    ownCities: const [
      GameCity(
        id: 'ai_city',
        ownerPlayerId: 'ai',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      ),
    ],
    ownResearch: PlayerResearchState.empty,
    ownImprovements: const [],
    diplomacy: diplomacy,
    visibleEnemyUnits: const [],
    rememberedEnemyCities: rememberedEnemyCities,
    pendingCityAttackThreats: pendingCityAttackThreats,
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: _map(),
    ruleset: GameRuleset.defaults,
  );
}

AiContext _context() {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _map(),
    turn: 12,
    rng: AiRng(1),
  );
}

MapData _map() {
  return MapData(
    cols: 4,
    rows: 4,
    tiles: [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
