import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/presentation/providers/ruleset/ruleset_providers.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ReplayTimelineRequest {
  final MapSelection selection;
  final String saveId;

  const ReplayTimelineRequest({required this.selection, required this.saveId});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReplayTimelineRequest &&
            other.selection == selection &&
            other.saveId == saveId;
  }

  @override
  int get hashCode => Object.hash(selection, saveId);
}

final replayTimelineProvider = FutureProvider.autoDispose
    .family<ReplayTimeline, ReplayTimelineRequest>((ref, request) async {
      final sessionFuture = ref.watch(
        gameSessionProvider(request.selection, request.saveId).future,
      );
      final cityRuleset = ref.watch(cityRulesetProvider);
      final technologyRuleset = ref.watch(technologyRulesetProvider);
      final stabilityRuleset = ref.watch(stabilityRulesetProvider);
      final replayStore = ref.watch(replayStoreProvider);
      final eventLog = ref.watch(eventLogProvider);
      final session = await sessionFuture;
      final ruleset = GameRuleset.standard().copyWith(
        city: cityRuleset,
        technology: technologyRuleset,
        stability: stabilityRuleset,
      );
      final reducer = GameStateReducer(
        mapData: session.mapData,
        ruleset: ruleset,
      );
      final service = ReplayService(
        replayStore: replayStore,
        eventLog: eventLog,
        commandResolver: LocalCommandResolver(reducer: reducer),
      );
      return service.buildTimeline(request.saveId);
    });
