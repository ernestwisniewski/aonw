import 'dart:async';

import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_runtime_strategy_resolver.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/application/services/turn_opening_lease.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/renderer_view_model.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/services/ai_turn_auto_scheduler.dart';
import 'package:aonw/game/presentation/services/ai_turn_execution_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_identity_guard.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_lifecycle_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_presentation_driver.dart';
import 'package:aonw/game/presentation/services/ai_turn_process_preparer.dart';
import 'package:aonw/game/presentation/services/ai_turn_runtime_coordinator.dart';
import 'package:aonw/game/presentation/services/isolated_ai_plan_executor.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_rules.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/providers/ai_settings_provider.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'game_ai_turn_auto_pilot_execution.dart';
part 'game_ai_turn_auto_pilot_process.dart';
part 'game_ai_turn_auto_pilot_runtime.dart';

class GameAiTurnAutoPilot extends ConsumerStatefulWidget {
  final GameSave? gameSave;
  final Duration interCommandDelay;

  const GameAiTurnAutoPilot({
    required this.gameSave,
    this.interCommandDelay = const Duration(milliseconds: 40),
    super.key,
  });

  @override
  ConsumerState<GameAiTurnAutoPilot> createState() =>
      _GameAiTurnAutoPilotState();
}

class _GameAiTurnAutoPilotState extends ConsumerState<GameAiTurnAutoPilot>
    with WidgetsBindingObserver {
  late final AiTurnRuntimeCoordinator _runtimeCoordinator;
  late final AiTurnLifecycleCoordinator _lifecycleCoordinator;
  final AiTurnPlanPrecomputeCache _precomputeCache =
      AiTurnPlanPrecomputeCache();
  final AiStrategicPlanProvider _strategicPlanProvider =
      AiStrategicPlanProvider();
  final AiRuntimeThrottler _runtimeThrottler = AiRuntimeThrottler();
  final AiTurnPrecomputeCoordinator _precomputeCoordinator =
      AiTurnPrecomputeCoordinator();
  final AiTurnRunScheduler _runScheduler = AiTurnRunScheduler();
  final AiTurnFollowUpIdentityGuard _followUpIdentityGuard =
      AiTurnFollowUpIdentityGuard();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _followUpIdentityGuard.initialize(_saveIdentity(widget.gameSave));
    _runtimeCoordinator = _createAiTurnRuntimeCoordinator();
    _lifecycleCoordinator = _createAiTurnLifecycleCoordinator();
  }

  @override
  void didUpdateWidget(GameAiTurnAutoPilot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final invalidatedLease = _followUpIdentityGuard.handleSaveChange(
      _saveIdentity(widget.gameSave),
    );
    if (invalidatedLease != null) {
      _cancelTurnOpening(invalidatedLease);
    }
    _lifecycleCoordinator.handleSaveChange(
      previousSave: oldWidget.gameSave,
      currentSave: widget.gameSave,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleCoordinator.handleLifecyclePaused(
      state != AppLifecycleState.resumed,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final invalidatedLease = _followUpIdentityGuard.invalidate();
    if (invalidatedLease != null) {
      _cancelTurnOpening(invalidatedLease);
    }
    _lifecycleCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = widget.gameSave;
    final control = ref.watch(gamePlayerControlControllerProvider);
    final handoff = ref.watch(gameHandoffProvider);
    final networkSession = ref.watch(networkSessionProvider);
    ref.watch(aiSettingsProvider);
    final gameState = save == null
        ? null
        : ref.watch(gameStateProvider(save.id)).value;
    _aiTurnAutoScheduler().evaluate(
      save: save,
      control: control,
      handoff: handoff,
      networkSession: networkSession,
      gameState: gameState,
    );
    return const SizedBox.shrink();
  }

  AiTurnSaveIdentity? _saveIdentity(GameSave? save) {
    if (save == null) return null;
    return AiTurnSaveIdentity(saveId: save.id, turn: save.turn);
  }

  void _notifyStateChanged() {
    if (mounted) setState(() {});
  }

  void _cancelTurnOpening(TurnOpeningLease lease) {
    if (!mounted) return;
    ref
        .read(gamePlayerControlControllerProvider.notifier)
        .cancelTurnOpening(lease);
  }
}
