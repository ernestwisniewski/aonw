import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef ProcessExit = Never Function(int code);
typedef SystemPop = Future<void> Function();

Future<void> exitApplication({
  TargetPlatform? platform,
  ProcessExit? exitProcess,
  SystemPop? systemPop,
}) async {
  final targetPlatform = platform ?? defaultTargetPlatform;
  if (targetPlatform == TargetPlatform.iOS) {
    (exitProcess ?? io.exit)(0);
  }
  await (systemPop ?? SystemNavigator.pop)();
}
