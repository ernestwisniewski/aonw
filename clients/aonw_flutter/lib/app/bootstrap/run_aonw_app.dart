import 'package:flutter/widgets.dart';

import '../composition/app_composition.dart';

void runAonwApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppComposition.production().root);
}
