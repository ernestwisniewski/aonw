import 'package:flutter/material.dart';

import '../../design_system/widgets/aonw_panel.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/map/presentation/widgets/map_screen.dart';
import '../../features/settings/presentation/client_settings_controller.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../game/aonw_flame_game.dart';
import '../../l10n/l10n.dart';

enum AonwRoute {
  map('/'),
  settings('/settings');

  const AonwRoute(this.location);

  final String location;

  static AonwRoute? fromLocation(String? location) {
    for (final route in values) {
      if (route.location == location) return route;
    }
    return null;
  }
}

final class AonwRouter {
  const AonwRouter({
    required this.mapController,
    required this.settingsController,
    required this.flameGameFactory,
    required this.routeObserver,
    this.mapInputSource,
  });

  final MapPresentationController mapController;
  final ClientSettingsController settingsController;
  final AonwFlameGameFactory flameGameFactory;
  final RouteObserver<ModalRoute<void>> routeObserver;
  final MapInputSource? mapInputSource;

  Route<void> onGenerateRoute(RouteSettings settings) {
    final route = AonwRoute.fromLocation(settings.name);
    return MaterialPageRoute<void>(
      settings: settings,
      builder: switch (route) {
        AonwRoute.map => (context) => Scaffold(
          body: SafeArea(
            child: MapScreen(
              controller: mapController,
              inputSource: mapInputSource,
              flameGameFactory: flameGameFactory,
              routeObserver: routeObserver,
              onOpenSettings: () =>
                  Navigator.of(context).pushNamed(AonwRoute.settings.location),
            ),
          ),
        ),
        AonwRoute.settings => (_) => SettingsScreen(
          controller: settingsController,
        ),
        null => (_) => _UnknownRoute(location: settings.name),
      },
    );
  }
}

final class _UnknownRoute extends StatelessWidget {
  const _UnknownRoute({required this.location});

  final String? location;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AonwMessagePanel(
            key: const ValueKey('unknown-route'),
            semanticLabel: l10n.unknownRouteLabel,
            title: l10n.pageUnavailable,
            message: l10n.unknownRouteMessage(
              location ?? l10n.missingRouteLocation,
            ),
          ),
        ),
      ),
    );
  }
}
