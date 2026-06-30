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

    test('backs common enemy messages when the war target is shared', () {
      final diplomacy = DiplomacyState.empty
          .addContact('ai', 'rival')
          .addContact('ai', 'enemy')
          .addContact('rival', 'enemy')
          .setStatus('ai', 'enemy', DiplomaticRelationStatus.war)
          .setStatus('rival', 'enemy', DiplomaticRelationStatus.war)
          .adjustRelationScore(
            'ai',
            'rival',
            -30,
            turn: 8,
            reason: DiplomaticScoreChangeReason.manual,
          )
          .addMessage(
            DiplomaticMessage.create(
              id: 'message_1',
              fromPlayerId: 'rival',
              toPlayerId: 'ai',
              topic: DiplomaticMessageTopic.commonEnemy,
              createdTurn: 11,
              expiresOnTurn: 16,
            ),
          );
      final view = _view(diplomacy: diplomacy);

      final commands = const DiplomacyAiPolicy().commandsFor(view, _context());

      expect(
        commands.first,
        const RespondDiplomaticMessageCommand(
          playerId: 'ai',
          messageId: 'message_1',
          response: DiplomaticMessageResponse.conciliatory,
        ),
      );
      expect(
        commands,
        contains(
          const SendDiplomaticMessageCommand(
            playerId: 'ai',
            targetPlayerId: 'rival',
            topic: DiplomaticMessageTopic.commonEnemy,
          ),
        ),
      );
    });

    test('requires pressure or payment for hostile truce offers', () {
      final baseDiplomacy = DiplomacyState.empty
          .setStatus('ai', 'rival', DiplomaticRelationStatus.war)
          .adjustRelationScore(
            'ai',
            'rival',
            -50,
            turn: 8,
            reason: DiplomaticScoreChangeReason.manual,
          );

      RespondDiplomaticProposalCommand responseFor(
        DiplomaticProposal proposal,
      ) {
        final view = _view(diplomacy: baseDiplomacy.addProposal(proposal));
        return const DiplomacyAiPolicy()
            .commandsFor(view, _context())
            .whereType<RespondDiplomaticProposalCommand>()
            .single;
      }

      expect(
        responseFor(
          const DiplomaticProposal(
            id: 'unpaid_truce',
            fromPlayerId: 'rival',
            toPlayerId: 'ai',
            kind: DiplomaticProposalKind.truce,
            createdTurn: 11,
            expiresOnTurn: 16,
          ),
        ),
        const RespondDiplomaticProposalCommand(
          playerId: 'ai',
          proposalId: 'unpaid_truce',
          accepted: false,
        ),
      );
      expect(
        responseFor(
          const DiplomaticProposal(
            id: 'paid_truce',
            fromPlayerId: 'rival',
            toPlayerId: 'ai',
            kind: DiplomaticProposalKind.truce,
            createdTurn: 11,
            expiresOnTurn: 16,
            goldPayment: DiplomaticProposalForecast.minimumTruceGoldPayment,
          ),
        ),
        const RespondDiplomaticProposalCommand(
          playerId: 'ai',
          proposalId: 'paid_truce',
          accepted: true,
        ),
      );
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
