part of 'replay_screen.dart';

class _ReplayControls extends StatelessWidget {
  final ReplayTimeline timeline;
  final int stepIndex;
  final bool playing;
  final double speed;
  final String? perspectivePlayerId;
  final bool showTurnMarkers;
  final bool freeCamera;
  final VoidCallback onTogglePlayback;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onStepChanged;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<String?> onPerspectiveChanged;
  final ValueChanged<bool> onShowTurnMarkersChanged;
  final ValueChanged<bool> onFreeCameraChanged;

  const _ReplayControls({
    required this.timeline,
    required this.stepIndex,
    required this.playing,
    required this.speed,
    required this.perspectivePlayerId,
    required this.showTurnMarkers,
    required this.freeCamera,
    required this.onTogglePlayback,
    required this.onPrevious,
    required this.onNext,
    required this.onStepChanged,
    required this.onSpeedChanged,
    required this.onPerspectiveChanged,
    required this.onShowTurnMarkersChanged,
    required this.onFreeCameraChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = timeline.steps.length;
    final step = stepIndex == 0 ? null : timeline.steps[stepIndex - 1];
    final turn = step?.turn ?? timeline.firstTurn;
    final eventCount = step?.events.length ?? 0;
    final messages = _messagesFor(context, step);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(232),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameUiTheme.gold.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 10 : 14,
              12,
              compact ? 10 : 14,
              12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ReplayPill(
                      icon: Icons.timeline_rounded,
                      label: l10n.replayStepCounter(stepIndex, total),
                    ),
                    _ReplayPill(
                      icon: Icons.flag_outlined,
                      label: l10n.replayTurnLabel(turn),
                    ),
                    _ReplayPill(
                      icon: Icons.bolt_rounded,
                      label: l10n.replayEventCount(eventCount),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _ReplayEventSummary(messages: messages, step: step),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ReplayIconButton(
                      tooltip: l10n.replayPreviousAction,
                      icon: Icons.skip_previous_rounded,
                      onPressed: onPrevious,
                    ),
                    const SizedBox(width: 8),
                    _ReplayIconButton(
                      tooltip: playing
                          ? l10n.replayPauseAction
                          : l10n.replayPlayAction,
                      icon: playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      emphasized: true,
                      onPressed: onTogglePlayback,
                    ),
                    const SizedBox(width: 8),
                    _ReplayIconButton(
                      tooltip: l10n.replayNextAction,
                      icon: Icons.skip_next_rounded,
                      onPressed: onNext,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: GameUiTheme.goldLight,
                          inactiveTrackColor: GameUiTheme.gold.withAlpha(55),
                          thumbColor: GameUiTheme.goldLight,
                          overlayColor: GameUiTheme.gold.withAlpha(45),
                        ),
                        child: Slider(
                          value: stepIndex.toDouble(),
                          min: 0,
                          max: total.toDouble(),
                          divisions: total == 0 ? null : total,
                          onChanged: total == 0
                              ? null
                              : (value) => onStepChanged(value.round()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ReplaySpeedSelector(
                      value: speed,
                      onChanged: onSpeedChanged,
                    ),
                    _ReplayPerspectiveSelector(
                      timeline: timeline,
                      value: perspectivePlayerId,
                      onChanged: onPerspectiveChanged,
                    ),
                    _ReplayTurnMarkerToggle(
                      value: showTurnMarkers,
                      onChanged: onShowTurnMarkersChanged,
                    ),
                    _ReplayFreeCameraToggle(
                      value: freeCamera,
                      onChanged: onFreeCameraChanged,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<GameEventNotificationMessage> _messagesFor(
    BuildContext context,
    ReplayStep? step,
  ) {
    if (step == null) return const [];
    final l10n = context.l10n;
    final activity = step.loggedCommand.activity;
    if (activity.isNotEmpty) {
      final entries = _activityEntriesForPerspective(activity);
      return [
        for (var i = 0; i < entries.length && i < 3; i++)
          GameEventNotificationMessage.from(
            l10n,
            GameEventNotification(
              id: step.offset * 1000 + i,
              event: entries[i].event,
              state: step.state,
              previousState: step.previousState,
              playerId: entries[i].playerId,
              turn: step.turn,
              context: entries[i].context,
            ),
            timeline.save,
          ),
      ];
    }
    return [
      for (var i = 0; i < step.events.length && i < 3; i++)
        GameEventNotificationMessage.from(
          l10n,
          GameEventNotification(
            id: step.offset * 1000 + i,
            event: step.events[i],
            state: step.state,
            previousState: step.previousState,
            playerId: step.effectiveActorPlayerId ?? '',
            turn: step.turn,
          ),
          timeline.save,
        ),
    ];
  }

  List<LoggedActivityEntry> _activityEntriesForPerspective(
    List<LoggedActivityEntry> entries,
  ) {
    final playerId = perspectivePlayerId;
    if (playerId != null && playerId.isNotEmpty) {
      return [
        for (final entry in entries)
          if (entry.playerId == playerId) entry,
      ];
    }

    final seenEventIndexes = <int>{};
    return [
      for (final entry in entries)
        if (seenEventIndexes.add(entry.eventIndex)) entry,
    ];
  }
}
