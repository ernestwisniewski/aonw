import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/presentation/providers/ruleset/ruleset_providers.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
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
      final session = await ref.watch(
        gameSessionProvider(request.selection, request.saveId).future,
      );
      final ruleset = GameRuleset(
        city: ref.watch(cityRulesetProvider),
        technology: ref.watch(technologyRulesetProvider),
      );
      final reducer = GameStateReducer(
        mapData: session.mapData,
        ruleset: ruleset,
      );
      final service = ReplayService(
        replayStore: ref.watch(replayStoreProvider),
        eventLog: ref.watch(eventLogProvider),
        commandResolver: LocalCommandResolver(reducer: reducer),
      );
      return service.buildTimeline(request.saveId);
    });
