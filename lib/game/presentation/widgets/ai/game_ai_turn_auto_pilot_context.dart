import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/application/services/turn_opening_lease.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_identity_guard.dart';
import 'package:aonw/game/presentation/services/ai_turn_lifecycle_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_runtime_coordinator.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runtime dependencies shared by the focused auto-pilot collaborators.
final class GameAiTurnAutoPilotContext {
  GameAiTurnAutoPilotContext({
    required this.ref,
    required this.saveReader,
    required this.contextReader,
    required this.interCommandDelayReader,
    required this.canContinue,
    required this.notifyStateChanged,
    required this.cancelTurnOpening,
  });

  final WidgetRef ref;
  final GameSave? Function() saveReader;
  final BuildContext Function() contextReader;
  final Duration Function() interCommandDelayReader;
  final bool Function() canContinue;
  final VoidCallback notifyStateChanged;
  final void Function(TurnOpeningLease lease) cancelTurnOpening;

  final AiTurnPlanPrecomputeCache precomputeCache = AiTurnPlanPrecomputeCache();
  final AiStrategicPlanProvider strategicPlanProvider =
      AiStrategicPlanProvider();
  final AiRuntimeThrottler runtimeThrottler = AiRuntimeThrottler();
  final AiTurnPrecomputeCoordinator precomputeCoordinator =
      AiTurnPrecomputeCoordinator();
  final AiTurnRunScheduler runScheduler = AiTurnRunScheduler();
  final AiTurnFollowUpIdentityGuard followUpIdentityGuard =
      AiTurnFollowUpIdentityGuard();

  late final AiTurnRuntimeCoordinator runtimeCoordinator;
  late final AiTurnLifecycleCoordinator lifecycleCoordinator;
}
