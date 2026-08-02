import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/city.dart';

class RenderState {
  final GameSelection? selection;
  final bool moveCommandActive;
  final CityFoundingDraft? cityFoundingDraft;

  const RenderState({
    this.selection,
    this.moveCommandActive = false,
    this.cityFoundingDraft,
  });

  static const empty = RenderState();

  factory RenderState.fromState(GameClientState state) {
    return RenderState(
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
    return other is RenderState &&
        other.selection == selection &&
        other.moveCommandActive == moveCommandActive &&
        other.cityFoundingDraft == cityFoundingDraft;
  }

  @override
  int get hashCode =>
      Object.hash(selection, moveCommandActive, cityFoundingDraft);
}
