part of 'diplomacy_player_modal_resource_trade.dart';

class _ResourceTradeBody extends StatelessWidget {
  const _ResourceTradeBody({
    required this.l10n,
    required this.blockedByWar,
    required this.hasOffers,
    required this.showModePicker,
    required this.mode,
    required this.onModeChanged,
    required this.editor,
    required this.summary,
  });

  final AppLocalizations l10n;
  final bool blockedByWar;
  final bool hasOffers;
  final bool showModePicker;
  final _ResourceTradeMode mode;
  final ValueChanged<_ResourceTradeMode> onModeChanged;
  final Widget editor;
  final Widget summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (blockedByWar) ...[
          _ResourceTradeNotice(
            message: l10n.diplomacyResourceTradeBlockedByWar,
            warning: true,
          ),
          const SizedBox(height: 10),
        ],
        if (!hasOffers)
          Text(
            l10n.diplomacyResourceTradeNoAvailableResources,
            style: GameUiTheme.bodySmall,
          )
        else ...[
          if (showModePicker) ...[
            _ResourceTradeModePicker(
              l10n: l10n,
              mode: mode,
              onChanged: onModeChanged,
            ),
            const SizedBox(height: 12),
          ],
          editor,
        ],
        const SizedBox(height: 14),
        summary,
      ],
    );
  }
}

class _ResourceTradeModePicker extends StatelessWidget {
  const _ResourceTradeModePicker({
    required this.l10n,
    required this.mode,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final _ResourceTradeMode mode;
  final ValueChanged<_ResourceTradeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ResourceTradeModeButton(
          key: const Key('diplomacy.resourceTrade.mode.gold'),
          label: l10n.diplomacyResourceTradeGoldMode,
          icon: GameIcons.gold,
          selected: mode == _ResourceTradeMode.gold,
          onPressed: () => onChanged(_ResourceTradeMode.gold),
        ),
        _ResourceTradeModeButton(
          key: const Key('diplomacy.resourceTrade.mode.exchange'),
          label: l10n.diplomacyResourceTradeExchangeMode,
          icon: GameIcons.split,
          selected: mode == _ResourceTradeMode.exchange,
          onPressed: () => onChanged(_ResourceTradeMode.exchange),
        ),
      ],
    );
  }
}

class _ResourceTradeModeButton extends StatelessWidget {
  const _ResourceTradeModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final GameIconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    GameIcon iconBuilder(Color color) =>
        GameIcon(icon, size: GameIconSize.small, color: color);
    return selected
        ? EpicButton.primary(
            label: label,
            iconBuilder: iconBuilder,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: onPressed,
          )
        : EpicButton.outlined(
            label: label,
            iconBuilder: iconBuilder,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: onPressed,
          );
  }
}

