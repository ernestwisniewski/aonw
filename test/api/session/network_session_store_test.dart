import 'package:aonw/api/session/network_session_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NetworkSessionStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves refresh token in secure storage, not shared prefs', () async {
      final secureTokens = _FakeSecureTokenStore();
      final store = NetworkSessionStore(secureTokens: secureTokens);

      await store.save(
        const StoredNetworkSession(
          userId: 'user_1',
          refreshToken: 'refresh-token',
          displayName: 'Alice',
          matchId: 'match_1',
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('network.session.userId'), 'user_1');
      expect(prefs.getString('network.session.displayName'), 'Alice');
      expect(prefs.getString('network.session.matchId'), 'match_1');
      expect(prefs.getString('network.session.refreshToken'), isNull);
      expect(
        secureTokens.values['network.session.refreshToken'],
        'refresh-token',
      );
    });

    test('stored session copyWith can clear the active match id', () {
      const session = StoredNetworkSession(
        userId: 'user_1',
        refreshToken: 'refresh-token',
        displayName: 'Alice',
        matchId: 'match_1',
      );

      final cleared = session.copyWith(matchId: null);

      expect(cleared.userId, 'user_1');
      expect(cleared.refreshToken, 'refresh-token');
      expect(cleared.displayName, 'Alice');
      expect(cleared.matchId, isNull);
    });

    test('migrates fallback shared prefs refresh token on load', () async {
      SharedPreferences.setMockInitialValues({
        'network.session.userId': 'user_1',
        'network.session.refreshToken': 'fallback-refresh-token',
        'network.session.displayName': 'Alice',
      });
      final secureTokens = _FakeSecureTokenStore();
      final store = NetworkSessionStore(secureTokens: secureTokens);

      final session = await store.load();

      final prefs = await SharedPreferences.getInstance();
      expect(session?.refreshToken, 'fallback-refresh-token');
      expect(prefs.getString('network.session.refreshToken'), isNull);
      expect(
        secureTokens.values['network.session.refreshToken'],
        'fallback-refresh-token',
      );
    });

    test(
      'loads fallback refresh token when secure storage is unavailable',
      () async {
        SharedPreferences.setMockInitialValues({
          'network.session.userId': 'user_1',
          'network.session.refreshToken': 'fallback-refresh-token',
          'network.session.displayName': 'Alice',
        });
        final secureTokens = _FakeSecureTokenStore(
          readException: _secureStorageFailure(),
          writeException: _secureStorageFailure(),
        );
        final store = NetworkSessionStore(secureTokens: secureTokens);

        final session = await store.load();

        final prefs = await SharedPreferences.getInstance();
        expect(session?.refreshToken, 'fallback-refresh-token');
        expect(
          prefs.getString('network.session.refreshToken'),
          'fallback-refresh-token',
        );
      },
    );

    test('does not persist refresh token when secure save fails', () async {
      final secureTokens = _FakeSecureTokenStore(
        writeException: _secureStorageFailure(),
      );
      final store = NetworkSessionStore(secureTokens: secureTokens);

      await store.save(
        const StoredNetworkSession(
          userId: 'user_1',
          refreshToken: 'refresh-token',
          displayName: 'Alice',
          matchId: 'match_1',
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('network.session.refreshToken'), isNull);
      expect(secureTokens.values['network.session.refreshToken'], isNull);
    });

    test('saves and loads standalone display name preference', () async {
      final store = NetworkSessionStore(secureTokens: _FakeSecureTokenStore());

      await store.saveDisplayName('  Alice   The Great  ');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('network.session.displayName'), 'Alice The Great');
      expect(await store.loadDisplayName(), 'Alice The Great');
    });

    test(
      'clear removes secure and session data but keeps display name',
      () async {
        SharedPreferences.setMockInitialValues({
          'network.session.userId': 'user_1',
          'network.session.refreshToken': 'fallback-refresh-token',
          'network.session.displayName': 'Alice',
          'network.session.matchId': 'match_1',
        });
        final secureTokens = _FakeSecureTokenStore(
          values: {'network.session.refreshToken': 'secure-refresh-token'},
        );
        final store = NetworkSessionStore(secureTokens: secureTokens);

        await store.clear();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('network.session.userId'), isNull);
        expect(prefs.getString('network.session.refreshToken'), isNull);
        expect(prefs.getString('network.session.displayName'), 'Alice');
        expect(prefs.getString('network.session.matchId'), isNull);
        expect(secureTokens.values['network.session.refreshToken'], isNull);
      },
    );

    test('clear ignores secure storage failures', () async {
      SharedPreferences.setMockInitialValues({
        'network.session.userId': 'user_1',
        'network.session.refreshToken': 'fallback-refresh-token',
        'network.session.displayName': 'Alice',
        'network.session.matchId': 'match_1',
      });
      final secureTokens = _FakeSecureTokenStore(
        deleteException: _secureStorageFailure(),
      );
      final store = NetworkSessionStore(secureTokens: secureTokens);

      await store.clear();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('network.session.userId'), isNull);
      expect(prefs.getString('network.session.refreshToken'), isNull);
      expect(prefs.getString('network.session.displayName'), 'Alice');
      expect(prefs.getString('network.session.matchId'), isNull);
    });
  });
}

class _FakeSecureTokenStore implements SecureSessionTokenStore {
  final Map<String, String> values;
  final PlatformException? readException;
  final PlatformException? writeException;
  final PlatformException? deleteException;

  _FakeSecureTokenStore({
    Map<String, String> values = const {},
    this.readException,
    this.writeException,
    this.deleteException,
  }) : values = {...values};

  @override
  Future<void> delete(String key) async {
    final exception = deleteException;
    if (exception != null) throw exception;
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    final exception = readException;
    if (exception != null) throw exception;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    final exception = writeException;
    if (exception != null) throw exception;
    values[key] = value;
  }
}

PlatformException _secureStorageFailure() {
  return PlatformException(
    code: '-34018',
    message: "A required entitlement isn't present.",
  );
}
