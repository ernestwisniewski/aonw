import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RenderState', () {
    test('projects renderer-facing fields from GameClientState', () {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final selection = GameSelection.unit(commander);
      final draft = CityFoundingDraft(
        unitId: commander.id,
        ownerPlayerId: commander.ownerPlayerId,
        center: CityHex(col: commander.col, row: commander.row),
      );
      final state = GameClientState(
        activePlayerId: commander.ownerPlayerId,
        units: [commander],
        interaction: InteractionState(
          selection: selection,
          moveCommandActive: true,
          cityFoundingDraft: draft,
        ),
      );

      final viewModel = RenderState.fromState(state);

      expect(viewModel.selection, selection);
      expect(viewModel.moveCommandActive, isTrue);
      expect(viewModel.cityFoundingDraft, draft);
    });
  });
}
