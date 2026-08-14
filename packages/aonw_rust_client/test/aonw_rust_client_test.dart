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
    final requestGolden = _fixture(
      'move_unit_request.json',
    ).readAsStringSync().trim();
    expect(request.toJson(), requestGolden);

    final responseGolden = _fixture(
      'command_result_response.json',
    ).readAsStringSync();
    final response = AonwClientResponse.parse(responseGolden);
    final command = response.require<AonwCommandResponse>().result;
    expect(command.stamp.revision, 8);
    expect(command.viewPatch.upsertedUnits.single.kind, AonwUnitKind.commander);
    expect(command.events.single, isA<AonwUnitMovedEvent>());
    expect(command.evidence, isA<AonwUnitMovementEvidence>());
  });

  test('client response rejects foreign versions', () {
    expect(
      () => AonwClientResponse.parse(
        '{"apiVersion":3,"outcome":{"status":"success",'
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
    final capabilities = AonwClientResponse.parse(
      rawResponse,
    ).require<AonwCapabilitiesResponse>();
    expect(capabilities.features, contains(AonwClientFeature.snapshot));
  });
}

File _fixture(String name) {
  for (final root in [
    'test/fixtures/client_protocol',
    '../../test/fixtures/client_protocol',
  ]) {
    final candidate = File('$root/$name');
    if (candidate.existsSync()) return candidate;
  }
  throw StateError('Shared client fixture not found: $name');
}
