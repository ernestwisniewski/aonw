import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'handoff_provider.g.dart';

@riverpod
class GameHandoffNotifier extends _$GameHandoffNotifier {
  @override
  HandoffData? build() => null;

  void setPending(HandoffData data) => state = data;

  void clear() => state = null;
}
