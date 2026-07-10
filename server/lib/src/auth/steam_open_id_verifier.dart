import 'dart:async';
import 'dart:convert';
import 'dart:io';

final class SteamOpenIdVerifier {
  SteamOpenIdVerifier({
    Uri? endpoint,
    this.timeout = const Duration(seconds: 5),
    this.maxRequestBytes = 16 * 1024,
    this.maxResponseBytes = 4 * 1024,
  }) : assert(timeout > Duration.zero),
       assert(maxRequestBytes > 0),
       assert(maxResponseBytes > 0),
       endpoint = endpoint ?? steamEndpoint;

  static final Uri steamEndpoint = Uri.parse(
    'https://steamcommunity.com/openid/login',
  );

  final Uri endpoint;
  final Duration timeout;
  final int maxRequestBytes;
  final int maxResponseBytes;

  Future<bool> verify(Map<String, String> query) async {
    final body = _verificationBody(query);
    if (utf8.encode(body).length > maxRequestBytes) return false;

    final client = HttpClient()
      ..autoUncompress = false
      ..connectionTimeout = timeout;
    try {
      return await _exchange(client, body).timeout(timeout);
    } on TimeoutException {
      return false;
    } on IOException {
      return false;
    } on FormatException {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> _exchange(HttpClient client, String body) async {
    final request = await client.postUrl(endpoint);
    request
      ..followRedirects = false
      ..headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      )
      ..write(body);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) return false;

    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > maxResponseBytes) return false;
      bytes.addAll(chunk);
    }
    final responseBody = utf8.decode(bytes);
    return responseBody
        .split('\n')
        .any((line) => line.trim() == 'is_valid:true');
  }

  String _verificationBody(Map<String, String> query) {
    final parameters = <String, String>{};
    for (final entry in query.entries) {
      if (entry.key.startsWith('openid.')) {
        parameters[entry.key] = entry.value;
      }
    }
    parameters['openid.mode'] = 'check_authentication';
    return Uri(queryParameters: parameters).query;
  }
}
