import 'package:flutter/widgets.dart';

import '../composition/app_composition.dart';
import 'app_error_boundary.dart';

void runAonwApp({
  AppErrorReporter errorReporter = const DebugAppErrorReporter(),
}) {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorBoundary.install(reporter: errorReporter);
  runApp(AppComposition.production().root);
}
