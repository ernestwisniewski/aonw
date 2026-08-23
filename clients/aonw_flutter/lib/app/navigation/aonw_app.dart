import 'package:flutter/material.dart';

import '../../design_system/aonw_theme.dart';
import '../../features/map/application/map_controller.dart';
import '../../features/map/presentation/widgets/map_screen.dart';

final class AonwApp extends StatefulWidget {
  const AonwApp({required this.mapController, super.key});

  final MapController mapController;

  @override
  State<AonwApp> createState() => _AonwAppState();
}

final class _AonwAppState extends State<AonwApp> {
  @override
  void didUpdateWidget(AonwApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController != widget.mapController) {
      oldWidget.mapController.dispose();
    }
  }

  @override
  void dispose() {
    widget.mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Age of New Worlds',
    debugShowCheckedModeBanner: false,
    theme: AonwTheme.dark,
    home: Scaffold(
      body: SafeArea(child: MapScreen(controller: widget.mapController)),
    ),
  );
}
