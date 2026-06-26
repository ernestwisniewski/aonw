import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class GameSoundCueMapper {
  static List<GameSoundCue> forCommand({
    required GameCommand command,
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
      SetActivePlayerCommand(:final playerId, :final canAct)
          when playerId.isNotEmpty && canAct =>
        const [GameSoundCue.newTurn],
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
    return switch (event) {
      CityFoundedEvent(:final ownerPlayerId)
          when _belongsToPlayer(ownerPlayerId, audiblePlayerId) =>
        GameSoundCue.city,
      CityBuiltBuildingEvent(:final cityId) ||
      CityProducedUnitEvent(:final cityId)
          when _belongsToPlayer(
            _cityOwner(state, previousState, cityId),
            audiblePlayerId,
          ) =>
        GameSoundCue.city,
      CityCapturedEvent(:final previousOwnerPlayerId, :final newOwnerPlayerId)
          when _belongsToAnyPlayer([
            previousOwnerPlayerId,
            newOwnerPlayerId,
          ], audiblePlayerId) =>
        GameSoundCue.city,
      CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId)
          when _combatInvolvesPlayer(
            state,
            previousState,
            attackerUnitId: attackerUnitId,
            defenderUnitId: defenderUnitId,
            playerId: audiblePlayerId,
          ) =>
        GameSoundCue.attack,
      _ => null,
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

  static GameUnit? _unitById(GameState? state, String unitId) {
    if (state == null) return null;
    for (final unit in state.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  static GameCity? _cityById(GameState? state, String cityId) {
    if (state == null) return null;
    for (final city in state.cities) {
      if (city.id == cityId) return city;
    }
    return null;
  }

  static String? _cityOwner(
    GameState state,
    GameState? previousState,
    String cityId,
  ) {
    return (_cityById(state, cityId) ?? _cityById(previousState, cityId))
        ?.ownerPlayerId;
  }

  static String? _unitOrCityOwner(
    GameState state,
    GameState? previousState,
    String id,
  ) {
    return (_unitById(state, id) ?? _unitById(previousState, id))
            ?.ownerPlayerId ??
        (_cityById(state, id) ?? _cityById(previousState, id))?.ownerPlayerId;
  }

  static bool _combatInvolvesPlayer(
    GameState state,
    GameState? previousState, {
    required String attackerUnitId,
    required String defenderUnitId,
    required String playerId,
  }) {
    return _belongsToAnyPlayer([
      _unitOrCityOwner(state, previousState, attackerUnitId),
      _unitOrCityOwner(state, previousState, defenderUnitId),
    ], playerId);
  }

  static String _audiblePlayerId(GameState? previousState, GameState state) {
    final previousActivePlayerId = previousState?.activePlayerId;
    if (previousActivePlayerId != null && previousActivePlayerId.isNotEmpty) {
      return previousActivePlayerId;
    }
    return state.activePlayerId;
  }

  static String _audiblePlayerIdForCommand(
    GameCommand command,
    GameState? previousState,
    GameState state,
  ) {
    return switch (command) {
      SetActivePlayerCommand(:final playerId) => playerId,
      _ => _audiblePlayerId(previousState, state),
    };
  }

  static bool _commandBelongsToPlayer(
    GameCommand command,
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
        (_unitById(previousState, unitId) ?? _unitById(state, unitId))
            ?.ownerPlayerId,
        playerId,
      ),
      FoundCityCommand(:final founderId) => _belongsToPlayer(
        (_unitById(previousState, founderId) ?? _unitById(state, founderId))
            ?.ownerPlayerId,
        playerId,
      ),
      SelectCityCommand(:final cityId) ||
      CityTappedCommand(:final cityId) ||
      StartBuildingCommand(:final cityId) ||
      StartUnitProductionCommand(:final cityId) ||
      StartCityProjectCommand(:final cityId) ||
      SetCitySpecializationCommand(:final cityId) ||
      RushProductionCommand(:final cityId) ||
      StartCityWorkedHexSelectionCommand(:final cityId) ||
      CancelCityWorkedHexSelectionCommand(:final cityId) ||
      ToggleWorkedHexCommand(:final cityId) ||
      StartCityExpansionSelectionCommand(:final cityId) ||
      CancelCityExpansionSelectionCommand(:final cityId) ||
      SelectCityExpansionHexCommand(:final cityId) => _belongsToPlayer(
        (_cityById(state, cityId) ?? _cityById(previousState, cityId))
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
      SetActivePlayerCommand(playerId: final commandPlayerId) ||
      FocusNextPendingActionCommand(playerId: final commandPlayerId) ||
      FocusTurnStartActionCommand(
        playerId: final commandPlayerId,
      ) => commandPlayerId == playerId,
      ResetUnitMovementCommand(playerId: final commandPlayerId) =>
        commandPlayerId == null || commandPlayerId == playerId,
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

  static bool _belongsToAnyPlayer(
    Iterable<String?> ownerPlayerIds,
    String playerId,
  ) {
    if (playerId.isEmpty) return true;
    return ownerPlayerIds.contains(playerId);
  }
}
