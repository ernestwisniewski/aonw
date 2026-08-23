import 'package:aonw_flutter/app/bootstrap/app_error_boundary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies framework and asynchronous process errors', () {
    final dispatcher = PlatformDispatcher.instance;
    final originalFlutterHandler = FlutterError.onError;
    final originalPlatformHandler = dispatcher.onError;
    void previousFlutterHandler(FlutterErrorDetails _) {}
    bool previousPlatformHandler(Object _, StackTrace _) => false;
    FlutterError.onError = previousFlutterHandler;
    dispatcher.onError = previousPlatformHandler;

    final reporter = _RecordingAppErrorReporter();
    final boundary = AppErrorBoundary.install(
      reporter: reporter,
      dispatcher: dispatcher,
    );
    addTearDown(() {
      boundary.dispose();
      FlutterError.onError = originalFlutterHandler;
      dispatcher.onError = originalPlatformHandler;
    });

    final frameworkError = StateError('framework');
    final frameworkStack = StackTrace.current;
    FlutterError.onError!(
      FlutterErrorDetails(exception: frameworkError, stack: frameworkStack),
    );

    final asynchronousError = StateError('asynchronous');
    final asynchronousStack = StackTrace.current;
    final handled = dispatcher.onError!(asynchronousError, asynchronousStack);

    expect(handled, isTrue);
    expect(reporter.reports, hasLength(2));
    expect(reporter.reports[0].kind, AppErrorKind.framework);
    expect(reporter.reports[0].kind.code, 'flutter_framework_error');
    expect(reporter.reports[0].error, same(frameworkError));
    expect(reporter.reports[0].stackTrace, same(frameworkStack));
    expect(reporter.reports[1].kind, AppErrorKind.asynchronous);
    expect(reporter.reports[1].kind.code, 'unhandled_async_error');
    expect(reporter.reports[1].error, same(asynchronousError));
    expect(reporter.reports[1].stackTrace, same(asynchronousStack));

    boundary.dispose();
    expect(FlutterError.onError, same(previousFlutterHandler));
    expect(dispatcher.onError, same(previousPlatformHandler));
  });
}

final class _RecordingAppErrorReporter implements AppErrorReporter {
  final reports = <AppErrorReport>[];

  @override
  void report(AppErrorReport report) => reports.add(report);
}
