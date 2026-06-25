import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScopedRendererCommandDispatcher extends ConsumerStatefulWidget {
  const ScopedRendererCommandDispatcher({
    required this.session,
    required this.onDispatcherChanged,
    required this.child,
    super.key,
  });

  final GameSession session;
  final ValueChanged<Future<void> Function(GameCommand command)?>
  onDispatcherChanged;
  final Widget child;

  @override
  ConsumerState<ScopedRendererCommandDispatcher> createState() =>
      _ScopedRendererCommandDispatcherState();
}

class _ScopedRendererCommandDispatcherState
    extends ConsumerState<ScopedRendererCommandDispatcher> {
  late final Future<void> Function(GameCommand command) _dispatcher = _dispatch;

  @override
  void initState() {
    super.initState();
    widget.onDispatcherChanged(_dispatcher);
  }

  @override
  void didUpdateWidget(ScopedRendererCommandDispatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onDispatcherChanged != widget.onDispatcherChanged) {
      oldWidget.onDispatcherChanged(null);
      widget.onDispatcherChanged(_dispatcher);
    }
  }

  @override
  void dispose() {
    widget.onDispatcherChanged(null);
    super.dispose();
  }

  Future<void> _dispatch(GameCommand command) async {
    if (widget.session.saveId.isEmpty) return;
    await ref.read(gameCommandControllerProvider.notifier).dispatch(command);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
