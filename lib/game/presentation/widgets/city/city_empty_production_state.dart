import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class CityEmptyProductionState extends StatelessWidget {
  const CityEmptyProductionState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        l10n.productionEmptyState,
        textAlign: TextAlign.center,
        style: const TextStyle(color: GameHudTheme.textMuted, fontSize: 13),
      ),
    );
  }
}
