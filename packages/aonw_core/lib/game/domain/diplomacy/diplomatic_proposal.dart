import 'package:aonw_core/game/domain/diplomacy/diplomacy_primitives.dart';
import 'package:aonw_core/util/wire_json.dart';

final class DiplomaticProposal {
  const DiplomaticProposal({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.kind,
    required this.createdTurn,
    required this.expiresOnTurn,
    this.goldPayment = 0,
  });

  factory DiplomaticProposal.fromJson(Map<String, dynamic> json) {
    return DiplomaticProposal(
      id: requiredStringValue(json['id'], 'id'),
      fromPlayerId: requiredStringValue(json['fromPlayerId'], 'fromPlayerId'),
      toPlayerId: requiredStringValue(json['toPlayerId'], 'toPlayerId'),
      kind: enumByName(
        json['kind'],
        DiplomaticProposalKind.values,
        'DiplomaticProposal.kind',
      ),
      createdTurn: requiredNonNegativeIntValue(
        json['createdTurn'],
        'createdTurn',
      ),
      expiresOnTurn: requiredNonNegativeIntValue(
        json['expiresOnTurn'],
        'expiresOnTurn',
      ),
      goldPayment:
          optionalNonNegativeIntValue(json['goldPayment'], 'goldPayment') ?? 0,
    );
  }

  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticProposalKind kind;
  final int createdTurn;
  final int expiresOnTurn;
  final int goldPayment;

  bool involves(String playerId) =>
      fromPlayerId == playerId || toPlayerId == playerId;

  bool isExpired(int turn) => turn >= expiresOnTurn;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromPlayerId': fromPlayerId,
    'toPlayerId': toPlayerId,
    'kind': kind.name,
    'createdTurn': createdTurn,
    'expiresOnTurn': expiresOnTurn,
    if (goldPayment > 0) 'goldPayment': goldPayment,
  };

  @override
  bool operator ==(Object other) =>
      other is DiplomaticProposal &&
      other.id == id &&
      other.fromPlayerId == fromPlayerId &&
      other.toPlayerId == toPlayerId &&
      other.kind == kind &&
      other.createdTurn == createdTurn &&
      other.expiresOnTurn == expiresOnTurn &&
      other.goldPayment == goldPayment;

  @override
  int get hashCode => Object.hash(
    DiplomaticProposal,
    id,
    fromPlayerId,
    toPlayerId,
    kind,
    createdTurn,
    expiresOnTurn,
    goldPayment,
  );
}
