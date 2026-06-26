import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HUD-level widgets do not expose domain action callbacks', () {
    expect(
      _domainCallbackViolations(const {
        'lib/game/presentation/widgets/hud/game_hud.dart',
        'lib/game/presentation/widgets/hud/overlay/game_hud_overlay_host.dart',
        'lib/game/presentation/widgets/hud/action_deck/hud_action_deck.dart',
        'lib/game/presentation/widgets/hud/overlay/hud_overlay_panels.dart',
      }),
      isEmpty,
    );
  });
}

List<String> _domainCallbackViolations(Set<String> paths) {
  final violations = <String>[];
  const disallowedNames = {
    'onActivityLogEntrySelected',
    'onBuildCityBuilding',
    'onDetachTroop',
    'onEmpireCitySelected',
    'onEmpireUnitSelected',
    'onEndTurn',
    'onNextAction',
    'onProduceCityUnit',
    'onResearchTechnology',
    'onRushCityProduction',
    'onSetCitySpecialization',
    'onStartCityProject',
    'onToggleActivityLogPanel',
  };

  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    for (final name in disallowedNames) {
      if (RegExp(
        r'\b(final|required this\.)'
        '$name'
        r'\b',
      ).hasMatch(content)) {
        violations.add('$path exposes $name instead of HudCommandDispatcher');
      }
    }
    if (path.endsWith('hud_overlay_panels.dart') &&
        RegExp(
          r'^typedef\s+\w+Action\s*=',
          multiLine: true,
        ).hasMatch(content)) {
      violations.add('$path declares domain action typedefs');
    }
  }

  return violations;
}
