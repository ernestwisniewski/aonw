part of 'hud_action_deck.dart';

const _combatForecastHeaderAlpha = 220;
const _combatForecastDividerAlpha = 190;

class _CombatOutcomeForecast extends StatelessWidget {
  const _CombatOutcomeForecast({
    required this.preview,
    required this.compact,
    required this.attackerName,
    required this.defenderName,
  });

  final HudCombatPreview preview;
  final bool compact;
  final String attackerName;
  final String defenderName;

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
    final attackerAccent = preview.attackerKilled
        ? GameUiTheme.danger
        : GameUiTheme.goldLight;
    final defenderAccent = preview.defenderKilled
        ? GameUiTheme.danger
        : GameUiTheme.success;

    return Container(
      key: const Key('hudCombatConfirm.forecast'),
      padding: EdgeInsets.fromLTRB(10, compact ? 9 : 10, 10, 10),
      decoration: SurfaceElevation.flat.decoration(
        accent: GameUiTheme.gold,
        background: GameUiTheme.surface,
        backgroundAlpha: 182,
        border: BorderEmphasis.subtle,
        radius: 8,
        includeShadow: false,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GameIcon(
                GameIcons.stats,
                size: 15,
                color: GameUiTheme.goldLight.withAlpha(
                  _combatForecastHeaderAlpha,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.combatPreviewForecastTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.sectionHeader.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final ringSize = constraints.maxWidth < 310
                  ? 88.0
                  : compact
                  ? 98.0
                  : 112.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CombatHpRingCard(
                      roleLabel: attackerCountry,
                      unitName: attackerName,
                      beforeHp: preview.attackerHpBefore,
                      afterHp: preview.attackerKilled
                          ? 0
                          : preview.attackerHpAfter,
                      maxHp: preview.attackerMaxHp,
                      killed: preview.attackerKilled,
                      accent: attackerAccent,
                      ringSize: ringSize,
                      ringKey: const Key('hudCombatConfirm.attackerRing'),
                      hpKey: const Key('hudCombatConfirm.attackerHpAfter'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: compact ? 7 : 10,
                      right: compact ? 7 : 10,
                      top: ringSize * 0.34,
                    ),
                    child: const _CombatForecastDivider(),
                  ),
                  Expanded(
                    child: _CombatHpRingCard(
                      roleLabel: defenderCountry,
                      unitName: defenderName,
                      beforeHp: preview.defenderHpBefore,
                      afterHp: preview.defenderKilled
                          ? 0
                          : preview.defenderHpAfter,
                      maxHp: preview.defenderMaxHp,
                      killed: preview.defenderKilled,
                      accent: defenderAccent,
                      ringSize: ringSize,
                      ringKey: const Key('hudCombatConfirm.defenderRing'),
                      hpKey: const Key('hudCombatConfirm.defenderHpAfter'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CombatForecastDivider extends StatelessWidget {
  const _CombatForecastDivider();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'VS',
          style: GameUiTheme.labelSmall.copyWith(
            color: GameUiTheme.goldLight,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        GameIcon(
          GameIcons.arrowRight,
          size: 18,
          color: GameUiTheme.gold.withAlpha(_combatForecastDividerAlpha),
        ),
      ],
    );
  }
}
