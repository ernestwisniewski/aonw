import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final atlas = File(
    'deploy/homepage/architecture/index.html',
  ).readAsStringSync();

  test('atlas tracks the shared multiplayer contract', () {
    final protocol = File(
      'packages/aonw_core/lib/protocol/protocol_version.dart',
    ).readAsStringSync();
    final wireVersion = _intConstant(protocol, 'kProtocolVersion');
    final multiplayerRevision = _intConstant(
      protocol,
      'kCurrentMultiplayerVersion',
    );

    expect(
      atlas,
      contains('WIRE v$wireVersion · MULTIPLAYER REV $multiplayerRevision'),
    );
    expect(atlas, contains('durable presence leases'));
    expect(atlas, contains('heartbeat renewal'));
  });

  test('atlas retains accessible animated flow diagrams', () {
    expect(atlas, contains('body class="animations-on"'));
    expect(atlas, contains('body.animations-on .edge'));
    expect(atlas, contains('@keyframes dash'));
    expect(atlas, contains('@media (prefers-reduced-motion: reduce)'));
    expect(atlas, contains('id="animate"'));
    expect(atlas, contains("document.body.classList.toggle('animations-on')"));
  });
}

int _intConstant(String source, String name) {
  final match = RegExp(
    '${RegExp.escape(name)}\\s*=\\s*(\\d+)',
  ).firstMatch(source);
  if (match == null) throw StateError('Missing integer constant $name.');
  return int.parse(match.group(1)!);
}