class _ResourceTradeEditorCard extends StatelessWidget {
  const _ResourceTradeEditorCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 80,
        borderColor: GameUiTheme.copper,
        borderAlpha: 120,
        border: BorderEmphasis.subtle,
        radius: 8,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _ResourceTradeSubmitButton extends StatelessWidget {
  const _ResourceTradeSubmitButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final GameIconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => EpicButton.primary(
    key: const Key('diplomacy.resourceTrade.confirm'),
    minWidth: 210,
    label: label,
    iconBuilder: (color) => GameIcon(icon, size: 16, color: color),
    onPressed: enabled ? onPressed : null,
  );
}

class _ResourceTradeSelector extends StatelessWidget {
  const _ResourceTradeSelector({
    required this.label,
    required this.value,
    required this.values,
    required this.l10n,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final String label;
  final ResourceType value;
  final List<ResourceType> values;
  final AppLocalizations l10n;
  final bool enabled;
  final ValueChanged<ResourceType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: GameUiTheme.bodySmall)),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: DecoratedBox(
            decoration: SurfaceElevation.flat.decoration(
              background: GameUiTheme.surface,
              backgroundAlpha: 120,
              borderColor: GameUiTheme.goldLight,
              borderAlpha: 72,
              border: BorderEmphasis.subtle,
              radius: 6,
              includeShadow: false,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 5),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ResourceType>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(7),
                  dropdownColor: GameUiTheme.bg,
                  iconEnabledColor: GameUiTheme.gold,
                  style: GameUiTheme.bodyStrong.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                  items: [
                    for (final resource in values)
                      DropdownMenuItem(
                        value: resource,
                        child: Text(
                          GameDisplayNames.resource(l10n, resource),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: enabled
                      ? (resource) {
                          if (resource != null) onChanged(resource);
                        }
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResourceTradeTerm extends StatelessWidget {
  const _ResourceTradeTerm({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final GameIconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: GameUiTheme.bodySmall)),
      const SizedBox(width: 10),
      Expanded(
        flex: 2,
        child: Row(
          children: [
            GameIcon(icon, size: GameIconSize.small, color: GameUiTheme.gold),
            const SizedBox(width: 7),
            Flexible(child: Text(value, style: GameUiTheme.bodyStrong)),
          ],
        ),
      ),
    ],
  );
}

class _ResourceTradeForecast extends StatelessWidget {
  const _ResourceTradeForecast({
    required this.text,
    required this.hint,
    this.warning = false,
  });

  final String text;
  final String hint;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? GameUiTheme.warning : GameUiTheme.success;
    return Semantics(
      label: '$text $hint',
      child: DecoratedBox(
        decoration: SurfaceElevation.flat.decoration(
          background: color,
          backgroundAlpha: 18,
          borderColor: color,
          borderAlpha: 100,
          border: BorderEmphasis.subtle,
          radius: 6,
          includeShadow: false,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: GameUiTheme.bodyStrong.copyWith(color: color)),
              const SizedBox(height: 3),
              Text(
                hint,
                style: GameUiTheme.cardMeta.copyWith(
                  color: warning
                      ? GameUiTheme.warning
                      : GameUiTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceTradeNotice extends StatelessWidget {
  const _ResourceTradeNotice({required this.message, required this.warning});

  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? GameUiTheme.warning : GameUiTheme.textSecondary;
    return Row(
      children: [
        GameIcon(GameIcons.warning, size: GameIconSize.small, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            style: GameUiTheme.bodySmall.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _ResourceTradeSummary extends StatelessWidget {
  const _ResourceTradeSummary({
    required this.l10n,
    required this.gameState,
    required this.activePlayerId,
    required this.targetPlayerId,
  });

  final AppLocalizations l10n;
  final GameClientState gameState;
  final String activePlayerId;
  final String targetPlayerId;

  @override
  Widget build(BuildContext context) {
    final agreements = _agreements();
    if (agreements.isEmpty) {
      return Text(
        l10n.diplomacyResourceTradeNoActiveAgreements,
        style: GameUiTheme.bodySmall.copyWith(color: GameUiTheme.textTertiary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.diplomacyResourceTradeActiveTitle,
          style: GameUiTheme.sectionHeader.copyWith(
            color: GameUiTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 7),
        for (final agreement in agreements)
          _ResourceTradeAgreementRow(label: _agreementLabel(agreement)),
      ],
    );
  }

  List<ResourceTradeAgreement> _agreements() => [
    for (final agreement in gameState.resourceTradeAgreements)
      if (agreement.isActive &&
          ((agreement.importerPlayerId == activePlayerId &&
                  agreement.exporterPlayerId == targetPlayerId) ||
              (agreement.importerPlayerId == targetPlayerId &&
                  agreement.exporterPlayerId == activePlayerId)))
        agreement,
  ];

  String _agreementLabel(ResourceTradeAgreement agreement) {
    final resourceName = GameDisplayNames.resource(l10n, agreement.resource);
    final direction = agreement.importerPlayerId == activePlayerId
        ? l10n.diplomacyResourceTradeImportDirection
        : l10n.diplomacyResourceTradeExportDirection;
    final price = agreement.goldPerTurn == 0
        ? l10n.diplomacyResourceTradeBarterPrice
        : l10n.diplomacyResourceTradeGoldPerTurnPrice(agreement.goldPerTurn);
    return l10n.diplomacyResourceTradeAgreementFlowLabel(
      direction,
      agreement.amountPerTurn,
      resourceName,
      price,
      agreement.remainingTurns,
    );
  }
}

class _ResourceTradeAgreementRow extends StatelessWidget {
  const _ResourceTradeAgreementRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.success,
        backgroundAlpha: 14,
        borderColor: GameUiTheme.success,
        borderAlpha: 72,
        border: BorderEmphasis.subtle,
        radius: 6,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            const GameIcon(
              GameIcons.route,
              size: GameIconSize.small,
              color: GameUiTheme.success,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
