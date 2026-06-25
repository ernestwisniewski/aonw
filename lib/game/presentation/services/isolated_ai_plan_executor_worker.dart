import 'dart:async';
import 'dart:isolate';

import 'package:aonw/game/presentation/services/ai_plan_executor_protocol.dart';
import 'package:aonw_core/ai.dart';

final _foregroundWorker = _PersistentAiPlanWorker();
final _precomputeWorker = _PersistentAiPlanWorker();

Future<AiTurnPlan> executeAiPlan({
  required AiStrategy strategy,
  required GameView view,
  required AiContext context,
}) {
  return _foregroundWorker.execute(
    AiPlanRequest(strategy: strategy, view: view, context: context),
  );
}

Future<AiTurnPlan> precomputeAiPlan({
  required AiStrategy strategy,
  required GameView view,
  required AiContext context,
}) {
  return _precomputeWorker.execute(
    AiPlanRequest(strategy: strategy, view: view, context: context),
  );
}

Future<void> shutdownAiPlanExecutorForTesting() {
  return Future.wait([
    _foregroundWorker.shutdown(),
    _precomputeWorker.shutdown(),
  ]).then((_) {});
}

class _PersistentAiPlanWorker {
  final Set<_PendingAiPlanRequest> _pending = {};
  Isolate? _isolate;
  SendPort? _sendPort;
  Future<SendPort>? _starting;
  int _generation = 0;

  Future<AiTurnPlan> execute(AiPlanRequest request) async {
    final sendPort = await _ensureStarted();
    final replyPort = ReceivePort('AI planning reply');
    final pending = _PendingAiPlanRequest(replyPort);
    _pending.add(pending);
    pending.subscription = replyPort.listen((response) {
      _completePending(pending, response);
    });

    try {
      sendPort.send(_AiPlanWorkerRequest(request, replyPort.sendPort));
      return await pending.completer.future;
    } finally {
      await _cleanupPending(pending);
    }
  }

  Future<void> shutdown() async {
    _generation += 1;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _starting = null;
    final pending = _pending.toList(growable: false);
    for (final request in pending) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          StateError('AI planning worker shut down'),
        );
      }
      await _cleanupPending(request);
    }
  }

  Future<SendPort> _ensureStarted() async {
    final existing = _sendPort;
    if (existing != null) return existing;

    final starting = _starting;
    if (starting != null) return starting;

    final generation = _generation;
    final readyPort = ReceivePort('AI planning worker ready');
    final future = () async {
      try {
        final isolate = await Isolate.spawn(
          _aiPlanWorkerMain,
          readyPort.sendPort,
          debugName: 'AI planning worker',
        );
        final sendPort = await readyPort.first as SendPort;
        if (_generation != generation) {
          isolate.kill(priority: Isolate.immediate);
          throw StateError('AI planning worker shut down');
        }
        _isolate = isolate;
        _sendPort = sendPort;
        return sendPort;
      } finally {
        readyPort.close();
        _starting = null;
      }
    }();

    _starting = future;
    return future;
  }

  void _completePending(_PendingAiPlanRequest pending, Object? response) {
    if (pending.completer.isCompleted) return;
    switch (response) {
      case _AiPlanWorkerSuccess(:final plan):
        pending.completer.complete(plan);
      case _AiPlanWorkerFailure(:final message, :final stackTrace):
        pending.completer.completeError(StateError('$message\n$stackTrace'));
      default:
        pending.completer.completeError(
          StateError('Unexpected AI worker response: $response'),
        );
    }
  }

  Future<void> _cleanupPending(_PendingAiPlanRequest pending) async {
    if (!_pending.remove(pending)) return;
    await pending.subscription?.cancel();
    pending.replyPort.close();
  }
}

class _PendingAiPlanRequest {
  final ReceivePort replyPort;
  final Completer<AiTurnPlan> completer = Completer<AiTurnPlan>();
  StreamSubscription<Object?>? subscription;

  _PendingAiPlanRequest(this.replyPort);
}

class _AiPlanWorkerRequest {
  final AiPlanRequest request;
  final SendPort replyPort;

  const _AiPlanWorkerRequest(this.request, this.replyPort);
}

class _AiPlanWorkerSuccess {
  final AiTurnPlan plan;

  const _AiPlanWorkerSuccess(this.plan);
}

class _AiPlanWorkerFailure {
  final String message;
  final String stackTrace;

  const _AiPlanWorkerFailure(this.message, this.stackTrace);
}

void _aiPlanWorkerMain(SendPort readyPort) {
  final commandPort = ReceivePort('AI planning worker commands');
  readyPort.send(commandPort.sendPort);

  commandPort.listen((message) {
    if (message is! _AiPlanWorkerRequest) return;
    try {
      final plan = planAiTurnInBackground(message.request);
      message.replyPort.send(_AiPlanWorkerSuccess(plan));
    } catch (error, stackTrace) {
      message.replyPort.send(
        _AiPlanWorkerFailure(error.toString(), stackTrace.toString()),
      );
    }
  });
}
