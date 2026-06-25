part of 'activity_log_dialog.dart';

class _ActivityLogFilterBar extends StatelessWidget {
  const _ActivityLogFilterBar({
    required this.selected,
    required this.compact,
    required this.onChanged,
  });

  final ActivityLogFilter selected;
  final bool compact;
  final ValueChanged<ActivityLogFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<ActivityLogFilter>(
      showSelectedIcon: false,
      segments: [
        for (final filter in ActivityLogFilter.values)
          ButtonSegment(
            value: filter,
            label: Text(compact ? filter.shortLabel(l10n) : filter.label(l10n)),
          ),
      ],
      selected: {selected},
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        minimumSize: WidgetStateProperty.all(const Size(0, 28)),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: compact ? 6 : 9),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GameUiTheme.bg;
          }
          return GameUiTheme.textSecondary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GameUiTheme.goldLight;
          }
          return Colors.transparent;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return BorderSide(
            color: selected
                ? GameUiTheme.goldLight
                : SurfaceElevation.flat.strokeColor(alpha: 82),
          );
        }),
        textStyle: WidgetStateProperty.all(GameUiTheme.labelSmall),
      ),
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _ActivityLogDistributionBar extends StatelessWidget {
  const _ActivityLogDistributionBar({
    required this.entries,
    required this.compact,
  });

  final List<GameEventNotification> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = _ActivityLogDistributionData.from(entries);
    if (data.total == 0) return const SizedBox.shrink();

    return Semantics(
      label: data.semanticLabel(l10n),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: compact ? 5 : 6,
          child: Row(
            children: [
              for (final segment in data.segments)
                if (segment.count > 0)
                  Expanded(
                    flex: segment.count,
                    child: Tooltip(
                      message: segment.tooltip(l10n),
                      child: ColoredBox(color: segment.color),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityLogDistributionData {
  const _ActivityLogDistributionData({required this.segments});

  final List<_ActivityLogDistributionSegment> segments;

  int get total {
    var sum = 0;
    for (final segment in segments) {
      sum += segment.count;
    }
    return sum;
  }

  String semanticLabel(AppLocalizations l10n) {
    return [
      for (final segment in segments)
        if (segment.count > 0) segment.tooltip(l10n),
    ].join(', ');
  }

  static _ActivityLogDistributionData from(
    List<GameEventNotification> entries,
  ) {
    var combat = 0;
    var city = 0;
    var diplomacy = 0;
    var technology = 0;
    var other = 0;
    for (final entry in entries) {
      final event = entry.event;
      if (ActivityLogFilter.combat.matches(event)) {
        combat++;
      } else if (ActivityLogFilter.city.matches(event)) {
        city++;
      } else if (ActivityLogFilter.diplomacy.matches(event)) {
        diplomacy++;
      } else if (ActivityLogFilter.technology.matches(event)) {
        technology++;
      } else {
        other++;
      }
    }
    return _ActivityLogDistributionData(
      segments: [
        _ActivityLogDistributionSegment(
          filter: ActivityLogFilter.combat,
          count: combat,
        ),
        _ActivityLogDistributionSegment(
          filter: ActivityLogFilter.city,
          count: city,
        ),
        _ActivityLogDistributionSegment(
          filter: ActivityLogFilter.diplomacy,
          count: diplomacy,
        ),
        _ActivityLogDistributionSegment(
          filter: ActivityLogFilter.technology,
          count: technology,
        ),
        _ActivityLogDistributionSegment(filter: null, count: other),
      ],
    );
  }
}

class _ActivityLogDistributionSegment {
  const _ActivityLogDistributionSegment({
    required this.filter,
    required this.count,
  });

  final ActivityLogFilter? filter;
  final int count;

  Color get color => filter?.emptyAccent ?? GameUiTheme.textMuted;

  String tooltip(AppLocalizations l10n) {
    final label = filter?.label(l10n) ?? l10n.commonOther;
    return '$label: $count';
  }
}

enum ActivityLogFilter { all, combat, city, diplomacy, technology }

extension ActivityLogFilterPresentation on ActivityLogFilter {
  String label(AppLocalizations l10n) {
    return switch (this) {
      ActivityLogFilter.all => l10n.activityLogFilterAll,
      ActivityLogFilter.combat => l10n.activityLogFilterCombat,
      ActivityLogFilter.city => l10n.activityLogFilterCities,
      ActivityLogFilter.diplomacy => l10n.activityLogFilterDiplomacy,
      ActivityLogFilter.technology => l10n.activityLogFilterTechnology,
    };
  }

  String shortLabel(AppLocalizations l10n) {
    return switch (this) {
      ActivityLogFilter.all => l10n.activityLogFilterAllShort,
      ActivityLogFilter.combat => l10n.activityLogFilterCombat,
      ActivityLogFilter.city => l10n.activityLogFilterCities,
      ActivityLogFilter.diplomacy => l10n.activityLogFilterDiplomacyShort,
      ActivityLogFilter.technology => l10n.activityLogFilterTechnology,
    };
  }

  String emptyLabel(AppLocalizations l10n) {
    return switch (this) {
      ActivityLogFilter.all => l10n.activityLogEmptyAllTitle,
      ActivityLogFilter.combat => l10n.activityLogEmptyCombatTitle,
      ActivityLogFilter.city => l10n.activityLogEmptyCityTitle,
      ActivityLogFilter.diplomacy => l10n.activityLogEmptyDiplomacyTitle,
      ActivityLogFilter.technology => l10n.activityLogEmptyTechnologyTitle,
    };
  }

  String emptyBody(AppLocalizations l10n) {
    return switch (this) {
      ActivityLogFilter.all => l10n.activityLogEmptyAllBody,
      ActivityLogFilter.combat => l10n.activityLogEmptyCombatBody,
      ActivityLogFilter.city => l10n.activityLogEmptyCityBody,
      ActivityLogFilter.diplomacy => l10n.activityLogEmptyDiplomacyBody,
      ActivityLogFilter.technology => l10n.activityLogEmptyTechnologyBody,
    };
  }

  GameIconData get emptyIcon {
    return switch (this) {
      ActivityLogFilter.all => GameIcons.activityLog,
      ActivityLogFilter.combat => GameIcons.attack,
      ActivityLogFilter.city => GameIcons.cityFilled,
      ActivityLogFilter.diplomacy => GameIcons.diplomacy,
      ActivityLogFilter.technology => GameIcons.science,
    };
  }

  Color get emptyAccent {
    return switch (this) {
      ActivityLogFilter.all => GameUiTheme.gold,
      ActivityLogFilter.combat => GameUiTheme.danger,
      ActivityLogFilter.city => GameUiTheme.resourcesAccent,
      ActivityLogFilter.diplomacy => GameUiTheme.info,
      ActivityLogFilter.technology => GameUiTheme.scienceAccent,
    };
  }

  bool matches(GameEvent event) {
    return switch (this) {
      ActivityLogFilter.all => true,
      ActivityLogFilter.combat =>
        event is CombatResolvedEvent ||
            event is UnitKilledEvent ||
            event is UnitRetreatedEvent,
      ActivityLogFilter.city =>
        event is CityFoundedEvent ||
            event is CityBuiltBuildingEvent ||
            event is CityProducedUnitEvent ||
            event is CityClaimedHexEvent ||
            event is CityCapturedEvent ||
            event is WorkerCompletedJobEvent,
      ActivityLogFilter.diplomacy =>
        event is CivilizationMetEvent ||
            event is DiplomaticProposalSentEvent ||
            event is DiplomaticProposalRespondedEvent ||
            event is DiplomaticProposalExpiredEvent ||
            event is DiplomaticRelationChangedEvent ||
            event is DiplomaticMessageSentEvent ||
            event is DiplomaticMessageRespondedEvent ||
            event is DiplomaticScoreChangedEvent ||
            event is DiplomaticPromiseBrokenEvent,
      ActivityLogFilter.technology => event is TechnologyResearchedEvent,
    };
  }
}
