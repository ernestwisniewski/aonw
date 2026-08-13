import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_strategic_resource_summary.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'strategic_resource_economy_cards.dart';
part 'strategic_resource_economy_primitives.dart';
part 'strategic_resource_economy_sections.dart';
part 'strategic_resource_economy_trade.dart';

Future<void> showStrategicResourceEconomyDialog(
  BuildContext context, {
  required HudStrategicResourceSummary summary,
  required GameClientState gameState,
  required GameSave gameSave,
  required String activePlayerId,
  required ValueChanged<GameCity> onCityPressed,
  required ValueChanged<String> onTradePartnerPressed,
  ValueListenable<GamepadInputSnapshot>? gamepadInputListenable,
}) async {
  await showGameModal<void>(
    context: context,
    size: GameModalSize.wide,
    builder: (dialogContext) => StrategicResourceEconomyPanel(
      summary: summary,
      gameState: gameState,
      gameSave: gameSave,
      activePlayerId: activePlayerId,
      gamepadInputListenable: gamepadInputListenable,
      onClose: () => Navigator.of(dialogContext).maybePop(),
      onCityPressed: (city) {
        Navigator.of(dialogContext).pop();
        onCityPressed(city);
      },
      onTradePartnerPressed: (playerId) {
        Navigator.of(dialogContext).pop();
        onTradePartnerPressed(playerId);
      },
    ),
  );
}

/// Read-only empire overview for strategic supply and its consumers.
class StrategicResourceEconomyPanel extends StatelessWidget {
  const StrategicResourceEconomyPanel({
    required this.summary,
    required this.gameState,
    required this.gameSave,
    required this.activePlayerId,
    required this.onClose,
    required this.onCityPressed,
    required this.onTradePartnerPressed,
    this.gamepadInputListenable,
    super.key,
  });

  final HudStrategicResourceSummary summary;
  final GameClientState gameState;
  final GameSave gameSave;
  final String activePlayerId;
  final VoidCallback onClose;
  final ValueChanged<GameCity> onCityPressed;
  final ValueChanged<String> onTradePartnerPressed;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final agreements = _activeAgreements();
    final alerts = _alerts(l10n, agreements);
    return GameModalScaffold(
      surfaceKey: const Key('strategicResourceEconomy.surface'),
      size: GameModalSize.wide,
      showCornerDiamonds: false,
      header: GameModalHeader(
        title: l10n.resourceEconomyTitle,
        subtitle: alerts.isEmpty
            ? l10n.resourceEconomyHealthySubtitle
            : l10n.resourceEconomyAttentionSubtitle(alerts.length),
        leading: const GameIcon(
          GameIcons.resources,
          size: GameIconSize.regular,
          color: GameUiTheme.goldLight,
        ),
        onClose: onClose,
      ),
      scrollable: false,
      content: GamepadScrollable(
        input: gamepadInputListenable,
        onCancel: onClose,
        child: _EconomyOverview(
          l10n: l10n,
          summary: summary,
          gameSave: gameSave,
          activePlayerId: activePlayerId,
          alerts: alerts,
          agreements: agreements,
          partners: _tradePartners(),
          onCityPressed: onCityPressed,
          onTradePartnerPressed: onTradePartnerPressed,
        ),
      ),
    );
  }

  List<ResourceTradeAgreement> _activeAgreements() => [
    for (final agreement in gameState.resourceTradeAgreements)
      if (agreement.isActive &&
          (agreement.importerPlayerId == activePlayerId ||
              agreement.exporterPlayerId == activePlayerId))
        agreement,
  ]..sort((a, b) => a.remainingTurns.compareTo(b.remainingTurns));

  List<_EconomyAlert> _alerts(
    AppLocalizations l10n,
    Iterable<ResourceTradeAgreement> agreements,
  ) => [
    for (final row in summary.rows)
      if (row.shortage || (row.available == 0 && row.allocated > 0))
        _EconomyAlert(
          key: 'stock.${row.resource.name}',
          title: row.available == 0
              ? l10n.resourceEconomyNoFreeStockAlert(
                  GameDisplayNames.resource(l10n, row.resource),
                )
              : l10n.resourceEconomyInsufficientStockAlert(
                  GameDisplayNames.resource(l10n, row.resource),
                ),
          detail: l10n.resourceEconomyNoFreeStockDetail,
          danger: row.shortage,
        ),
    for (final agreement in agreements)
      if (agreement.remainingTurns <= 2)
        _EconomyAlert(
          key: 'trade.${agreement.id}',
          title: l10n.resourceEconomyTradeExpiringAlert(
            GameDisplayNames.resource(l10n, agreement.resource),
            agreement.remainingTurns,
          ),
          detail: l10n.resourceEconomyTradeExpiringDetail,
        ),
  ];

  List<Player> _tradePartners() => [
    for (final player in gameSave.players)
      if (player.id != activePlayerId && _hasContact(player.id)) player,
  ];

  bool _hasContact(String targetPlayerId) {
    if (activePlayerId.isEmpty || targetPlayerId.isEmpty) return false;
    if (gameState.diplomacy.hasContact(activePlayerId, targetPlayerId)) {
      return true;
    }
    return DiplomaticContact.hasContact(
      playerId: activePlayerId,
      targetPlayerId: targetPlayerId,
      fogOfWar: gameState.fogOfWar,
      units: gameState.units,
      cities: gameState.cities,
    );
  }
}
