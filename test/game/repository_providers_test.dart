import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _configuredApiBaseUrl = String.fromEnvironment('AONW_API_BASE_URL');

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'API config uses compile-time override when provided',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(apiConfigProvider);

      expect(config.baseUrl.toString(), _configuredApiBaseUrl);
    },
    skip: _configuredApiBaseUrl.isEmpty
        ? 'No AONW_API_BASE_URL dart-define was provided.'
        : false,
  );

  test(
    'default API config targets localhost for local builds',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(apiConfigProvider);

      expect(config.baseUrl.toString(), 'http://localhost:8080');
    },
    skip: _configuredApiBaseUrl.isNotEmpty,
  );

  test(
    'default API config uses Android emulator host alias',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(apiConfigProvider);

      expect(config.baseUrl.toString(), 'http://10.0.2.2:8080');
    },
    skip: _configuredApiBaseUrl.isNotEmpty,
  );
}
