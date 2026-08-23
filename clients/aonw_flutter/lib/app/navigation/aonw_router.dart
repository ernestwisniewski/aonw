import 'package:flutter/material.dart';

import '../../design_system/widgets/aonw_panel.dart';
import '../../features/map/application/map_controller.dart';
import '../../features/map/presentation/widgets/map_screen.dart';
import '../../l10n/l10n.dart';

enum AonwRoute {
  map('/');

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
  const AonwRouter({required this.mapController});

  final MapController mapController;

  Route<void> onGenerateRoute(RouteSettings settings) {
    final route = AonwRoute.fromLocation(settings.name);
    return MaterialPageRoute<void>(
      settings: settings,
      builder: switch (route) {
        AonwRoute.map => (_) => Scaffold(
          body: SafeArea(child: MapScreen(controller: mapController)),
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
