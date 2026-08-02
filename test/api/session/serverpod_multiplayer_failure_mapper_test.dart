import 'package:aonw/api/session/serverpod_multiplayer_failure_mapper.dart';
import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

void main() {
  test('maps generated multiplayer errors to an application failure', () {
    final generated = sp.MultiplayerException(
      code: 'match_full',
      message: 'No free slot',
    );

    final mapped = mapServerpodMultiplayerFailure(generated);

    expect(
      mapped,
      isA<MultiplayerFailure>()
          .having(
            (failure) => failure.kind,
            'kind',
            MultiplayerFailureKind.multiplayer,
          )
          .having((failure) => failure.code, 'code', 'match_full')
          .having((failure) => failure.message, 'message', 'No free slot')
          .having((failure) => failure.cause, 'cause', same(generated)),
    );
  });

  test('maps generated account and refresh errors without leaking them', () {
    final account = mapServerpodMultiplayerFailure(
      sp.AccountAuthException(code: 'account_exists'),
    );
    final refresh = mapServerpodMultiplayerFailure(
      sp_auth.RefreshTokenExpiredException(),
    );

    expect(
      account,
      isA<MultiplayerFailure>()
          .having(
            (failure) => failure.kind,
            'kind',
            MultiplayerFailureKind.authentication,
          )
          .having((failure) => failure.code, 'code', 'account_exists'),
    );
    expect(
      refresh,
      isA<MultiplayerFailure>()
          .having(
            (failure) => failure.kind,
            'kind',
            MultiplayerFailureKind.authentication,
          )
          .having((failure) => failure.code, 'code', 'refresh_rejected'),
    );
  });

  test('keeps non-Serverpod failures intact', () {
    final original = StateError('local invariant');

    expect(mapServerpodMultiplayerFailure(original), same(original));
  });
}
