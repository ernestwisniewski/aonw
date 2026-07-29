import 'dart:convert';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'rush_production_test_support.dart';

part 'rush_production_command_resolver_test_support.dart';
part 'rush_production_command_resolver_accepted_test_support.dart';

void main() {
  group('RushProductionCommandResolver', () {
    final rejections = _rushKernelRejections();

    test('exposes the exact rejection vocabulary', () {
      expect(rejections.map((scenario) => scenario.reason).toSet(), {
        'city_not_found',
        'city_not_controlled',
        'production_queue_empty',
        'project_cannot_be_rushed',
        'rush_production_unavailable',
      });
    });

    for (final rejection in rejections) {
      test(rejection.name, () => _expectRushKernelParity(rejection));
    }

    for (final acceptance in _acceptedRushKernelScenarios()) {
      test(acceptance.name, () => _expectRushKernelParity(acceptance));
    }
  });
}
