import 'package:flutter/widgets.dart';

import '../composition/app_composition.dart';

void runAonwApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppComposition().build());
}
