import 'dart:convert';
import 'dart:io';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:test/test.dart';

void main() {
  test('shared client goldens stay consumable from Dart', () {
    final request = AonwClientRequest.moveUnit(
      expectedRevision: 7,
      unitId: 'unit-1',
      targetCol: 3,
      targetRow: 4,
    );
    final requestGolden = File(
      'test/fixtures/client_protocol/move_unit_request.json',
    ).readAsStringSync().trim();
    expect(request.toJson(), requestGolden);

    final responseGolden = File(
      'test/fixtures/client_protocol/command_result_response.json',
    ).readAsStringSync();
    final response = AonwClientResponse.parse(responseGolden);
    expect(
      response.requireResponse('command')['result'],
      isA<Map<String, Object?>>(),
    );
  });

  test('client response rejects foreign versions', () {
    expect(
      () => AonwClientResponse.parse(
        '{"apiVersion":2,"outcome":{"status":"success",'
        '"response":{"type":"sessionClosed"}}}',
      ),
      throwsFormatException,
    );
  });

  test('native availability and session creation stay coherent', () async {
    final session = await createAonwRustSession();
    expect(session != null, aonwRustClientAvailable);
    if (session == null) return;
    addTearDown(session.close);

    final rawResponse = await session.requestJson(
      AonwClientRequest.capabilities().toJson(),
    );
    final response = jsonDecode(rawResponse) as Map<String, dynamic>;
    expect(response['apiVersion'], aonwClientApiVersion);
    expect(AonwClientResponse.parse(rawResponse).isSuccess, isTrue);
  });
}
