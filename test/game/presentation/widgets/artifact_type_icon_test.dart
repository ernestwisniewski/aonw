import 'package:aonw/game/presentation/widgets/theme/artifact_type_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Hero's Sword uses its canonical map-marker glyph", () {
    final icon = gameIconForArtifactType(WorldArtifactType.heroSword);

    expect(icon, isNot(same(GameIcons.artifact)));
    expect(icon.strokeWidth, 1.55);
    expect(icon.paths, contains('M12 18.3L12 6.3'));
  });
}
