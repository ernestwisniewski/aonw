import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class GameSoundCueMapper {
  static List<GameSoundCue> forCommand({
    required Object command,
    required GameState? previousState,
    required GameState state,
    required Iterable<GameEvent> events,
    required Iterable<UiEffect> uiEffects,
  }) {
    if (!_commandHadEffect(previousState, state, events, uiEffects)) {
      return const [];
    }

    final audiblePlayerId = _audiblePlayerIdForCommand(
      command,
      previousState,
      state,
    );
    if (!_commandBelongsToPlayer(
      command,
      previousState,
      state,
      audiblePlayerId,
    )) {
      return const [];
    }

    return switch (command) {
      TileTappedCommand() => _tileTapCues(state: state, uiEffects: uiEffects),
      SelectTileCommand() => const [GameSoundCue.mapTileSelect],
      CityTappedCommand() || SelectCityCommand() => const [GameSoundCue.city],
      MoveUnitCommand() => const [GameSoundCue.walk],
      ToggleMoveTargetingCommand() => _moveTargetingCues(previousState, state),
      StartCityFoundingCommand() ||
      StartCityWorkedHexSelectionCommand() ||
      StartCityExpansionSelectionCommand() ||
      StartWorkerActionSelectionCommand() => const [GameSoundCue.uiPanelOpen],
      _ => const [],
    };
  }

  static List<GameSoundCue> forEvents({
    required Iterable<GameEvent> events,
    required GameState state,
    required GameState? previousState,
  }) {
    final audiblePlayerId = _audiblePlayerId(previousState, state);
    final cues = <GameSoundCue>[];
    for (final event in events) {
      final cue = _cueForEvent(
        event,
        state,
        previousState,
        audiblePlayerId: audiblePlayerId,
      );
      if (cue != null && !cues.contains(cue)) cues.add(cue);
    }
    return cues;
  }

  static List<GameSoundCue> forRendererEffects({
    required Iterable<RendererEffect> effects,
    required GameState state,
    required GameState? previousState,
  }) {
    return const [];
  }

  static bool _commandHadEffect(
    GameState? previousState,
    GameState state,
    Iterable<GameEvent> events,
    Iterable<UiEffect> uiEffects,
  ) {
    return previousState == null ||
        previousState != state ||
        events.isNotEmpty ||
        uiEffects.isNotEmpty;
  }

  static List<GameSoundCue> _tileTapCues({
    required GameState state,
    required Iterable<UiEffect> uiEffects,
  }) {
    if (uiEffects.whereType<AnimateUnitMoveEffect>().isNotEmpty) {
      return const [GameSoundCue.walk];
    }
    if (state.movePreview != null) return const [GameSoundCue.movePreview];

    final selection = state.selection;
    if (selection?.type == GameSelectionType.unit) return const [];
    if (selection?.type == GameSelectionType.city) {
      return const [GameSoundCue.city];
    }
    return const [GameSoundCue.mapTileSelect];
  }

  static GameSoundCue? _cueForEvent(
    GameEvent event,
    GameState state,
    GameState? previousState, {
    required String audiblePlayerId,
  }) {
    final descriptor = GameEventDescriptor.forEvent(event);
    if (!_eventBelongsToAudiblePlayer(
      descriptor,
      state,
      previousState,
      audiblePlayerId,
    )) {
      return null;
    }
    return switch (descriptor.soundCueKind) {
      GameEventSoundCueKind.city => GameSoundCue.city,
      GameEventSoundCueKind.combat => GameSoundCue.attack,
      GameEventSoundCueKind.none => null,
    };
  }

  static List<GameSoundCue> _moveTargetingCues(
    GameState? previousState,
    GameState state,
  ) {
    if (state.moveCommandActive &&
        !(previousState?.moveCommandActive ?? false)) {
      return const [GameSoundCue.movePreview];
    }
    return const [];
  }

  static bool _eventBelongsToAudiblePlayer(
    GameEventDescriptor descriptor,
    GameState state,
    GameState? previousState,
    String playerId,
  ) {
    if (playerId.isEmpty) return true;
    return descriptor
        .playerIdsFor(state: state, previousState: previousState)
        .contains(playerId);
  }

  static String _audiblePlayerId(GameState? previousState, GameState state) {
    final previousActivePlayerId = previousState?.activePlayerId;
    if (previousActivePlayerId != null && previousActivePlayerId.isNotEmpty) {
      return previousActivePlayerId;
    }
    return state.activePlayerId;
  }

  static String _audiblePlayerIdForCommand(
    Object command,
    GameState? previousState,
    GameState state,
  ) {
    return _audiblePlayerId(previousState, state);
  }

  static bool _commandBelongsToPlayer(
    Object command,
    GameState? previousState,
    GameState state,
    String playerId,
  ) {
    if (playerId.isEmpty) return true;
    return switch (command) {
      SelectUnitCommand(:final unitId) ||
      StartAttackTargetingCommand(attackerUnitId: final unitId) ||
      CancelAttackTargetingCommand(attackerUnitId: final unitId) ||
      AttackHexCommand(attackerUnitId: final unitId) ||
      StartCommanderMergeSelectionCommand(commanderUnitId: final unitId) ||
      CancelCommanderMergeSelectionCommand(commanderUnitId: final unitId) ||
      MoveUnitCommand(:final unitId) ||
      CancelUnitActionCommand(:final unitId) ||
      SkipUnitTurnCommand(:final unitId) ||
      FortifyUnitCommand(:final unitId) ||
      AutoExploreUnitCommand(:final unitId) ||
      StartMerchantTradeRouteSelectionCommand(:final unitId) ||
      CancelMerchantTradeRouteSelectionCommand(:final unitId) ||
      AssignMerchantTradeRouteCommand(:final unitId) ||
      StartMerchantMoveToCitySelectionCommand(:final unitId) ||
      CancelMerchantMoveToCitySelectionCommand(:final unitId) ||
      MoveMerchantToCityCommand(:final unitId) ||
      StartArtifactExcavationCommand(:final unitId) ||
      StoreArtifactInCityCommand(:final unitId) ||
      DetachTroopCommand(:final unitId) ||
      StartWorkerActionSelectionCommand(:final unitId) ||
      SelectWorkerImprovementCommand(:final unitId) ||
      ConfirmWorkerImprovementCommand(:final unitId) ||
      CancelWorkerActionSelectionCommand(:final unitId) ||
      CancelWorkerJobCommand(:final unitId) ||
      AssignWorkerToHexCommand(:final unitId) ||
      CancelWorkerAssignmentCommand(:final unitId) => _belongsToPlayer(
        (previousState?.unitById(unitId) ?? state.unitById(unitId))
            ?.ownerPlayerId,
        playerId,
      ),
      FoundCityCommand(:final founderId) => _belongsToPlayer(
        (previousState?.unitById(founderId) ?? state.unitById(founderId))
            ?.ownerPlayerId,
        playerId,
      ),
      SelectCityCommand(:final cityId) ||
      CityTappedCommand(:final cityId) ||
      StartBuildingCommand(:final cityId) ||
      StartUnitProductionCommand(:final cityId) ||
      StartCityProjectCommand(:final cityId) ||
      StartWonderCommand(:final cityId) ||
      SetCitySpecializationCommand(:final cityId) ||
      RushProductionCommand(:final cityId) ||
      StartCityWorkedHexSelectionCommand(:final cityId) ||
      CancelCityWorkedHexSelectionCommand(:final cityId) ||
      ToggleWorkedHexCommand(:final cityId) ||
      StartCityExpansionSelectionCommand(:final cityId) ||
      CancelCityExpansionSelectionCommand(:final cityId) ||
      SelectCityExpansionHexCommand(:final cityId) => _belongsToPlayer(
        (state.cityById(cityId) ?? previousState?.cityById(cityId))
            ?.ownerPlayerId,
        playerId,
      ),
      EndTurnCommand(playerId: final commandPlayerId) ||
      SubmitTurnCommand(playerId: final commandPlayerId) ||
      TradeArtifactCommand(playerId: final commandPlayerId) ||
      OpenResourceTradeCommand(playerId: final commandPlayerId) ||
      OpenResourceExchangeCommand(playerId: final commandPlayerId) ||
      SendDiplomaticProposalCommand(playerId: final commandPlayerId) ||
      RespondDiplomaticProposalCommand(playerId: final commandPlayerId) ||
      SendDiplomaticMessageCommand(playerId: final commandPlayerId) ||
      RespondDiplomaticMessageCommand(playerId: final commandPlayerId) ||
      DeclareWarCommand(playerId: final commandPlayerId) ||
      SendGoldGiftCommand(playerId: final commandPlayerId) ||
      FocusNextPendingActionCommand(playerId: final commandPlayerId) ||
      FocusTurnStartActionCommand(
        playerId: final commandPlayerId,
      ) => commandPlayerId == playerId,
      SelectTechnologyCommand(playerId: final commandPlayerId) ||
      CancelResearchSelectionCommand(
        playerId: final commandPlayerId,
      ) => commandPlayerId == playerId,
      StartCityFoundingCommand() ||
      CancelCityFoundingCommand() ||
      ToggleMoveTargetingCommand() => _selectedOwnerBelongsToPlayer(
        previousState ?? state,
        playerId,
      ),
      TileTappedCommand() || SelectTileCommand() => true,
      _ => true,
    };
  }

  static bool _selectedOwnerBelongsToPlayer(GameState state, String playerId) {
    final selection = state.selection;
    return switch (selection?.type) {
      GameSelectionType.unit => _belongsToPlayer(
        selection?.unit?.ownerPlayerId,
        playerId,
      ),
      GameSelectionType.city => _belongsToPlayer(
        selection?.city?.ownerPlayerId,
        playerId,
      ),
      _ => true,
    };
  }

  static bool _belongsToPlayer(String? ownerPlayerId, String playerId) {
    if (playerId.isEmpty) return true;
    return ownerPlayerId == playerId;
  }
}
