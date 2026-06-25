import 'package:aonw/menu/app_exit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exitApplication pops the system navigator outside iOS', () async {
    var popped = false;

    await exitApplication(
      platform: TargetPlatform.android,
      systemPop: () async => popped = true,
    );

    expect(popped, isTrue);
  });

  test('exitApplication terminates the process on iOS', () async {
    var exitCode = -1;
    var popped = false;

    await expectLater(
      exitApplication(
        platform: TargetPlatform.iOS,
        exitProcess: (code) {
          exitCode = code;
          throw const _ExitIntercepted();
        },
        systemPop: () async => popped = true,
      ),
      throwsA(isA<_ExitIntercepted>()),
    );

    expect(exitCode, 0);
    expect(popped, isFalse);
  });
}

class _ExitIntercepted implements Exception {
  const _ExitIntercepted();
}
