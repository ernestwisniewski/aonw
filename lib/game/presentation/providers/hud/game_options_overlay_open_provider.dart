import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gameOptionsOverlayOpenProvider =
    NotifierProvider.family<GameOptionsOverlayOpenController, bool, String>(
      GameOptionsOverlayOpenController.new,
    );

class GameOptionsOverlayOpenController extends Notifier<bool> {
  GameOptionsOverlayOpenController(this.saveId);

  final String saveId;

  @override
  bool build() => false;

  void setOpen(bool value) {
    if (state != value) state = value;
  }
}

class GameOptionsOverlayOpenPublisher extends ConsumerStatefulWidget {
  const GameOptionsOverlayOpenPublisher({
    required this.saveId,
    required this.active,
    super.key,
  });

  final String saveId;
  final bool active;

  @override
  ConsumerState<GameOptionsOverlayOpenPublisher> createState() =>
      _GameOptionsOverlayOpenPublisherState();
}

class _GameOptionsOverlayOpenPublisherState
    extends ConsumerState<GameOptionsOverlayOpenPublisher> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setOpen(widget.active);
    });
    return const SizedBox.shrink();
  }

  void _setOpen(bool active) {
    if (widget.saveId.isEmpty) return;
    ref
        .read(gameOptionsOverlayOpenProvider(widget.saveId).notifier)
        .setOpen(active);
  }
}
