import 'dart:io';

import 'cli.dart';
import 'model.dart';

void main(List<String> arguments) {
  if (arguments.length == 1 && arguments.single == '--help') {
    stdout.write(releasePlanUsage);
    return;
  }
  try {
    stdout.writeln(ReleasePlanCommand.parse(arguments).render());
  } on ReleasePlanException catch (error) {
    stderr
      ..writeln('Release plan failed: ${error.message}')
      ..write(releasePlanUsage);
    exitCode = 64;
  }
}
