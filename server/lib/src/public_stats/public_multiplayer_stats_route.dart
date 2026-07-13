import 'dart:async';
import 'dart:convert';

import 'package:aonw_server/src/public_stats/public_multiplayer_stats_service.dart';
import 'package:aonw_server/src/public_stats/public_multiplayer_stats_store.dart';
import 'package:serverpod/serverpod.dart';

final class PublicMultiplayerStatsRoute extends Route {
  PublicMultiplayerStatsRoute({PublicMultiplayerStatsService? service})
    : _service = service ?? PublicMultiplayerStatsService(),
      super(methods: {Method.get});

  final PublicMultiplayerStatsService _service;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final stats = await _service.snapshot(
      ServerpodPublicMultiplayerStatsStore(session),
    );
    return Response.ok(
      headers: Headers.fromMap({
        'cache-control': [
          'public, max-age=30, s-maxage=60, stale-while-revalidate=300',
        ],
        'access-control-allow-origin': ['*'],
        'x-content-type-options': ['nosniff'],
      }),
      body: Body.fromString(
        jsonEncode(stats.toJson()),
        mimeType: MimeType.json,
      ),
    );
  }
}
