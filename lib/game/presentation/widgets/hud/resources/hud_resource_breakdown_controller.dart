import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hudResourceBreakdownControllerProvider =
    NotifierProvider<HudResourceBreakdownController, TopResourcePopupType?>(
      HudResourceBreakdownController.new,
    );

class HudResourceBreakdownController extends Notifier<TopResourcePopupType?> {
  @override
  TopResourcePopupType? build() => null;

  void toggle(TopResourcePopupType type) {
    state = state == type ? null : type;
  }

  void close() {
    state = null;
  }
}
