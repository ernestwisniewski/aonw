import 'dart:ui';

import 'package:flutter/foundation.dart';

enum AppErrorKind {
  framework('flutter_framework_error'),
  asynchronous('unhandled_async_error');

  const AppErrorKind(this.code);

  final String code;
}

final class AppErrorReport {
  const AppErrorReport({
    required this.kind,
    required this.error,
    required this.stackTrace,
  });

  final AppErrorKind kind;
  final Object error;
  final StackTrace stackTrace;
}

abstract interface class AppErrorReporter {
  void report(AppErrorReport report);
}

final class DebugAppErrorReporter implements AppErrorReporter {
  const DebugAppErrorReporter();

  @override
  void report(AppErrorReport report) {
    debugPrintStack(
      label: 'AoNW client error [${report.kind.code}]: ${report.error}',
      stackTrace: report.stackTrace,
    );
  }
}

/// Owns the two process-level Flutter error callbacks installed at bootstrap.
final class AppErrorBoundary {
  AppErrorBoundary._({
    required AppErrorReporter reporter,
    required PlatformDispatcher dispatcher,
  }) : _reporter = reporter,
       _dispatcher = dispatcher,
       _previousFlutterHandler = FlutterError.onError,
       _previousPlatformHandler = dispatcher.onError {
    _flutterHandler = _handleFlutterError;
    _platformHandler = _handlePlatformError;
    FlutterError.onError = _flutterHandler;
    _dispatcher.onError = _platformHandler;
  }

  factory AppErrorBoundary.install({
    required AppErrorReporter reporter,
    PlatformDispatcher? dispatcher,
  }) => AppErrorBoundary._(
    reporter: reporter,
    dispatcher: dispatcher ?? PlatformDispatcher.instance,
  );

  final AppErrorReporter _reporter;
  final PlatformDispatcher _dispatcher;
  final FlutterExceptionHandler? _previousFlutterHandler;
  final ErrorCallback? _previousPlatformHandler;
  late final FlutterExceptionHandler _flutterHandler;
  late final ErrorCallback _platformHandler;
  var _disposed = false;

  void _handleFlutterError(FlutterErrorDetails details) {
    _reporter.report(
      AppErrorReport(
        kind: AppErrorKind.framework,
        error: details.exception,
        stackTrace: details.stack ?? StackTrace.current,
      ),
    );
  }

  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    _reporter.report(
      AppErrorReport(
        kind: AppErrorKind.asynchronous,
        error: error,
        stackTrace: stackTrace,
      ),
    );
    return true;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (identical(FlutterError.onError, _flutterHandler)) {
      FlutterError.onError = _previousFlutterHandler;
    }
    if (identical(_dispatcher.onError, _platformHandler)) {
      _dispatcher.onError = _previousPlatformHandler;
    }
  }
}
