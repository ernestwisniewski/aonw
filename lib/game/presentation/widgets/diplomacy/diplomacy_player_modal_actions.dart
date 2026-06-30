part of 'diplomacy_player_modal.dart';

class _ActionsSection extends StatelessWidget {
  static const int _recentHostilityTurns = 8;

  const _ActionsSection({
    required this.l10n,
    required this.gameState,
    required this.relation,
    required this.currentTurn,
    required this.activePlayerId,
    required this.targetPlayerId,
    required this.onCommand,
  });

  final AppLocalizations l10n;
  final GameState gameState;
  final DiplomaticRelation relation;
  final int currentTurn;
  final String activePlayerId;
  final String targetPlayerId;
  final Future<void> Function(GameCommand command) onCommand;

  @override
  Widget build(BuildContext context) {
    final truceBlocksWar =
        relation.status == DiplomaticRelationStatus.truce &&
        relation.statusExpiresOnTurn != null;
    final canProposeFriendship = _canProposeFriendship();
    final canProposeTruce = _canProposeTruce();
    final truceGoldPayment = _suggestedTruceGoldPayment();
    final goldGiftAmount = _suggestedGoldGiftAmount();
    final friendshipForecast = _proposalForecast(
      DiplomaticProposalKind.friendship,
    );
    final truceForecast = _proposalForecast(
      DiplomaticProposalKind.truce,
      goldPayment: truceGoldPayment,
    );
    return _Section(
      title: l10n.diplomacyActionsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              EpicButton.outlined(
                label: l10n.diplomacySendFriendship,
                icon: Icons.handshake_outlined,
                onPressed: !canProposeFriendship
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
                onPressed: !canProposeTruce
                    ? null
                    : () => unawaited(
                        onCommand(
                          SendDiplomaticProposalCommand(
                            playerId: activePlayerId,
                            targetPlayerId: targetPlayerId,
                            kind: DiplomaticProposalKind.truce,
                            goldPayment: truceGoldPayment,
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
              EpicButton.outlined(
                label: l10n.diplomacySendGoldGift,
                icon: Icons.redeem_outlined,
                onPressed: goldGiftAmount <= 0
                    ? null
                    : () => unawaited(
                        onCommand(
                          SendGoldGiftCommand(
                            playerId: activePlayerId,
                            targetPlayerId: targetPlayerId,
                            amount: goldGiftAmount,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ProposalForecastLine(
            l10n: l10n,
            kind: DiplomaticProposalKind.friendship,
            forecast: friendshipForecast,
          ),
          const SizedBox(height: 4),
          _ProposalForecastLine(
            l10n: l10n,
            kind: DiplomaticProposalKind.truce,
            forecast: truceForecast,
          ),
          if (truceGoldPayment > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.diplomacyTruceGoldPayment(truceGoldPayment),
              style: GameUiTheme.cardMeta.copyWith(
                color: GameUiTheme.goldLight,
              ),
            ),
          ],
          if (goldGiftAmount > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.diplomacyGoldGiftAmount(goldGiftAmount),
              style: GameUiTheme.cardMeta.copyWith(
                color: GameUiTheme.goldLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  DiplomaticProposalForecast _proposalForecast(
    DiplomaticProposalKind kind, {
    int goldPayment = 0,
  }) {
    return DiplomaticProposalForecast.evaluate(
      kind: kind,
      relation: relation,
      recentHostility: _recentAggression(activePlayerId, targetPlayerId) > 0,
      goldPayment: goldPayment,
    );
  }

  bool _canProposeFriendship() {
    return relation.status == DiplomaticRelationStatus.neutral ||
        relation.status == DiplomaticRelationStatus.hostile ||
        relation.status == DiplomaticRelationStatus.truce;
  }

  bool _canProposeTruce() {
    return relation.status == DiplomaticRelationStatus.hostile ||
        relation.status == DiplomaticRelationStatus.war;
  }

  int _suggestedTruceGoldPayment() {
    if (relation.status != DiplomaticRelationStatus.war) return 0;
    final availableGold = gameState.playerGold[activePlayerId] ?? 0;
    return availableGold >= DiplomaticProposalForecast.minimumTruceGoldPayment
        ? DiplomaticProposalForecast.minimumTruceGoldPayment
        : 0;
  }

  int _suggestedGoldGiftAmount() {
    if (relation.status == DiplomaticRelationStatus.war ||
        relation.status == DiplomaticRelationStatus.truce) {
      return 0;
    }
    final availableGold = gameState.playerGold[activePlayerId] ?? 0;
    if (availableGold < DiplomaticGoldGiftRules.minimumAmount) return 0;
    return math.min(10, availableGold);
  }

  int _recentAggression(String attackerId, String defenderId) {
    return gameState.diplomacy
        .scoreEntriesBetween(attackerId, defenderId)
        .where(_isRecentAggression)
        .length;
  }

  bool _isRecentAggression(DiplomaticScoreEntry entry) {
    if (currentTurn < entry.turn ||
        currentTurn - entry.turn >= _recentHostilityTurns) {
      return false;
    }
    return entry.reason == DiplomaticScoreChangeReason.unitAttack ||
        entry.reason == DiplomaticScoreChangeReason.cityAttack ||
        entry.reason == DiplomaticScoreChangeReason.declarationOfWar;
  }
}

class _ProposalForecastLine extends StatelessWidget {
  const _ProposalForecastLine({
    required this.l10n,
    required this.kind,
    required this.forecast,
  });

  final AppLocalizations l10n;
  final DiplomaticProposalKind kind;
  final DiplomaticProposalForecast forecast;

  @override
  Widget build(BuildContext context) {
    final outcome = forecast.accepted
        ? l10n.diplomacyProposalForecastAccepted
        : l10n.diplomacyProposalForecastRejected;
    final reasons = forecast.reasons
        .map((reason) => _reasonLabel(l10n, reason))
        .join(', ');
    return Text(
      l10n.diplomacyProposalForecastLine(
        _proposalLabel(l10n, kind),
        outcome,
        reasons,
      ),
      style: GameUiTheme.cardMeta.copyWith(
        color: forecast.accepted ? GameUiTheme.success : GameUiTheme.danger,
      ),
    );
  }

  String _reasonLabel(
    AppLocalizations l10n,
    DiplomaticProposalForecastReason reason,
  ) {
    return switch (reason) {
      DiplomaticProposalForecastReason.acceptableRelations =>
        l10n.diplomacyProposalForecastReasonAcceptableRelations,
      DiplomaticProposalForecastReason.activeWar =>
        l10n.diplomacyProposalForecastReasonActiveWar,
      DiplomaticProposalForecastReason.atWar =>
        l10n.diplomacyProposalForecastReasonAtWar,
      DiplomaticProposalForecastReason.goldPayment =>
        l10n.diplomacyProposalForecastReasonGoldPayment,
      DiplomaticProposalForecastReason.lowRelations =>
        l10n.diplomacyProposalForecastReasonLowRelations,
      DiplomaticProposalForecastReason.militaryPressure =>
        l10n.diplomacyProposalForecastReasonMilitaryPressure,
      DiplomaticProposalForecastReason.recentHostility =>
        l10n.diplomacyProposalForecastReasonRecentHostility,
    };
  }
}
