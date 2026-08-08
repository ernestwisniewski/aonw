part of 'hud_selection_actions.dart';

List<Widget> _widgetsFromActionGroups(
  List<List<HudSelectionActionSpec>> groups,
) {
  final widgets = <Widget>[];
  for (final group in groups) {
    if (group.isEmpty) continue;
    if (widgets.isNotEmpty) {
      widgets.add(const SelectionActionGroupBreak());
    }
    widgets.addAll([for (final spec in group) spec.toChip()]);
  }
  return widgets;
}
