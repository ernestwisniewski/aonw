part of 'hud_victory_status_summary.dart';

class HudVictoryStatusDetail {
  final String label;
  final String value;
  final bool highlighted;

  const HudVictoryStatusDetail({
    required this.label,
    required this.value,
    this.highlighted = false,
  });
}
