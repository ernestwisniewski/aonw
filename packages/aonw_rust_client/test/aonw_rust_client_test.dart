import 'dart:convert';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:test/test.dart';

void main() {
  test('native availability and session creation stay coherent', () async {
    final session = await createAonwRustSession();
    expect(session != null, aonwRustClientAvailable);
    if (session == null) return;
    addTearDown(session.close);

    final response =
        jsonDecode(
              await session.requestJson(
                '{"apiVersion":1,"request":{"type":"capabilities"}}',
              ),
            )
            as Map<String, dynamic>;
    expect(response['apiVersion'], 1);
    expect((response['outcome'] as Map<String, dynamic>)['status'], 'success');
  });
}
