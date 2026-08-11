import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:flutter/widgets.dart';

void finishMultiplayerAccountAuth(
  BuildContext context,
  void Function(NetworkAuthResult result) onAuthenticated,
  NetworkAuthResult result,
) {
  onAuthenticated(result);
  Navigator.of(context).pop();
}
