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

    final inspectRequest = AonwClientRequest.inspectMap(
      mapDocument: 'map-document',
    );
    expect(
      inspectRequest.toJson(),
      _fixture('inspect_map_request.json').readAsStringSync().trim(),
    );
    final mapResponse = AonwClientResponse.parse(
      _fixture('map_inspected_response.json').readAsStringSync(),
    ).require<AonwMapInspectedResponse>();
    expect(mapResponse.map.gridLayout, AonwMapGridLayout.oddQFlatTop);
    expect(mapResponse.map.tiles.single.displayTerrain, AonwMapTerrain.forest);
    expect(mapResponse.map.objectives.single.type, AonwMapObjectiveType.ruins);
  });

  test('client response rejects foreign versions', () {
    expect(
      () => AonwClientResponse.parse(
        '{"apiVersion":6,"outcome":{"status":"success",'
        '"response":{"type":"sessionClosed"}}}',
      ),
      throwsFormatException,
    );
  });

  test('native availability and session creation stay coherent', () async {
    expect(aonwRustClientIdentity.isCompatible, aonwRustClientAvailable);
    final session = await createAonwRustSession();
    expect(session != null, aonwRustClientAvailable);
    if (session == null) return;
    expect(
      aonwRustClientIdentity.buildIdentity,
      aonwExpectedNativeBuildIdentity,
    );
    addTearDown(session.close);

    final rawResponse = await session.requestJson(
      AonwClientRequest.capabilities().toJson(),
    );
    final response = jsonDecode(rawResponse) as Map<String, dynamic>;
    expect(response['apiVersion'], aonwClientApiVersion);
    final capabilities = AonwClientResponse.parse(
      rawResponse,
    ).require<AonwCapabilitiesResponse>();
    expect(capabilities.features, unorderedEquals(AonwClientFeature.values));

    final inspected = AonwClientResponse.parse(
      await session.requestJson(
        AonwClientRequest.inspectMap(
          mapDocument: _starterMap().readAsStringSync(),
        ).toJson(),
      ),
    ).require<AonwMapInspectedResponse>();
    expect(inspected.map.mapId, 'aonw2_starter');
    expect(inspected.map.tiles, hasLength(49));
    expect(
      inspected.map.contentHash,
      '4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d',
    );
  });
}

File _starterMap() {
  for (final path in [
    'clients/aonw_godot/assets/maps/aonw2_starter/map.json',
    '../../clients/aonw_godot/assets/maps/aonw2_starter/map.json',
  ]) {
    final candidate = File(path);
    if (candidate.existsSync()) return candidate;
  }
  throw StateError('Starter map fixture not found.');
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
