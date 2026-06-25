part of 'diplomacy_state.dart';

final class DiplomaticProposal {
  const DiplomaticProposal({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.kind,
    required this.createdTurn,
    required this.expiresOnTurn,
  });

  factory DiplomaticProposal.fromJson(Map<String, dynamic> json) {
    return DiplomaticProposal(
      id: _requiredString(json, 'id'),
      fromPlayerId: _requiredString(json, 'fromPlayerId'),
      toPlayerId: _requiredString(json, 'toPlayerId'),
      kind: _enumValue(
        json['kind'],
        DiplomaticProposalKind.values,
        'DiplomaticProposal.kind',
      ),
      createdTurn: _requiredNonNegativeInt(json['createdTurn'], 'createdTurn'),
      expiresOnTurn: _requiredNonNegativeInt(
        json['expiresOnTurn'],
        'expiresOnTurn',
      ),
    );
  }

  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticProposalKind kind;
  final int createdTurn;
  final int expiresOnTurn;

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
  };

  @override
  bool operator ==(Object other) =>
      other is DiplomaticProposal &&
      other.id == id &&
      other.fromPlayerId == fromPlayerId &&
      other.toPlayerId == toPlayerId &&
      other.kind == kind &&
      other.createdTurn == createdTurn &&
      other.expiresOnTurn == expiresOnTurn;

  @override
  int get hashCode => Object.hash(
    DiplomaticProposal,
    id,
    fromPlayerId,
    toPlayerId,
    kind,
    createdTurn,
    expiresOnTurn,
  );
}
