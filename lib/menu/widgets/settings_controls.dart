import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GameUiTheme.bg.withAlpha(232),
      shape: RoundedRectangleBorder(
        borderRadius: GameUiTheme.borderRadius,
        side: BorderSide(color: GameUiTheme.gold.withAlpha(86)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: GameUiTheme.gold),
                const SizedBox(width: 8),
                Text(
                  GameText.sectionLabel(title),
                  style: GameUiTheme.sectionHeader.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      secondary: Icon(icon, color: GameUiTheme.gold, size: 20),
      activeThumbColor: GameUiTheme.goldLight,
      activeTrackColor: GameUiTheme.gold.withAlpha(90),
      inactiveThumbColor: GameUiTheme.textSecondary,
      inactiveTrackColor: GameUiTheme.surface.withAlpha(210),
      title: Text(
        label,
        maxLines: 2,
        style: GameUiTheme.bodyStrong.copyWith(
          color: value ? GameUiTheme.goldLight : GameUiTheme.textPrimary,
        ),
      ),
    );
  }
}
