import 'dart:async';

import 'package:flutter/material.dart';

import '../../design_system/aonw_theme.dart';
import '../../features/map/application/map_controller.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/settings/application/client_settings_controller.dart';
import '../../features/settings/presentation/client_settings_scope.dart';
import '../../l10n/l10n.dart';
import 'aonw_router.dart';

final class AonwApp extends StatefulWidget {
  const AonwApp({
    required this.mapController,
    this.mapInputSource,
    this.settingsController,
    this.locale,
    super.key,
  });

  final MapController mapController;
  final MapInputSource? mapInputSource;
  final ClientSettingsController? settingsController;
  final Locale? locale;

  @override
  State<AonwApp> createState() => _AonwAppState();
}

final class _AonwAppState extends State<AonwApp> with WidgetsBindingObserver {
  late ClientSettingsController _settingsController;
  late AppLifecycleState _lifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _installSettingsController();
    _synchronizeInputLifecycle();
  }

  @override
  void didUpdateWidget(AonwApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController != widget.mapController) {
      oldWidget.mapController.dispose();
    }
    if (oldWidget.mapInputSource != widget.mapInputSource) {
      _setInputActive(oldWidget.mapInputSource, false);
      unawaited(oldWidget.mapInputSource?.close());
      _synchronizeInputLifecycle();
    }
    if (oldWidget.settingsController != widget.settingsController) {
      _settingsController.dispose();
      _installSettingsController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setInputActive(widget.mapInputSource, false);
    widget.mapController.dispose();
    unawaited(widget.mapInputSource?.close());
    _settingsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _synchronizeInputLifecycle();
  }

  @override
  Widget build(BuildContext context) {
    final router = AonwRouter(
      mapController: widget.mapController,
      mapInputSource: widget.mapInputSource,
      settingsController: _settingsController,
    );
    return ClientSettingsScope(
      controller: _settingsController,
      child: ListenableBuilder(
        listenable: _settingsController,
        builder: (context, child) => MaterialApp(
          key: ValueKey(widget.mapController),
          onGenerateTitle: (context) => context.aonwL10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AonwTheme.darkFor(
            highContrast: _settingsController.settings.highContrast,
          ),
          locale: widget.locale,
          localizationsDelegates: AonwLocalizations.localizationsDelegates,
          supportedLocales: AonwLocalizations.supportedLocales,
          initialRoute: AonwRoute.map.location,
          onGenerateRoute: router.onGenerateRoute,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                disableAnimations:
                    media.disableAnimations ||
                    _settingsController.settings.reducedMotion,
                highContrast:
                    media.highContrast ||
                    _settingsController.settings.highContrast,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  void _installSettingsController() {
    _settingsController =
        widget.settingsController ?? ClientSettingsController.ephemeral();
    unawaited(_settingsController.load());
  }

  void _synchronizeInputLifecycle() {
    _setInputActive(
      widget.mapInputSource,
      _lifecycleState == AppLifecycleState.resumed,
    );
  }

  static void _setInputActive(MapInputSource? source, bool active) {
    if (source case final LifecycleAwareMapInputSource lifecycleAware) {
      lifecycleAware.setActive(active);
    }
  }
}
