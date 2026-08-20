import 'package:aonw/game/application/services/turn_opening_lease.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_identity_guard.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_context.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_runtime.dart';
import 'package:aonw/shared/providers/ai_settings_provider.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  late final GameAiTurnAutoPilotContext _autoPilot;
  bool _active = true;

  bool get _canContinue => mounted && _active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoPilot = GameAiTurnAutoPilotContext(
      ref: ref,
      saveReader: () => widget.gameSave,
      contextReader: () => context,
      interCommandDelayReader: () => widget.interCommandDelay,
      canContinue: () => _canContinue,
      notifyStateChanged: _notifyStateChanged,
      cancelTurnOpening: _cancelTurnOpening,
    );
    _autoPilot.followUpIdentityGuard.initialize(_saveIdentity(widget.gameSave));
    _autoPilot.initialize();
  }

  @override
  void didUpdateWidget(GameAiTurnAutoPilot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final invalidatedLease = _autoPilot.followUpIdentityGuard.handleSaveChange(
      _saveIdentity(widget.gameSave),
    );
    if (invalidatedLease != null) {
      _cancelTurnOpening(invalidatedLease);
    }
    _autoPilot.lifecycleCoordinator.handleSaveChange(
      previousSave: oldWidget.gameSave,
      currentSave: widget.gameSave,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _autoPilot.lifecycleCoordinator.handleLifecyclePaused(
      state != AppLifecycleState.resumed,
    );
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  void dispose() {
    _active = false;
    WidgetsBinding.instance.removeObserver(this);
    final invalidatedLease = _autoPilot.followUpIdentityGuard.invalidate();
    if (invalidatedLease != null) {
      _cancelTurnOpening(invalidatedLease);
    }
    _autoPilot.lifecycleCoordinator.dispose();
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
    _autoPilot.aiTurnAutoScheduler().evaluate(
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
    if (_canContinue) setState(() {});
  }

  void _cancelTurnOpening(TurnOpeningLease lease) {
    if (!mounted) return;
    ref
        .read(gamePlayerControlControllerProvider.notifier)
        .cancelTurnOpening(lease);
  }
}
