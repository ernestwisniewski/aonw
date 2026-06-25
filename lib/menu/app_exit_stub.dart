import 'package:flutter/services.dart';

typedef ProcessExit = Never Function(int code);
typedef SystemPop = Future<void> Function();

Future<void> exitApplication({
  TargetPlatform? platform,
  ProcessExit? exitProcess,
  SystemPop? systemPop,
}) async {
  await (systemPop ?? SystemNavigator.pop)();
}
