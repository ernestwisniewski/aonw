import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local Docker and Flutter defaults use the stable OAuth ports', () {
    final makefile = File('Makefile').readAsStringSync();
    final compose = File('compose.yml').readAsStringSync();
    final environment = _environment(File('.env.example'));

    expect(
      makefile,
      contains(
        'LOCAL_API_BASE_URL ?= http://\$(LOCAL_API_HOST):\$(LOCAL_API_PORT)',
      ),
    );
    expect(makefile, contains('LOCAL_API_PORT ?= 8080'));
    expect(makefile, contains('LOCAL_WEB_PORT ?= 7357'));
    expect(makefile, contains('--web-hostname "\$(LOCAL_WEB_HOST)"'));
    expect(makefile, contains('--web-port "\$(LOCAL_WEB_PORT)"'));
    expect(makefile, contains('AONW_API_BASE_URL=\$(LOCAL_API_BASE_URL)'));
    expect(
      compose,
      contains(
        r'${AONW_SERVER_PUBLIC_PORT:-8080}:'
        r'${SERVERPOD_API_SERVER_PORT:-8080}',
      ),
    );

    expect(environment['SERVERPOD_RUN_MODE'], 'development');
    expect(environment['SERVERPOD_SERVER_ID'], 'local');
    expect(environment['SERVERPOD_API_SERVER_PUBLIC_HOST'], 'localhost');
    expect(environment['SERVERPOD_API_SERVER_PUBLIC_PORT'], '8080');
    expect(environment['SERVERPOD_API_SERVER_PUBLIC_SCHEME'], 'http');
    expect(environment['AONW_API_BASE_URL'], 'http://localhost:8080');
  });
}

Map<String, String> _environment(File file) {
  return {
    for (final line in file.readAsLinesSync())
      if (line.isNotEmpty && !line.startsWith('#') && line.contains('='))
        line.substring(0, line.indexOf('=')): line.substring(
          line.indexOf('=') + 1,
        ),
  };
}
