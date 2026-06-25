part of 'diplomacy_player_modal.dart';

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.l10n,
    required this.relation,
    required this.activePlayerId,
    required this.targetPlayerId,
    required this.onCommand,
  });

  final AppLocalizations l10n;
  final DiplomaticRelation relation;
  final String activePlayerId;
  final String targetPlayerId;
  final Future<void> Function(GameCommand command) onCommand;

  @override
  Widget build(BuildContext context) {
    final truceBlocksWar =
        relation.status == DiplomaticRelationStatus.truce &&
        relation.statusExpiresOnTurn != null;
    return _Section(
      title: l10n.diplomacyActionsTitle,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          EpicButton.outlined(
            label: l10n.diplomacySendFriendship,
            icon: Icons.handshake_outlined,
            onPressed: relation.status == DiplomaticRelationStatus.war
                ? null
                : () => unawaited(
                    onCommand(
                      SendDiplomaticProposalCommand(
                        playerId: activePlayerId,
                        targetPlayerId: targetPlayerId,
                        kind: DiplomaticProposalKind.friendship,
                      ),
                    ),
                  ),
          ),
          EpicButton.outlined(
            label: l10n.diplomacySendTruce,
            icon: Icons.hourglass_bottom_outlined,
            onPressed:
                relation.status == DiplomaticRelationStatus.friendly ||
                    relation.status == DiplomaticRelationStatus.truce
                ? null
                : () => unawaited(
                    onCommand(
                      SendDiplomaticProposalCommand(
                        playerId: activePlayerId,
                        targetPlayerId: targetPlayerId,
                        kind: DiplomaticProposalKind.truce,
                      ),
                    ),
                  ),
          ),
          EpicButton.outlined(
            label: l10n.diplomacyDeclareWar,
            icon: Icons.gavel_outlined,
            onPressed:
                truceBlocksWar ||
                    relation.status == DiplomaticRelationStatus.war
                ? null
                : () => unawaited(
                    onCommand(
                      DeclareWarCommand(
                        playerId: activePlayerId,
                        targetPlayerId: targetPlayerId,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
