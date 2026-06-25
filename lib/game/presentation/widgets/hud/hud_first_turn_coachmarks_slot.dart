import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_step.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmarks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HudFirstTurnCoachmarksSlot extends StatelessWidget {
  const HudFirstTurnCoachmarksSlot({
    required this.saveId,
    required this.active,
    required this.enabled,
    required this.initialCameraFocusReadyListenable,
    required this.hasSelectionActions,
    required this.readyToEndTurn,
    required this.coachmarkContext,
    super.key,
  });

  final String saveId;
  final bool active;
  final bool enabled;
  final ValueListenable<bool> initialCameraFocusReadyListenable;
  final bool hasSelectionActions;
  final bool readyToEndTurn;
  final FirstTurnCoachmarkContext coachmarkContext;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: initialCameraFocusReadyListenable,
      builder: (context, initialCameraFocusReady, _) {
        return FirstTurnCoachmarksOverlay(
          saveId: saveId,
          active: active,
          enabled: enabled && initialCameraFocusReady,
          hasSelectionActions: hasSelectionActions,
          readyToEndTurn: readyToEndTurn,
          coachmarkContext: coachmarkContext,
        );
      },
    );
  }
}
