import '../generated/protocol.dart';

MultiplayerException multiplayerException(String code, String message) {
  return MultiplayerException(code: code, message: message);
}
