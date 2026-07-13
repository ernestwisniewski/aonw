import 'package:aonw_server/src/generated/protocol.dart';

MultiplayerException multiplayerException(String code, String message) {
  return MultiplayerException(code: code, message: message);
}
