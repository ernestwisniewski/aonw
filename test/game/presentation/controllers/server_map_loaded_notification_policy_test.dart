import 'package:aonw/game/presentation/controllers/server_map_loaded_notification_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerMapLoadedNotificationPolicy', () {
    test('allows the first connected notification for the active match', () {
      expect(_shouldNotify(), isTrue);
    });

    test('rejects local games and empty save identifiers', () {
      expect(_shouldNotify(multiplayer: false), isFalse);
      expect(_shouldNotify(saveId: ''), isFalse);
    });

    test('rejects a notification already sent for this save', () {
      expect(_shouldNotify(sentFor: 'match_1'), isFalse);
    });

    test('rejects disconnected sessions', () {
      expect(_shouldNotify(sessionConnected: false), isFalse);
    });

    test('rejects a session connected to another match', () {
      expect(_shouldNotify(sessionMatchId: 'match_2'), isFalse);
    });
  });
}

bool _shouldNotify({
  bool multiplayer = true,
  String saveId = 'match_1',
  String? sentFor,
  bool sessionConnected = true,
  String? sessionMatchId = 'match_1',
}) => ServerMapLoadedNotificationPolicy.shouldNotify(
  multiplayer: multiplayer,
  saveId: saveId,
  sentFor: sentFor,
  sessionConnected: sessionConnected,
  sessionMatchId: sessionMatchId,
);
