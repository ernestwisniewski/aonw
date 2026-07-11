import 'dart:io';

import 'package:test/test.dart';

void main() {
  const reviewedEndpointDelegates = <String, String>{
    'listMatches': 'listMatches',
    'createMatch': 'createMatch',
    'quickplay': 'quickplay',
    'joinMatch': 'joinMatch',
    'joinPrivateMatch': 'joinPrivateMatch',
    'loadMatch': 'loadMatch',
    'loadSnapshot': 'loadSnapshot',
    'listEvents': 'listEvents',
    'startMatch': 'startMatch',
    'markMapLoaded': 'loadMatch',
    'resignMatch': 'resignMatch',
    'leaveMatch': 'leaveMatch',
    'connect': 'connect',
  };

  test('every generated multiplayer surface requires projection review', () {
    final generated = File(
      'lib/src/generated/endpoints.dart',
    ).readAsStringSync();
    final blockStart = generated.indexOf("connectors['multiplayer']");
    final blockEnd = generated.indexOf(
      "    modules['serverpod_auth_core']",
      blockStart,
    );
    expect(blockStart, greaterThanOrEqualTo(0));
    expect(blockEnd, greaterThan(blockStart));
    final multiplayerBlock = generated.substring(blockStart, blockEnd);
    final generatedMethods = RegExp(
      r"^        '([A-Za-z0-9_]+)': _i1\.Method(?:Stream)?Connector\(",
      multiLine: true,
    ).allMatches(multiplayerBlock).map((match) => match.group(1)!).toSet();

    expect(
      generatedMethods,
      reviewedEndpointDelegates.keys.toSet(),
      reason: 'A new multiplayer RPC must explicitly pass projection review.',
    );

    final endpoint = File(
      'lib/src/multiplayer/multiplayer_endpoint.dart',
    ).readAsStringSync();
    for (final entry in reviewedEndpointDelegates.entries) {
      expect(
        _methodBody(endpoint, entry.key),
        contains('multiplayerHub.${entry.value}('),
        reason: '${entry.key} must cross the reviewed multiplayer hub.',
      );
    }
  });

  test('reviewed read and stream surfaces retain their projection gates', () {
    final hubApi = File(
      'lib/src/multiplayer/realtime_match_hub_api.dart',
    ).readAsStringSync();
    const projectionEvidence = <String, String>{
      'listMatches': '_queries.listMatches(',
      'createMatch': '_viewProjector.matchFor(',
      'quickplay': '_viewProjector.matchFor(',
      'joinMatch': '_viewProjector.matchFor(',
      'joinPrivateMatch': '_viewProjector.matchFor(',
      'loadMatch': '_viewProjector.matchFor(',
      'loadSnapshot': '_queries.loadSnapshot(',
      'listEvents': '_queries.listEvents(',
      'startMatch': '_viewProjector.matchFor(',
      'resignMatch': '_viewProjector.matchFor(',
      'connect': '_connectionRegistry.connect(',
    };

    for (final entry in projectionEvidence.entries) {
      expect(
        _methodBody(hubApi, entry.key),
        contains(entry.value),
        reason: '${entry.key} lost its recipient-projection boundary.',
      );
    }
  });

  test('reviewed read surfaces declare projection-proof return types', () {
    final hubApi = File(
      'lib/src/multiplayer/realtime_match_hub_api.dart',
    ).readAsStringSync();
    const projectedSignatures = <String>[
      'Future<List<ProjectedWireMatch>> listMatches(',
      'Future<ProjectedWireMatch> quickplay(',
      'Future<ProjectedWireMatch> createMatch(',
      'Future<ProjectedWireMatch> joinMatch(',
      'Future<ProjectedWireMatch> joinPrivateMatch(',
      'Future<ProjectedWireMatch> loadMatch(',
      'Future<ProjectedWireSnapshot> loadSnapshot(',
      'Future<List<ProjectedWireEvent>> listEvents(',
      'Future<ProjectedWireMatch> startMatch(',
      'Future<ProjectedWireMatch> resignMatch(',
    ];

    for (final signature in projectedSignatures) {
      expect(
        hubApi,
        contains(signature),
        reason:
            'Hub read surfaces must return Projected* wire types so the '
            'compiler rejects unprojected canonical state.',
      );
    }
  });
}

String _methodBody(String source, String methodName) {
  final signature = RegExp(
    '\\n  (?:Future|Stream)<[^\\n]+> ${RegExp.escape(methodName)}\\(',
  ).firstMatch(source);
  if (signature == null) {
    throw StateError('Method $methodName was not found.');
  }
  final nextSignature = RegExp(
    r'\n  (?:Future|Stream)<[^\n]+> [A-Za-z0-9_]+\(',
  ).firstMatch(source.substring(signature.end));
  final end = nextSignature == null
      ? source.length
      : signature.end + nextSignature.start;
  return source.substring(signature.start, end);
}
