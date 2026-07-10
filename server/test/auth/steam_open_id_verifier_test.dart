import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aonw_server/src/auth/steam_open_id_verifier.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  tearDown(() => server.close(force: true));

  test('accepts a bounded valid Steam verification response', () async {
    final handled = server.first.then((request) async {
      final body = await utf8.decoder.bind(request).join();
      request.response.write('ns:http://specs.openid.net/auth/2.0\n');
      request.response.write('is_valid:true\n');
      await request.response.close();
      return (method: request.method, body: body);
    });

    final verified = await _verifier(server).verify({
      'openid.mode': 'id_res',
      'openid.claimed_id': 'https://steamcommunity.com/openid/id/123',
      'ignored': 'not-forwarded',
    });
    final request = await handled;

    expect(verified, isTrue);
    expect(request.method, 'POST');
    expect(request.body, contains('openid.mode=check_authentication'));
    expect(request.body, contains('openid.claimed_id='));
    expect(request.body, isNot(contains('ignored')));
  });

  test('rejects oversized verification requests before network I/O', () async {
    final verifier = SteamOpenIdVerifier(
      endpoint: _endpoint(server),
      maxRequestBytes: 32,
    );

    final verified = await verifier.verify({
      'openid.mode': 'id_res',
      'openid.signature': List.filled(128, 'x').join(),
    });

    expect(verified, isFalse);
  });

  test('rejects oversized verification responses', () async {
    final handled = server.first.then((request) async {
      await request.drain<void>();
      request.response.write(List.filled(64, 'x').join());
      await request.response.close();
    });
    final verifier = SteamOpenIdVerifier(
      endpoint: _endpoint(server),
      maxResponseBytes: 32,
    );

    expect(await verifier.verify(_query), isFalse);
    await handled;
  });

  test(
    'fails closed when Steam does not respond before the deadline',
    () async {
      final handled = server.first.then((request) async {
        await request.drain<void>();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        try {
          request.response.write('is_valid:true\n');
          await request.response.close();
        } on IOException {
          // The verifier force-closes the timed-out connection.
        }
      });
      final verifier = SteamOpenIdVerifier(
        endpoint: _endpoint(server),
        timeout: const Duration(milliseconds: 50),
      );

      expect(await verifier.verify(_query), isFalse);
      await handled;
    },
  );
}

SteamOpenIdVerifier _verifier(HttpServer server) {
  return SteamOpenIdVerifier(endpoint: _endpoint(server));
}

Uri _endpoint(HttpServer server) {
  return Uri.parse('http://${server.address.address}:${server.port}/openid');
}

const _query = <String, String>{
  'openid.mode': 'id_res',
  'openid.signature': 'signature',
};
