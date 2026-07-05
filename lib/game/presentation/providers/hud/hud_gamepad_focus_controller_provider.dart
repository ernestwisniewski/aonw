import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hudGamepadFocusControllerProvider =
    NotifierProvider<HudGamepadFocusController, HudGamepadFocusState>(
      HudGamepadFocusController.new,
    );

final hudGamepadFocusTargetRegistryProvider =
    NotifierProvider<
      HudGamepadFocusTargetRegistry,
      Map<String, List<HudGamepadFocusTarget>>
    >(HudGamepadFocusTargetRegistry.new);

final hudGamepadPopupInputCaptureProvider =
    NotifierProvider<HudGamepadPopupInputCaptureController, bool>(
      HudGamepadPopupInputCaptureController.new,
    );

class HudGamepadPopupInputCaptureController extends Notifier<bool> {
  final Set<String> _capturedSources = {};

  @override
  bool build() => false;

  void setCaptured(bool captured) {
    setSourceCaptured('default', captured);
  }

  void setSourceCaptured(String sourceId, bool captured) {
    if (captured) {
      _capturedSources.add(sourceId);
    } else {
      _capturedSources.remove(sourceId);
    }
    final next = _capturedSources.isNotEmpty;
    if (state == next) return;
    state = next;
  }
}
