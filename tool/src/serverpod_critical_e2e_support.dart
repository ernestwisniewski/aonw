import 'dart:async';
import 'dart:io';

import 'package:aonw_server_client/aonw_server_client.dart' as sp;

final class CriticalMatchStream {
  CriticalMatchStream._({
    required StreamController<sp.MultiplayerClientMessage> input,
    required StreamIterator<sp.MultiplayerServerMessage> output,
    required this.timeout,
  }) : _input = input,
       _output = output;

  final StreamController<sp.MultiplayerClientMessage> _input;
  final StreamIterator<sp.MultiplayerServerMessage> _output;
  final Duration timeout;
  late final sp.MultiplayerServerMessage initialMessage;
  bool _closed = false;

  static Future<CriticalMatchStream> open({
    required sp.Client client,
    required String matchId,
    required int afterOffset,
    required Duration timeout,
  }) async {
    final input = StreamController<sp.MultiplayerClientMessage>();
    final output = StreamIterator(
      client.multiplayer.connect(matchId, afterOffset, input.stream),
    );
    final connection = CriticalMatchStream._(
      input: input,
      output: output,
      timeout: timeout,
    );
    try {
      final initialMessage = await connection._next(
        context: 'initial stream message',
      );
      if (initialMessage.snapshot == null ||
          initialMessage.event != null ||
          initialMessage.ack != null) {
        throw StateError(
          'Match stream must start with a snapshot message before any event '
          'or ACK.',
        );
      }
      connection.initialMessage = initialMessage;
      return connection;
    } catch (_) {
      try {
        await connection.close();
      } catch (_) {
        // Preserve the connection contract failure instead of replacing it
        // with a secondary cleanup failure.
      }
      rethrow;
    }
  }

  void send(sp.MultiplayerClientMessage message) {
    if (_closed) throw StateError('Cannot send to a closed match stream.');
    _input.add(message);
  }

  Future<sp.MultiplayerServerMessage> nextAck() async {
    final message = await _next(context: 'command ACK');
    if (message.ack == null ||
        message.match != null ||
        message.snapshot != null ||
        message.event != null) {
      throw StateError(
        'Expected the next match stream message to contain only a command ACK.',
      );
    }
    return message;
  }

  Future<sp.MultiplayerServerMessage> _next({required String context}) async {
    final hasNext = await _output.moveNext().timeout(
      timeout,
      onTimeout: () => throw TimeoutException('Waiting for $context.', timeout),
    );
    if (!hasNext) {
      throw StateError('Match stream ended before $context.');
    }
    return _output.current;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await Future.wait([
      if (!_input.isClosed)
        _closeWithin(_input.close(), context: 'match stream input'),
      _closeWithin(_output.cancel(), context: 'match stream output'),
    ], eagerError: false);
  }

  Future<void> _closeWithin(Future<void> operation, {required String context}) {
    return operation.timeout(
      timeout,
      onTimeout: () => throw TimeoutException('Closing $context.', timeout),
    );
  }
}

final class CriticalE2eConfig {
  const CriticalE2eConfig({
    required this.host,
    required this.mapName,
    required this.requestTimeout,
    required this.streamTimeout,
  });

  final String host;
  final String mapName;
  final Duration requestTimeout;
  final Duration streamTimeout;

  static const usage = '''
Usage:
  dart run tool/serverpod_critical_e2e.dart [options]

Options:
  --host URL   Serverpod API host. Default: http://127.0.0.1:18080/
  --map NAME   Bundled multiplayer map. Default: myranth
''';

  factory CriticalE2eConfig.fromArgs(List<String> args) {
    final options = <String, String>{};
    for (var index = 0; index < args.length; index += 1) {
      final argument = args[index];
      if (argument == '--help' || argument == '-h') {
        stdout.write(usage);
        exit(0);
      }
      if (!argument.startsWith('--')) {
        throw FormatException('Unexpected argument: $argument');
      }
      final equals = argument.indexOf('=');
      if (equals != -1) {
        options[argument.substring(2, equals)] = argument.substring(equals + 1);
        continue;
      }
      if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
        throw FormatException('Missing value for $argument');
      }
      options[argument.substring(2)] = args[index + 1];
      index += 1;
    }
    final unknown = options.keys.where((key) => key != 'host' && key != 'map');
    if (unknown.isNotEmpty) {
      throw FormatException('Unknown option: --${unknown.first}');
    }
    final mapName = options['map'] ?? 'myranth';
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(mapName)) {
      throw FormatException('Invalid map name: $mapName');
    }
    return CriticalE2eConfig(
      host: options['host'] ?? 'http://127.0.0.1:18080/',
      mapName: mapName,
      requestTimeout: const Duration(seconds: 15),
      streamTimeout: const Duration(seconds: 10),
    );
  }
}
