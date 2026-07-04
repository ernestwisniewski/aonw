import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_event_mapper.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

final class GamepadInputAdapter {
  GamepadInputAdapter({GamepadEventMapper mapper = const GamepadEventMapper()})
    : _mapper = mapper;

  final GamepadEventMapper _mapper;
  final ValueNotifier<GamepadInputSnapshot> snapshot =
      ValueNotifier<GamepadInputSnapshot>(GamepadInputSnapshot.empty);

  StreamSubscription<NormalizedGamepadEvent>? _subscription;
  String? _activeGamepadId;

  void start() {
    if (_subscription != null) return;
    _subscription = Gamepads.normalizedEvents.listen(_handleEvent);
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    snapshot.dispose();
  }

  void _handleEvent(NormalizedGamepadEvent event) {
    if (!_accepts(event)) return;
    final next = _mapper.apply(snapshot.value, event);
    if (next == snapshot.value) return;
    snapshot.value = next;
  }

  bool _accepts(NormalizedGamepadEvent event) {
    final current = _activeGamepadId;
    if (current == null) {
      _activeGamepadId = event.gamepadId;
      return true;
    }
    if (current == event.gamepadId) return true;

    final shouldSwitch = event.value.abs() > 0.5;
    if (!shouldSwitch) return false;
    _activeGamepadId = event.gamepadId;
    snapshot.value = GamepadInputSnapshot.empty;
    return true;
  }
}
