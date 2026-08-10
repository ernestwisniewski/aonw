import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:flutter/material.dart';

class MenuActionBar extends StatelessWidget {
  const MenuActionBar({
    this.summary,
    this.primaryLabel,
    this.primaryKey,
    this.primaryIcon,
    this.primaryBusy = false,
    this.onPrimary,
    this.secondaryLabel,
    this.secondaryKey,
    this.secondaryIcon,
    this.onSecondary,
    super.key,
  });

  final Widget? summary;
  final String? primaryLabel;
  final Key? primaryKey;
  final IconData? primaryIcon;
  final bool primaryBusy;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final Key? secondaryKey;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final hasPrimary = primaryLabel != null;
    final hasSecondary = secondaryLabel != null;
    if (!hasPrimary && !hasSecondary && summary == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(248),
        border: Border(
          top: BorderSide(color: GameUiTheme.gold.withAlpha(90), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: LayoutBuilder(builder: _buildLayout),
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    final compact = constraints.maxWidth < 520;
    final actions = _MenuActionButtons(
      compact: compact,
      primaryLabel: primaryLabel,
      primaryKey: primaryKey,
      primaryIcon: primaryBusy ? Icons.hourglass_top_rounded : primaryIcon,
      onPrimary: primaryBusy ? null : onPrimary,
      secondaryLabel: secondaryLabel,
      secondaryKey: secondaryKey,
      secondaryIcon: secondaryIcon,
      onSecondary: primaryBusy ? null : onSecondary,
    );
    return compact ? _compactLayout(actions) : _wideLayout(actions);
  }

  Widget _compactLayout(Widget actions) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null) ...[summary!, const SizedBox(height: 10)],
        actions,
      ],
    );
  }

  Widget _wideLayout(Widget actions) {
    return Row(
      children: [
        if (summary != null) ...[
          Expanded(child: summary!),
          const SizedBox(width: 16),
        ] else
          const Spacer(),
        actions,
      ],
    );
  }
}

class _MenuActionButtons extends StatelessWidget {
  const _MenuActionButtons({
    required this.compact,
    required this.primaryLabel,
    required this.primaryKey,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.secondaryKey,
    required this.secondaryIcon,
    required this.onSecondary,
  });

  final bool compact;
  final String? primaryLabel;
  final Key? primaryKey;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final Key? secondaryKey;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final primary = _primaryButton();
    final secondary = _secondaryButton();
    return compact
        ? _compactButtons(primary, secondary)
        : _wideButtons(primary, secondary);
  }

  Widget? _primaryButton() {
    if (primaryLabel == null) return null;
    return EpicButton.primary(
      key: primaryKey,
      onPressed: onPrimary,
      icon: primaryIcon,
      label: primaryLabel!,
      minWidth: compact ? null : 176,
    );
  }

  Widget? _secondaryButton() {
    if (secondaryLabel == null) return null;
    return EpicButton.outlined(
      key: secondaryKey,
      onPressed: onSecondary,
      icon: secondaryIcon,
      label: secondaryLabel!,
      minWidth: compact ? null : 132,
    );
  }

  Widget _compactButtons(Widget? primary, Widget? secondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primary != null) SizedBox(width: double.infinity, child: primary),
        if (primary != null && secondary != null) const SizedBox(height: 8),
        if (secondary != null)
          SizedBox(width: double.infinity, child: secondary),
      ],
    );
  }

  Widget _wideButtons(Widget? primary, Widget? secondary) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?secondary,
        if (primary != null && secondary != null) const SizedBox(width: 10),
        ?primary,
      ],
    );
  }
}
