import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';

enum SelectionInfoChipTone { neutral, accent, warning }

class SelectionInfoChipViewModel {
  final String id;
  final GameIconData icon;
  final String label;
  final String? badge;
  final SelectionInfoChipTone tone;
  final bool enabled;

  const SelectionInfoChipViewModel({
    required this.id,
    required this.icon,
    required this.label,
    this.badge,
    this.tone = SelectionInfoChipTone.neutral,
    this.enabled = true,
  });
}
