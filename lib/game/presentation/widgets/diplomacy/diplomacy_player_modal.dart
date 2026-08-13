import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/diplomacy_history_presenter.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomacy_player_modal_resource_trade.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomacy_section.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'diplomacy_player_modal_actions.dart';
part 'diplomacy_player_modal_conversation.dart';
part 'diplomacy_player_modal_labels.dart';
part 'diplomacy_player_modal_overview.dart';
part 'diplomacy_player_modal_primitives.dart';
part 'diplomacy_player_modal_relation_chart.dart';

Future<void> showDiplomacyPlayerModal(
  BuildContext context, {
  required GameSave gameSave,
  required GameClientState gameState,
  required WorldMap mapData,
  required String activePlayerId,
  required String targetPlayerId,
  required Future<DispatchCommandResult> Function(DomainCommand command)
  onCommand,
  ValueListenable<GamepadInputSnapshot>? gamepadInputListenable,
}) {
  return showGameModal<void>(
    context: context,
    size: GameModalSize.wide,
    builder: (dialogContext) {
      Future<bool> dispatchAndMaybeClose(DomainCommand command) async {
        final result = await onCommand(command);
        if (result.accepted && dialogContext.mounted) {
          unawaited(Navigator.of(dialogContext).maybePop());
        }
        return result.accepted;
      }

      return DiplomacyPlayerModal(
        gameSave: gameSave,
        gameState: gameState,
        mapData: mapData,
        activePlayerId: activePlayerId,
        targetPlayerId: targetPlayerId,
        gamepadInputListenable: gamepadInputListenable,
        onCommand: (command) async {
          await dispatchAndMaybeClose(command);
        },
        onResourceTradeCommand: dispatchAndMaybeClose,
      );
    },
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
    this.onResourceTradeCommand,
    this.gamepadInputListenable,
    super.key,
  });

  final GameSave gameSave;
  final GameClientState gameState;
  final WorldMap mapData;
  final String activePlayerId;
  final String targetPlayerId;
  final Future<void> Function(DomainCommand command) onCommand;
  final Future<bool> Function(DomainCommand command)? onResourceTradeCommand;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

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
      scrollable: false,
      content: GamepadScrollable(
        input: gamepadInputListenable,
        onCancel: () => Navigator.of(context).maybePop(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              final children = _sections(l10n: l10n, relation: relation);
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _withGaps(children, vertical: true),
                );
              }
              return _wideLayout(children);
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _sections({
    required AppLocalizations l10n,
    required DiplomaticRelation relation,
  }) => [
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
    ResourceTradeSection(
      l10n: l10n,
      gameState: gameState,
      mapData: mapData,
      relation: relation,
      activePlayerId: activePlayerId,
      targetPlayerId: targetPlayerId,
      onCommand: onCommand,
      onResourceTradeCommand: onResourceTradeCommand,
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
                DiplomacyState.relationKey(activePlayerId, targetPlayerId),
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
      gameState: gameState,
      relation: relation,
      currentTurn: gameSave.turn,
      activePlayerId: activePlayerId,
      targetPlayerId: targetPlayerId,
      onCommand: onCommand,
    ),
  ];

  Widget _wideLayout(List<Widget> children) {
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
  }

  String _playerName(AppLocalizations l10n, String playerId) {
    final player = gameSave.playerById(playerId);
    return player == null ? playerId : GameDisplayNames.player(l10n, player);
  }

  String _playerCountryName(AppLocalizations l10n, String playerId) {
    final player = gameSave.playerById(playerId);
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
