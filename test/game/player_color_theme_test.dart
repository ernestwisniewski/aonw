import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerColorTheme', () {
    test('uses the current domain player palette', () {
      expect(PlayerColorTheme.palette, Player.palette);
    });

    test('resolves stored player colors without remapping', () {
      expect(
        PlayerColorTheme.resolveValue(Player.palette.first),
        Player.palette.first,
      );
      expect(PlayerColorTheme.resolveValue(0xFF123456), 0xFF123456);
    });
  });
}
