import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('DiplomacyState', () {
    test('defaults missing player pairs to neutral', () {
      const diplomacy = DiplomacyState.empty;

      expect(
        diplomacy.statusBetween('player_1', 'player_2'),
        DiplomaticRelationStatus.neutral,
      );
    });

    test('can record an explicit neutral relation', () {
      final diplomacy = DiplomacyState.empty.setStatus(
        'player_1',
        'player_2',
        DiplomaticRelationStatus.neutral,
        turn: 2,
        reason: DiplomaticRelationChangeReason.manual,
      );
      final relation = diplomacy.relationBetween('player_1', 'player_2');

      expect(relation.status, DiplomaticRelationStatus.neutral);
      expect(relation.lastChangedTurn, 2);
      expect(relation.lastChangeReason, DiplomaticRelationChangeReason.manual);
      expect(
        diplomacy.relations,
        contains(DiplomacyState.relationKey('player_1', 'player_2')),
      );
    });

    test('unit attacks escalate neutral relations to hostile', () {
      final diplomacy = DiplomacyState.empty.registerUnitAttack(
        attackerPlayerId: 'player_1',
        defenderPlayerId: 'player_2',
        turn: 4,
      );
      final relation = diplomacy.relationBetween('player_2', 'player_1');

      expect(relation.status, DiplomaticRelationStatus.hostile);
      expect(relation.lastChangedTurn, 4);
      expect(
        relation.lastChangeReason,
        DiplomaticRelationChangeReason.unitAttack,
      );
    });

    test('derives attitude from relation score thresholds', () {
      final diplomacy = DiplomacyState.empty
          .adjustRelationScore(
            'player_1',
            'player_2',
            40,
            turn: 2,
            reason: DiplomaticScoreChangeReason.manual,
          )
          .adjustRelationScore(
            'player_1',
            'player_3',
            -40,
            turn: 2,
            reason: DiplomaticScoreChangeReason.manual,
          );

      expect(
        diplomacy.scoreStatusBetween('player_1', 'player_2'),
        DiplomaticRelationStatus.friendly,
      );
      expect(
        diplomacy.scoreStatusBetween('player_1', 'player_3'),
        DiplomaticRelationStatus.hostile,
      );
      expect(
        diplomacy.scoreStatusBetween('player_2', 'player_3'),
        DiplomaticRelationStatus.neutral,
      );
    });

    test('applies warmonger penalty to contacts who know both sides', () {
      final diplomacy = DiplomacyState.empty
          .addContact('player_1', 'player_2')
          .addContact('player_1', 'player_3')
          .addContact('player_2', 'player_3')
          .addContact('player_1', 'player_4');

      final result = DiplomaticWarmongerReputation.apply(
        diplomacy: diplomacy,
        aggressorPlayerId: 'player_1',
        victimPlayerId: 'player_2',
        action: DiplomaticWarmongerAction.declarationOfWar,
        turn: 6,
      );

      expect(
        result.diplomacy.relationScoreBetween('player_1', 'player_3'),
        DiplomaticWarmongerReputation.declarationOfWarPenalty,
      );
      expect(result.diplomacy.relationScoreBetween('player_1', 'player_4'), 0);
      expect(
        result.entries.single.reason,
        DiplomaticScoreChangeReason.warmongerPenalty,
      );
    });

    test('round-trips discovered contacts through json', () {
      final diplomacy = DiplomacyState.empty.addContact('player_2', 'player_1');
      final json = diplomacy.toJson();
      final restored = DiplomacyState.fromJson(json);

      expect(json['contacts'], [
        DiplomacyState.relationKey('player_1', 'player_2'),
      ]);
      expect(restored.hasContact('player_1', 'player_2'), isTrue);
      expect(restored, diplomacy);
    });

    test('round-trips proposals messages and score history through json', () {
      final message =
          DiplomaticMessage.create(
            id: 'message_1',
            fromPlayerId: 'player_1',
            toPlayerId: 'player_2',
            topic: DiplomaticMessageTopic.withdrawScouts,
            createdTurn: 4,
            expiresOnTurn: 9,
          ).copyWith(
            response: DiplomaticMessageResponse.conciliatory,
            respondedTurn: 5,
            relationScoreDelta: 12,
            relationScoreAfter: 12,
            promiseDueTurn: 8,
          );
      final diplomacy = DiplomacyState.empty
          .addProposal(
            const DiplomaticProposal(
              id: 'proposal_1',
              fromPlayerId: 'player_2',
              toPlayerId: 'player_1',
              kind: DiplomaticProposalKind.truce,
              createdTurn: 3,
              expiresOnTurn: 8,
            ),
          )
          .addMessage(message)
          .adjustRelationScore(
            'player_2',
            'player_1',
            12,
            turn: 5,
            reason: DiplomaticScoreChangeReason.messageResponse,
            sourceId: 'message_1',
          );

      final restored = DiplomacyState.fromJson(diplomacy.toJson());

      expect(restored, diplomacy);
      expect(restored.proposalsFor('player_1'), hasLength(1));
      expect(restored.messagesBetween('player_1', 'player_2').single, message);
      expect(
        restored.scoreEntriesBetween('player_1', 'player_2'),
        hasLength(1),
      );
    });

    test(
      'city attacks escalate relations to war without downgrading later',
      () {
        final diplomacy = DiplomacyState.empty
            .registerCityAttack(
              attackerPlayerId: 'player_1',
              defenderPlayerId: 'player_2',
              turn: 5,
            )
            .registerUnitAttack(
              attackerPlayerId: 'player_2',
              defenderPlayerId: 'player_1',
              turn: 6,
            );

        expect(
          diplomacy.statusBetween('player_1', 'player_2'),
          DiplomaticRelationStatus.war,
        );
        expect(
          diplomacy.relationBetween('player_1', 'player_2').lastChangeReason,
          DiplomaticRelationChangeReason.cityAttack,
        );
      },
    );

    test('round-trips relations through json with stable ordering', () {
      final diplomacy = DiplomacyState.empty
          .setStatus(
            'player_3',
            'player_1',
            DiplomaticRelationStatus.friendly,
            turn: 2,
            reason: DiplomaticRelationChangeReason.manual,
          )
          .registerCityAttack(
            attackerPlayerId: 'player_1',
            defenderPlayerId: 'player_2',
            turn: 3,
          );

      final json = diplomacy.toJson();
      final restored = DiplomacyState.fromJson(json);

      expect(restored, diplomacy);
      expect(
        (json['relations'] as List)
            .cast<Map<String, dynamic>>()
            .map(
              (relation) => '${relation['playerAId']}:${relation['playerBId']}',
            )
            .toList(),
        ['player_1:player_2', 'player_1:player_3'],
      );
    });
  });
}
