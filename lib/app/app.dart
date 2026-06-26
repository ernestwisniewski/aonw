import 'dart:async';

import 'package:aonw/app/router.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/providers/audio/game_audio_provider.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/performance/dev_performance.dart';
import 'package:aonw/shared/performance/fps_counter_overlay.dart';
import 'package:aonw/shared/providers/accessibility_settings_provider.dart';
import 'package:aonw/shared/providers/language_settings_provider.dart';
import 'package:aonw/shared/providers/performance_settings_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HexApp extends ConsumerStatefulWidget {
  const HexApp({super.key});

  @override
  ConsumerState<HexApp> createState() => _HexAppState();
}

class _HexAppState extends ConsumerState<HexApp> {
  late final GameAudioController _audioController;

  @override
  void initState() {
    super.initState();
    _audioController = ref.read(gameAudioControllerProvider);
    unawaited(_audioController.startMusicLoop());
  }

  @override
  void dispose() {
    unawaited(_audioController.stopMusicLoop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final accessibility = ref.watch(accessibilitySettingsProvider);
    final language = ref.watch(languageSettingsProvider);
    final performance = ref.watch(performanceSettingsProvider);
    final mapZoom = performance.showMapZoom
        ? ref.watch(mapZoomDebugProvider)
        : null;
    final showPerformanceOverlay =
        performance.showFps || (performance.showMapZoom && mapZoom != null);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: DevPerformance.isEnabled,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: language.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GameUiTheme.gold,
          brightness: Brightness.dark,
          surface: GameUiTheme.surface,
        ),
        fontFamily: GameUiTheme.bodyFont,
        scaffoldBackgroundColor: GameUiTheme.bg,
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: GameUiTheme.surfaceDeep.withAlpha(242),
          contentTextStyle: GameUiTheme.bodyStrong.copyWith(
            color: GameUiTheme.textPrimary,
            fontSize: 13,
          ),
          actionTextColor: GameUiTheme.goldLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: GameUiTheme.gold.withAlpha(130)),
          ),
        ),
        tooltipTheme: TooltipThemeData(
          triggerMode: TooltipTriggerMode.longPress,
          waitDuration: const Duration(milliseconds: 450),
          showDuration: const Duration(seconds: 5),
          preferBelow: false,
          verticalOffset: 16,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: GameUiTheme.bg.withAlpha(242),
            borderRadius: GameUiTheme.borderRadius,
            border: Border.all(color: GameUiTheme.gold.withAlpha(120)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          textStyle: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return _GlobalTextScale(
          textScaleFactor: accessibility.textScaleFactor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              if (showPerformanceOverlay)
                Positioned.fill(
                  child: _GlobalFpsOverlay(
                    showFps: performance.showFps,
                    showMapZoom: performance.showMapZoom,
                    mapZoom: mapZoom,
                  ),
                ),
            ],
          ),
        );
      },
      routerConfig: router,
    );
  }
}

class _GlobalFpsOverlay extends StatelessWidget {
  const _GlobalFpsOverlay({
    required this.showFps,
    required this.showMapZoom,
    required this.mapZoom,
  });

  final bool showFps;
  final bool showMapZoom;
  final double? mapZoom;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.bottomRight,
          child: FpsCounterOverlay(
            showFps: showFps,
            showMapZoom: showMapZoom,
            mapZoom: mapZoom,
          ),
        ),
      ),
    );
  }
}

class _GlobalTextScale extends StatelessWidget {
  final double textScaleFactor;
  final Widget child;

  const _GlobalTextScale({required this.textScaleFactor, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return child;

    final platformScale = mediaQuery.textScaler.scale(1);
    final combinedScale = (platformScale * textScaleFactor).clamp(0.85, 1.65);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(combinedScale.toDouble()),
      ),
      child: child,
    );
  }
}
