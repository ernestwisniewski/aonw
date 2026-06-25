part of 'hud_action_deck.dart';

class _CombatConfirmationDialog extends StatelessWidget {
  const _CombatConfirmationDialog({
    required this.preview,
    required this.onCancel,
    required this.onConfirm,
    this.onDestroyCity,
  });

  final HudCombatPreview preview;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final VoidCallback? onDestroyCity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final attackerCountry = GameDisplayNames.playerCountry(
      l10n,
      preview.attackerCountry,
    );
    final defenderCountry = GameDisplayNames.playerCountry(
      l10n,
      preview.defenderCountry,
    );
    final attackerName = _attackerDisplayName(l10n);
    final defenderName = _defenderDisplayName(l10n);
    return GameModalScaffold(
      surfaceKey: const Key('hudCombatConfirm.surface'),
      size: GameModalSize.adaptive,
      contentPadding: const EdgeInsets.all(14),
      header: GameModalHeader(
        title: l10n.selectionActionConfirmAttack,
        subtitle:
            '$attackerCountry: $attackerName → '
            '$defenderCountry: $defenderName',
        onClose: onCancel,
      ),
      actions: _actions(l10n),
      content: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.combatPreviewConfirmBody, style: GameUiTheme.bodySmall),
              const SizedBox(height: 12),
              _CombatOutcomeForecast(
                preview: preview,
                compact: compact,
                attackerName: attackerName,
                defenderName: defenderName,
              ),
              const SizedBox(height: 12),
              _CombatExplanationPanel(preview: preview),
            ],
          );
        },
      ),
    );
  }

  String _attackerDisplayName(AppLocalizations l10n) {
    final unitType = preview.attackerUnitType;
    if (unitType != null) return GameDisplayNames.unitType(l10n, unitType);
    return preview.attackerName;
  }

  String _defenderDisplayName(AppLocalizations l10n) {
    final unitType = preview.defenderUnitType;
    if (unitType != null) return GameDisplayNames.unitType(l10n, unitType);
    final city = preview.defenderCity;
    if (city != null) return GameDisplayNames.city(l10n, city);
    return preview.defenderName;
  }

  List<GameModalAction> _actions(AppLocalizations l10n) {
    return [
      GameModalAction(
        key: const Key('hudCombatConfirm.cancel'),
        onPressed: onCancel,
        label: l10n.selectionActionCancel,
        variant: EpicButtonVariant.text,
      ),
      if (onDestroyCity != null)
        GameModalAction(
          key: const Key('hudCombatConfirm.destroyCity'),
          onPressed: onDestroyCity,
          label: l10n.selectionActionDestroyCity,
          variant: EpicButtonVariant.text,
        ),
      GameModalAction(
        key: const Key('hudCombatConfirm.confirm'),
        onPressed: onConfirm,
        label: onDestroyCity == null
            ? l10n.selectionActionConfirmAttack
            : l10n.selectionActionCaptureCity,
        variant: EpicButtonVariant.primary,
      ),
    ];
  }
}
