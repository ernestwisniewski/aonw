import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _unitActionEngineHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'unit_action_engine_handler.dart';
const _domainUnitActionResolverPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'domain_unit_action_command_resolver.dart';

void main() {
  test('skip and fortify rules apply only through the game engine', () {
    final sources = productionDartSources();

    for (final methodName in const ['skipUnitTurn', 'fortifyUnit']) {
      expect(
        instanceMemberReferenceCountsByPath(
          sources,
          'DomainUnitActionCommandResolver',
          methodName,
        ),
        {_unitActionEngineHandlerPath: 1},
        reason:
            'The engine handler must own the single typed domain adapter '
            '$methodName reference.',
      );
      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'UnitActionCommandResolver',
          methodName,
        ),
        {_domainUnitActionResolverPath: 1},
        reason:
            'The domain adapter must own the single typed neutral kernel '
            '$methodName reference.',
      );
    }
  });

  test('unit action rule guard detects aliases, prefixes, and tear-offs', () {
    const restoredPath = 'lib/restored_unit_action_tear_off.dart';
    final widened = {
      ...productionDartSources(),
      restoredPath: '''
typedef DomainResolver = DomainUnitActionCommandResolver;
typedef UnitKernel = UnitActionCommandResolver;

void restoreLegacy(DomainResolver resolver) {
  final domainSkip = resolver.skipUnitTurn;
  final domainFortify = resolver.fortifyUnit;
  final kernelSkip = UnitKernel.skipUnitTurn;
  final kernelFortify = core.UnitActionCommandResolver.fortifyUnit;
}
''',
    };

    for (final methodName in const ['skipUnitTurn', 'fortifyUnit']) {
      expect(
        instanceMemberReferenceCountsByPath(
          widened,
          'DomainUnitActionCommandResolver',
          methodName,
        ),
        {_unitActionEngineHandlerPath: 1, restoredPath: 1},
      );
      expect(
        staticMemberReferenceCountsByPath(
          widened,
          'UnitActionCommandResolver',
          methodName,
        ),
        {_domainUnitActionResolverPath: 1, restoredPath: 1},
      );
    }
  });
}
