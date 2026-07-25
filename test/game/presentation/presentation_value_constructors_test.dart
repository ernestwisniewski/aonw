import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_screen.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('action palette values retain runtime constructor arguments', () {
    final chip = ActionPaletteYieldChip(
      kind: _runtime(ActionPaletteYieldKind.food),
      value: _runtime(2),
    );
    final option = ActionPaletteOption(
      id: _runtime('farm'),
      iconAtlasRow: _runtime(1),
      iconAtlasColumn: _runtime(2),
      label: _runtime('Farm'),
      yieldChips: _runtime([chip]),
      turns: _runtime(3),
      state: _runtime(ActionPaletteOptionState.available),
      ctaLabel: _runtime('Build'),
    );

    expect(option.yieldChips, [chip]);
    expect(option.yieldChips.single.value, 2);
    expect(option.isAvailable, isTrue);
  });

  test('new game screen retains runtime constructor arguments', () {
    final key = UniqueKey();
    final screen = NewGameScreen(
      flow: _runtime(NewGameFlow.multiplayer),
      startAtMap: _runtime(true),
      initialPlayerCountry: _runtime(PlayerCountry.poland),
      key: key,
    );

    expect(screen.flow, NewGameFlow.multiplayer);
    expect(screen.startAtMap, isTrue);
    expect(screen.initialPlayerCountry, PlayerCountry.poland);
    expect(screen.key, same(key));
  });
}

T _runtime<T>(T value) => value;
