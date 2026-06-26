part of 'hud_action_deck.dart';

const _combatExplanationHeaderAlpha = 220;
const _combatExplanationBulletAlpha = 220;

class _CombatExplanationPanel extends StatelessWidget {
  const _CombatExplanationPanel({required this.preview});

  final HudCombatPreview preview;

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
    final lines = [
      _advantageLine(l10n, attackerCountry, defenderCountry),
      _CombatExplanationItem(
        text: l10n.combatPreviewTerrainLine(
          attackerCountry,
          _terrainList(l10n, preview.attackerTerrains),
          defenderCountry,
          _terrainList(l10n, preview.defenderTerrains),
        ),
        tone: _CombatExplanationTone.neutral,
      ),
      ..._sourceLines(l10n, attackerCountry, defenderCountry),
      _retaliationLine(l10n, attackerCountry, defenderCountry),
    ];

    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: GameUiTheme.gold,
        background: GameUiTheme.bg,
        backgroundAlpha: 132,
        border: BorderEmphasis.subtle,
        radius: 8,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GameIcon(
                  GameIcons.info,
                  size: 15,
                  color: GameUiTheme.goldLight.withAlpha(
                    _combatExplanationHeaderAlpha,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.combatPreviewAdvantageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.sectionHeader.copyWith(
                      color: GameUiTheme.goldLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in lines) _CombatExplanationLine(line),
          ],
        ),
      ),
    );
  }

  _CombatExplanationItem _advantageLine(
    AppLocalizations l10n,
    String attackerCountry,
    String defenderCountry,
  ) {
    final pressure = preview.attackerAttack - preview.defenderDefense;
    if (pressure >= 2) {
      return _CombatExplanationItem(
        text: l10n.combatPreviewAdvantageAttacker(
          attackerCountry,
          preview.attackerAttack,
          preview.defenderDefense,
          _targetHpLoss,
        ),
        tone: _CombatExplanationTone.positive,
      );
    }
    if (pressure <= -2) {
      return _CombatExplanationItem(
        text: l10n.combatPreviewAdvantageDefender(
          defenderCountry,
          preview.attackerAttack,
          preview.defenderDefense,
          _targetHpLoss,
        ),
        tone: _CombatExplanationTone.negative,
      );
    }
    return _CombatExplanationItem(
      text: l10n.combatPreviewAdvantageEven(
        preview.attackerAttack,
        preview.defenderDefense,
        _targetHpLoss,
      ),
      tone: _CombatExplanationTone.neutral,
    );
  }

  List<_CombatExplanationItem> _sourceLines(
    AppLocalizations l10n,
    String attackerCountry,
    String defenderCountry,
  ) {
    final positiveSources = <String>{};
    final negativeSources = <String>{};
    for (final modifier in preview.attackerModifiers) {
      final source = _sourceLabel(l10n, modifier, attacker: true);
      if (source == null) continue;
      if (modifier.delta > 0) {
        positiveSources.add(source);
      } else {
        negativeSources.add(source);
      }
    }
    for (final modifier in preview.defenderModifiers) {
      final source = _sourceLabel(l10n, modifier, attacker: false);
      if (source == null) continue;
      if (modifier.delta > 0) {
        negativeSources.add(source);
      } else {
        positiveSources.add(source);
      }
    }
    if (positiveSources.isEmpty && negativeSources.isEmpty) {
      return [
        _CombatExplanationItem(
          text: l10n.combatPreviewNoSourcesLine,
          tone: _CombatExplanationTone.neutral,
        ),
      ];
    }
    return [
      if (positiveSources.isNotEmpty)
        _CombatExplanationItem(
          text: l10n.combatPreviewPositiveSourcesLine(
            attackerCountry,
            _joinLabels(positiveSources),
          ),
          tone: _CombatExplanationTone.positive,
        ),
      if (negativeSources.isNotEmpty)
        _CombatExplanationItem(
          text: l10n.combatPreviewNegativeSourcesLine(
            defenderCountry,
            _joinLabels(negativeSources),
          ),
          tone: _CombatExplanationTone.negative,
        ),
    ];
  }

  _CombatExplanationItem _retaliationLine(
    AppLocalizations l10n,
    String attackerCountry,
    String defenderCountry,
  ) {
    if (preview.hasRetaliation) {
      return _CombatExplanationItem(
        text: l10n.combatPreviewRetaliationRisk(
          defenderCountry,
          attackerCountry,
          _attackerHpLoss,
        ),
        tone: _CombatExplanationTone.negative,
      );
    }
    if (preview.defenderKilled) {
      return _CombatExplanationItem(
        text: l10n.combatPreviewNoRetaliationDefenderDefeated,
        tone: _CombatExplanationTone.positive,
      );
    }
    if (preview.defenderRetreated) {
      return _CombatExplanationItem(
        text: l10n.combatPreviewNoRetaliationDefenderRetreats,
        tone: _CombatExplanationTone.positive,
      );
    }
    if (preview.defenderAttack <= 0) {
      return _CombatExplanationItem(
        text: l10n.combatPreviewNoRetaliationNoAttack,
        tone: _CombatExplanationTone.positive,
      );
    }
    return _CombatExplanationItem(
      text: l10n.combatPreviewNoRetaliationReason(
        preview.distance,
        preview.range,
      ),
      tone: _CombatExplanationTone.positive,
    );
  }

  int get _targetHpLoss {
    final defenderHpAfter = preview.defenderKilled
        ? 0
        : preview.defenderHpAfter;
    return math.max(0, preview.defenderHpBefore - defenderHpAfter);
  }

  int get _attackerHpLoss {
    final attackerHpAfter = preview.attackerKilled
        ? 0
        : preview.attackerHpAfter;
    return math.max(0, preview.attackerHpBefore - attackerHpAfter);
  }

  String? _sourceLabel(
    AppLocalizations l10n,
    CombatModifier modifier, {
    required bool attacker,
  }) {
    return CombatModifierLabels.source(l10n, modifier, attacker: attacker);
  }

  String _terrainList(AppLocalizations l10n, List<TerrainType> terrains) {
    if (terrains.isEmpty) return l10n.commonNoneLower;
    return _joinLabels(terrains.map((terrain) => _terrainName(l10n, terrain)));
  }

  String _joinLabels(Iterable<String> labels) => labels.join(', ');

  String _terrainName(AppLocalizations l10n, TerrainType terrain) {
    return switch (terrain) {
      TerrainType.ocean => l10n.terrainOcean,
      TerrainType.coast => l10n.terrainCoast,
      TerrainType.lake => l10n.terrainLake,
      TerrainType.plains => l10n.terrainPlains,
      TerrainType.grassland => l10n.terrainGrassland,
      TerrainType.desert => l10n.terrainDesert,
      TerrainType.tundra => l10n.terrainTundra,
      TerrainType.snow => l10n.terrainSnow,
      TerrainType.mountain => l10n.terrainMountain,
      TerrainType.hills => l10n.terrainHills,
      TerrainType.wetlands => l10n.terrainWetlands,
      TerrainType.jungle => l10n.terrainJungle,
      TerrainType.forest => l10n.terrainForest,
      TerrainType.river => l10n.terrainRiver,
    };
  }
}

class _CombatExplanationLine extends StatelessWidget {
  const _CombatExplanationLine(this.item);

  final _CombatExplanationItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.tone.color;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: color.withAlpha(_combatExplanationBulletAlpha),
                shape: const CircleBorder(),
              ),
              child: const SizedBox.square(dimension: 4),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              item.text,
              style: GameUiTheme.bodySmall.copyWith(color: color, height: 1.18),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CombatExplanationTone {
  positive,
  negative,
  neutral;

  Color get color {
    return switch (this) {
      _CombatExplanationTone.positive => GameUiTheme.success,
      _CombatExplanationTone.negative => GameUiTheme.danger,
      _CombatExplanationTone.neutral => GameUiTheme.textPrimary,
    };
  }
}

class _CombatExplanationItem {
  const _CombatExplanationItem({required this.text, required this.tone});

  final String text;
  final _CombatExplanationTone tone;
}
