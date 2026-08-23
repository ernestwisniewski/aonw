import 'dart:async';

import 'package:flutter/material.dart';

import '../../design_system/aonw_theme.dart';
import '../../features/map/application/map_controller.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../l10n/l10n.dart';
import 'aonw_router.dart';

final class AonwApp extends StatefulWidget {
  const AonwApp({
    required this.mapController,
    this.mapInputSource,
    this.locale,
    super.key,
  });

  final MapController mapController;
  final MapInputSource? mapInputSource;
  final Locale? locale;

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
    if (oldWidget.mapInputSource != widget.mapInputSource) {
      unawaited(oldWidget.mapInputSource?.close());
    }
  }

  @override
  void dispose() {
    widget.mapController.dispose();
    unawaited(widget.mapInputSource?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = AonwRouter(
      mapController: widget.mapController,
      mapInputSource: widget.mapInputSource,
    );
    return MaterialApp(
      key: ValueKey(widget.mapController),
      onGenerateTitle: (context) => context.aonwL10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AonwTheme.dark,
      locale: widget.locale,
      localizationsDelegates: AonwLocalizations.localizationsDelegates,
      supportedLocales: AonwLocalizations.supportedLocales,
      initialRoute: AonwRoute.map.location,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
