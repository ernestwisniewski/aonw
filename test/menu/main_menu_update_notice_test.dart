import 'package:aonw/menu/main_menu_update_notice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unsupported multiplayer status activates the translated notice', () {
    expect(mainMenuUpdateNoticeForStatus('soon'), isA<MainMenuUpdateNotice>());
    expect(mainMenuUpdateNoticeForStatus('current'), isNull);
    expect(mainMenuUpdateNoticeForStatus('unknown'), isNull);
  });
}
