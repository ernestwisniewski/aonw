import 'dart:convert';

import 'package:aonw_rust_client/src/api.dart';

const aonwClientApiVersion = 1;

final class AonwClientRequest {
  AonwClientRequest._(this.request);

  factory AonwClientRequest.capabilities() =>
      AonwClientRequest._(const {'type': 'capabilities'});

  factory AonwClientRequest.openSession({
    required String mapDocument,
    required String scenarioDocument,
    required String actorPlayerId,
  }) => AonwClientRequest._({
    'type': 'openSession',
    'mapDocument': mapDocument,
    'scenarioDocument': scenarioDocument,
    'actorPlayerId': actorPlayerId,
  });

  factory AonwClientRequest.closeSession() =>
      AonwClientRequest._(const {'type': 'closeSession'});

  factory AonwClientRequest.snapshot() =>
      AonwClientRequest._(const {'type': 'snapshot'});

  factory AonwClientRequest.reachable({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'reachable',
      'expectedRevision': expectedRevision,
      'unitId': unitId,
    },
  });

  factory AonwClientRequest.routePlan({
    required int expectedRevision,
    required String unitId,
    required int targetCol,
    required int targetRow,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'routePlan',
      'expectedRevision': expectedRevision,
      'unitId': unitId,
      'target': {'col': targetCol, 'row': targetRow},
    },
  });

  factory AonwClientRequest.moveUnit({
    required int expectedRevision,
    required String unitId,
    required int targetCol,
    required int targetRow,
  }) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': 'moveUnit',
      'expectedRevision': expectedRevision,
      'unitId': unitId,
      'target': {'col': targetCol, 'row': targetRow},
    },
  });

  factory AonwClientRequest.cancelUnitAction({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._(
    _unitCommand('cancelUnitAction', expectedRevision, unitId),
  );

  factory AonwClientRequest.skipUnitTurn({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._(
    _unitCommand('skipUnitTurn', expectedRevision, unitId),
  );

  factory AonwClientRequest.fortifyUnit({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._(
    _unitCommand('fortifyUnit', expectedRevision, unitId),
  );

  factory AonwClientRequest.exportSave() =>
      AonwClientRequest._(const {'type': 'exportSave'});

  factory AonwClientRequest.openSave({
    required String mapDocument,
    required String saveDocument,
  }) => AonwClientRequest._({
    'type': 'openSave',
    'mapDocument': mapDocument,
    'saveDocument': saveDocument,
  });

  factory AonwClientRequest.exportReplay() =>
      AonwClientRequest._(const {'type': 'exportReplay'});

  factory AonwClientRequest.verifyReplay({
    required String mapDocument,
    required String replayDocument,
  }) => AonwClientRequest._({
    'type': 'verifyReplay',
    'mapDocument': mapDocument,
    'replayDocument': replayDocument,
  });

  final Map<String, Object?> request;

  String toJson() =>
      jsonEncode({'apiVersion': aonwClientApiVersion, 'request': request});

  static Map<String, Object?> _unitCommand(
    String type,
    int expectedRevision,
    String unitId,
  ) => {
    'type': 'dispatch',
    'command': {
      'type': type,
      'expectedRevision': expectedRevision,
      'unitId': unitId,
    },
  };
}

final class AonwClientResponse {
  AonwClientResponse._({this.response, this.error});

  factory AonwClientResponse.parse(String source) {
    final value = jsonDecode(source);
    final envelope = _map(value, 'client response');
    if (envelope['apiVersion'] != aonwClientApiVersion) {
      throw const FormatException('Unsupported AoNW client API version.');
    }
    final outcome = _map(envelope['outcome'], 'client outcome');
    return switch (outcome['status']) {
      'success' => AonwClientResponse._(
        response: _map(outcome['response'], 'client success response'),
      ),
      'failure' => AonwClientResponse._(
        error: AonwClientError.fromJson(
          _map(outcome['error'], 'client failure response'),
        ),
      ),
      _ => throw const FormatException('Invalid AoNW client outcome.'),
    };
  }

  final Map<String, Object?>? response;
  final AonwClientError? error;

  bool get isSuccess => response != null;

  Map<String, Object?> requireResponse(String type) {
    final value = response;
    if (value == null) {
      throw StateError(error?.message ?? 'Client request failed.');
    }
    if (value['type'] != type) {
      throw FormatException('Expected AoNW response type $type.');
    }
    return value;
  }
}

final class AonwClientError {
  const AonwClientError({required this.code, required this.message});

  factory AonwClientError.fromJson(Map<String, Object?> value) {
    final code = value['code'];
    final message = value['message'];
    if (code is! String || message is! String) {
      throw const FormatException('Invalid AoNW client error.');
    }
    return AonwClientError(code: code, message: message);
  }

  final String code;
  final String message;
}

extension AonwRustSessionClientProtocol on AonwRustSession {
  Future<AonwClientResponse> send(AonwClientRequest request) async =>
      AonwClientResponse.parse(await requestJson(request.toJson()));
}

Map<String, Object?> _map(Object? value, String label) {
  if (value is! Map<String, Object?>) {
    throw FormatException('Invalid AoNW $label.');
  }
  return value;
}
