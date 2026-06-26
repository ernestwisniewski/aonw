import 'dart:async';
import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/replay/replay_playback_policy.dart';
import 'package:aonw/game/presentation/replay/replay_renderer_effect_planner.dart';
import 'package:aonw/game/presentation/replay/replay_turn_banner_policy.dart';
import 'package:aonw/game/presentation/widgets.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/turn_start_banner_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/scrollable_error_view.dart';
import 'package:aonw/shared/widgets/viewport_gesture_layer.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'replay_renderer_host.dart';
part 'replay_renderer_host_lifecycle.dart';
part 'replay_renderer_host_controls.dart';
part 'replay_surface_widgets.dart';
part 'replay_controls.dart';
part 'replay_event_summary.dart';
part 'replay_control_selectors.dart';
part 'replay_control_buttons.dart';
part 'replay_error_view.dart';

const _replayViewportSize = Size(640, 360);

class ReplayScreen extends ConsumerWidget {
  final String saveId;

  const ReplayScreen({required this.saveId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displaySettings = ref.watch(hexDisplayProvider);
    final gameplaySettings = ref.watch(gameplaySettingsProvider);
    final l10n = context.l10n;

    if (saveId.isEmpty) {
      return _ReplayErrorView(
        title: l10n.replayErrorTitle,
        body: l10n.replayErrorBody('Missing save id.'),
        onBack: () => context.go('/load-game'),
      );
    }

    final saveAsync = ref.watch(gameSaveProvider(saveId));
    return saveAsync.when(
      loading: () =>
          const GameLoadingView(progress: GameLoadingProgress.initial),
      error: (error, _) => _ReplayErrorView(
        title: l10n.replayErrorTitle,
        body: l10n.loadGameError(error.toString()),
        onBack: () => context.go('/load-game'),
      ),
      data: (save) {
        if (save == null || save.mapName.trim().isEmpty) {
          return _ReplayErrorView(
            title: l10n.replayErrorTitle,
            body: l10n.replayErrorBody('Save metadata is incomplete.'),
            onBack: () => context.go('/load-game'),
          );
        }

        final replaySelection = MapSelection(
          name: save.mapName.trim(),
          source: save.mapSource,
        );
        final request = ReplayTimelineRequest(
          selection: replaySelection,
          saveId: saveId,
        );
        final sessionAsync = ref.watch(
          gameSessionProvider(replaySelection, saveId),
        );
        final timelineAsync = ref.watch(replayTimelineProvider(request));

        return sessionAsync.when(
          loading: () =>
              const GameLoadingView(progress: GameLoadingProgress.initial),
          error: (error, _) => _ReplayErrorView(
            title: l10n.replayErrorTitle,
            body: l10n.loadGameError(error.toString()),
            onBack: () => context.go('/load-game'),
          ),
          data: (session) => timelineAsync.when(
            loading: () =>
                const GameLoadingView(progress: GameLoadingProgress.initial),
            error: (error, _) => _ReplayErrorView(
              title: l10n.replayErrorTitle,
              body: _replayErrorBody(l10n, error),
              onBack: () => context.go('/load-game'),
            ),
            data: (timeline) => _ReplayRendererHost(
              session: session,
              timeline: timeline,
              displaySettings: displaySettings,
              followUnitMovementCamera:
                  gameplaySettings.followUnitMovementCamera,
              cinematicCameraEnabled: gameplaySettings.cinematicCameraEnabled,
              l10n: l10n,
            ),
          ),
        );
      },
    );
  }
}
