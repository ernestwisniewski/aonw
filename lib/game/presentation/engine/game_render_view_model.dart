import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';

class GameRenderViewModel {
  final GameSelection? selection;
  final bool moveCommandActive;
  final CityFoundingDraft? cityFoundingDraft;

  const GameRenderViewModel({
    this.selection,
    this.moveCommandActive = false,
    this.cityFoundingDraft,
  });

  static const empty = GameRenderViewModel();

  factory GameRenderViewModel.fromState(GameState state) {
    return GameRenderViewModel(
      selection: state.selection?.withVisibleResources(
        playerId: state.activePlayerId,
        research: state.research,
      ),
      moveCommandActive: state.moveCommandActive,
      cityFoundingDraft: state.cityFoundingDraft,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameRenderViewModel &&
        other.selection == selection &&
        other.moveCommandActive == moveCommandActive &&
        other.cityFoundingDraft == cityFoundingDraft;
  }

  @override
  int get hashCode =>
      Object.hash(selection, moveCommandActive, cityFoundingDraft);
}
