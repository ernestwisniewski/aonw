import 'dart:async';

import 'package:flutter/widgets.dart';

class SelectedPanelItemRevealer extends StatefulWidget {
  const SelectedPanelItemRevealer({
    required this.selected,
    required this.child,
    this.alignment = 0.2,
    super.key,
  });

  final bool selected;
  final double alignment;
  final Widget child;

  @override
  State<SelectedPanelItemRevealer> createState() =>
      _SelectedPanelItemRevealerState();
}

class _SelectedPanelItemRevealerState extends State<SelectedPanelItemRevealer> {
  @override
  void initState() {
    super.initState();
    _revealIfSelected();
  }

  @override
  void didUpdateWidget(SelectedPanelItemRevealer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _revealIfSelected();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _revealIfSelected() {
    if (!widget.selected) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 120),
          alignment: widget.alignment,
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }
}
