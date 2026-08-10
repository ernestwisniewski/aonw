part of 'civilization_met_popup_overlay.dart';

class _CivilizationMetDialog extends StatefulWidget {
  final _CivilizationMetPopupModel model;
  final GamepadInputRouter? gamepadRouter;

  const _CivilizationMetDialog({
    required this.model,
    required this.gamepadRouter,
  });

  @override
  State<_CivilizationMetDialog> createState() => _CivilizationMetDialogState();
}

class _CivilizationMetDialogState extends State<_CivilizationMetDialog> {
  bool _doNotShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GamepadInputRouteBinding(
      router: widget.gamepadRouter,
      route: GamepadInputRoute(
        priority: GamepadInputRoutePriority.modal,
        onConfirm: _dismiss,
        onCancel: _dismiss,
      ),
      child: GameModalScaffold(
        surfaceKey: const Key('civilizationMetDialog.surface'),
        size: GameModalSize.regular,
        contentPadding: EdgeInsets.zero,
        scrollable: false,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CivilizationMetHeader(model: widget.model),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Text(
                  l10n.civilizationMetPopupBody(widget.model.civilizationName),
                  style: GameUiTheme.body.copyWith(
                    color: GameUiTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              _CivilizationMetFooter(
                doNotShowAgain: _doNotShowAgain,
                onToggleDoNotShowAgain: (value) =>
                    setState(() => _doNotShowAgain = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    Navigator.of(context).pop(_dialogResult(_doNotShowAgain));
  }
}

class _CivilizationMetHeader extends StatelessWidget {
  final _CivilizationMetPopupModel model;

  const _CivilizationMetHeader({required this.model});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CivilizationMetThumbnail(color: model.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.civilizationMetPopupEyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.gold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                GameUiEpicHeader(
                  label: model.civilizationName,
                  alignment: Alignment.centerLeft,
                  accent: model.color,
                  compact: false,
                  textKey: const Key('civilizationMetDialog.title'),
                ),
                const SizedBox(height: 4),
                Text(
                  '${model.leaderName} - ${model.playerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.cardMeta.copyWith(
                    color: GameUiTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CivilizationMetFooter extends StatelessWidget {
  final bool doNotShowAgain;
  final ValueChanged<bool> onToggleDoNotShowAgain;

  const _CivilizationMetFooter({
    required this.doNotShowAgain,
    required this.onToggleDoNotShowAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.surface,
        backgroundAlpha: 170,
        borderColor: GameUiTheme.copper,
        border: BorderEmphasis.regular,
        topBorder: true,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _CivilizationMetOptOutToggle(
              label: l10n.commonDoNotShowAgain,
              value: doNotShowAgain,
              onChanged: onToggleDoNotShowAgain,
            ),
            _CivilizationMetConfirmButton(
              label: l10n.civilizationMetPopupOk,
              result: _dialogResult(doNotShowAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _CivilizationMetOptOutToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CivilizationMetOptOutToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: GameUiTheme.borderRadius,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              key: const Key('civilizationMetDialog.doNotShowAgain.checkbox'),
              value: value,
              onChanged: (nextValue) => onChanged(nextValue ?? false),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CivilizationMetConfirmButton extends StatelessWidget {
  final String label;
  final _CivilizationMetDialogResult result;

  const _CivilizationMetConfirmButton({
    required this.label,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => Navigator.of(context).pop(result),
      style: FilledButton.styleFrom(
        backgroundColor: GameUiTheme.gold,
        foregroundColor: GameUiTheme.bg,
        textStyle: GameUiTheme.actionLabel,
        shape: RoundedRectangleBorder(borderRadius: GameUiTheme.borderRadius),
      ),
      child: Text(label),
    );
  }
}

_CivilizationMetDialogResult _dialogResult(bool doNotShowAgain) {
  return doNotShowAgain
      ? _CivilizationMetDialogResult.disablePopup
      : _CivilizationMetDialogResult.dismissed;
}
