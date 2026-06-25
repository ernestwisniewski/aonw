import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/diplomacy_history_presenter.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

part 'diplomacy_player_modal_actions.dart';
part 'diplomacy_player_modal_conversation.dart';
part 'diplomacy_player_modal_labels.dart';
part 'diplomacy_player_modal_overview.dart';
part 'diplomacy_player_modal_primitives.dart';
part 'diplomacy_player_modal_resource_offers.dart';
part 'diplomacy_player_modal_resource_trade.dart';

Future<void> showDiplomacyPlayerModal(
  BuildContext context, {
  required GameSave gameSave,
  required GameState gameState,
  required MapData mapData,
  required String activePlayerId,
  required String targetPlayerId,
  required Future<void> Function(GameCommand command) onCommand,
}) {
  return showGameModal<void>(
    context: context,
    size: GameModalSize.wide,
    builder: (dialogContext) => DiplomacyPlayerModal(
      gameSave: gameSave,
      gameState: gameState,
      mapData: mapData,
      activePlayerId: activePlayerId,
      targetPlayerId: targetPlayerId,
      onCommand: (command) async {
        await onCommand(command);
        if (dialogContext.mounted) {
          unawaited(Navigator.of(dialogContext).maybePop());
        }
      },
    ),
  );
}

class DiplomacyPlayerModal extends StatelessWidget {
  const DiplomacyPlayerModal({
    required this.gameSave,
    required this.gameState,
    required this.mapData,
    required this.activePlayerId,
    required this.targetPlayerId,
    required this.onCommand,
    super.key,
  });

  final GameSave gameSave;
  final GameState gameState;
  final MapData mapData;
  final String activePlayerId;
  final String targetPlayerId;
  final Future<void> Function(GameCommand command) onCommand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playerName = _playerName(l10n, targetPlayerId);
    final countryName = _playerCountryName(l10n, targetPlayerId);
    final relation = gameState.diplomacy.relationBetween(
      activePlayerId,
      targetPlayerId,
    );
    final statusLabel = MultiplayerRelationStatusStyle.label(
      l10n,
      relation.status,
    );

    return GameModalScaffold(
      surfaceKey: const Key('diplomacyPlayerModal.surface'),
      size: GameModalSize.wide,
      showCornerDiamonds: false,
      header: GameModalHeader(
        title: l10n.commonDiplomacy,
        subtitle: '$playerName · $countryName · $statusLabel',
        icon: Icons.handshake_outlined,
        onClose: () => Navigator.of(context).maybePop(),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final children = [
              _OverviewSection(
                relation: relation,
                scoreEntries: gameState.diplomacy.scoreEntriesBetween(
                  activePlayerId,
                  targetPlayerId,
                ),
                l10n: l10n,
                currentTurn: gameSave.turn,
              ),
              _StatsSection(
                l10n: l10n,
                gameState: gameState,
                activePlayerId: activePlayerId,
                targetPlayerId: targetPlayerId,
              ),
              _ProposalsSection(
                l10n: l10n,
                diplomacy: gameState.diplomacy,
                activePlayerId: activePlayerId,
                targetPlayerId: targetPlayerId,
                onCommand: onCommand,
              ),
              _ResourceTradeSection(
                l10n: l10n,
                gameState: gameState,
                mapData: mapData,
                relation: relation,
                activePlayerId: activePlayerId,
                targetPlayerId: targetPlayerId,
                onCommand: onCommand,
              ),
              _HistorySection(
                l10n: l10n,
                entries: gameState.diplomacy.scoreEntriesBetween(
                  activePlayerId,
                  targetPlayerId,
                ),
                messages: gameState.diplomacy.messagesBetween(
                  activePlayerId,
                  targetPlayerId,
                ),
                proposals: gameState.diplomacy
                    .proposalsFor(activePlayerId)
                    .where(
                      (proposal) =>
                          DiplomacyState.relationKey(
                            proposal.fromPlayerId,
                            proposal.toPlayerId,
                          ) ==
                          DiplomacyState.relationKey(
                            activePlayerId,
                            targetPlayerId,
                          ),
                    )
                    .toList(growable: false),
                playerNameFor: (playerId) => _playerName(l10n, playerId),
              ),
              _MessagesSection(
                l10n: l10n,
                diplomacy: gameState.diplomacy,
                activePlayerId: activePlayerId,
                targetPlayerId: targetPlayerId,
                onCommand: onCommand,
              ),
              _ActionsSection(
                l10n: l10n,
                relation: relation,
                activePlayerId: activePlayerId,
                targetPlayerId: targetPlayerId,
                onCommand: onCommand,
              ),
            ];
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _withGaps(children, vertical: true),
              );
            }
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: children[0]),
                    const SizedBox(width: 14),
                    Expanded(child: children[1]),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: children[2]),
                    const SizedBox(width: 14),
                    Expanded(child: children[3]),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: children[4]),
                    const SizedBox(width: 14),
                    Expanded(child: children[6]),
                  ],
                ),
                const SizedBox(height: 14),
                children[5],
              ],
            );
          },
        ),
      ),
    );
  }

  Player? _playerById(String playerId) {
    for (final player in gameSave.players) {
      if (player.id == playerId) return player;
    }
    return null;
  }

  String _playerName(AppLocalizations l10n, String playerId) {
    final player = _playerById(playerId);
    return player == null ? playerId : GameDisplayNames.player(l10n, player);
  }

  String _playerCountryName(AppLocalizations l10n, String playerId) {
    final player = _playerById(playerId);
    final country = player?.country ?? gameState.playerCountries[playerId];
    if (country == null) return playerId;
    return GameDisplayNames.playerCountry(l10n, country);
  }

  static List<Widget> _withGaps(
    List<Widget> children, {
    required bool vertical,
  }) {
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0)
          SizedBox(width: vertical ? 0 : 14, height: vertical ? 14 : 0),
        children[i],
      ],
    ];
  }
}
