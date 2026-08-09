part of 'new_game_screen.dart';

typedef _NewGameReviewState = ({
  int playerCount,
  MapValidationResult? validation,
  bool loading,
  Object? error,
});

extension _NewGameScreenContent on _NewGameScreenState {
  Widget _buildContent(
    BuildContext context,
    List<MapSelection> maps, {
    required bool multiplayerAccessAllowed,
  }) {
    if (_scheduleDirectMultiplayerLobby(
      maps,
      multiplayerAccessAllowed: multiplayerAccessAllowed,
    )) {
      return const _NewGameLoading();
    }

    final official = _mapsFromSource(maps, MapSource.asset);
    final yours = _mapsFromSource(maps, MapSource.saved);
    final review = _reviewState();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _buildHeader(context, official.length, yours.length),
        _NewGameStepRail(step: _step, onStepSelected: _selectStep),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: GameMotion.scene,
          switchInCurve: GameMotion.enter,
          switchOutCurve: GameMotion.exit,
          child: _buildStep(
            official: official,
            yours: yours,
            review: review,
            multiplayerAccessAllowed: multiplayerAccessAllowed,
          ),
        ),
      ],
    );
  }

  bool _scheduleDirectMultiplayerLobby(
    List<MapSelection> maps, {
    required bool multiplayerAccessAllowed,
  }) {
    if (!widget.startAtMap ||
        _flow != NewGameFlow.multiplayer ||
        !multiplayerAccessAllowed ||
        _autoOpenedMultiplayerLobby) {
      return false;
    }
    _autoOpenedMultiplayerLobby = true;
    final map = _randomMultiplayerMap(maps);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openLobby(map);
    });
    return true;
  }

  List<MapSelection> _mapsFromSource(
    Iterable<MapSelection> maps,
    MapSource source,
  ) => [
    for (final map in maps)
      if (map.source == source) map,
  ];

  _NewGameReviewState _reviewState() {
    final selectedMap = _selectedMap;
    final asyncMap = selectedMap == null
        ? null
        : ref.watch(activeMapProvider(selectedMap));
    final playerCount = switch (asyncMap) {
      AsyncData(:final value) =>
        NewGameSinglePlayerSetup.playerCountForWorldMap(value),
      _ => NewGameSinglePlayerSetup.playerCountForMapName(selectedMap?.name),
    };
    return (
      playerCount: playerCount,
      validation: switch (asyncMap) {
        AsyncData(:final value) => MapValidator.validate(
          mapData: value,
          playerCount: playerCount,
          gameLength: _selectedGameLength,
        ),
        _ => null,
      },
      loading: asyncMap is AsyncLoading,
      error: switch (asyncMap) {
        AsyncError(:final error) => error,
        _ => null,
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int officialMapCount,
    int savedMapCount,
  ) {
    final l10n = context.l10n;
    return GameUiScreenHeader(
      icon: _flow.icon,
      title: l10n.newGameIntroTitle,
      subtitle: l10n.newGameIntroSubtitle,
      meta: [
        MenuMetricPill(
          icon: Icons.public_outlined,
          label: l10n.officialMapsCount(officialMapCount),
        ),
        MenuMetricPill(
          icon: Icons.edit_location_alt_outlined,
          label: l10n.yourMapsCount(savedMapCount),
        ),
      ],
    );
  }

  Widget _buildStep({
    required List<MapSelection> official,
    required List<MapSelection> yours,
    required _NewGameReviewState review,
    required bool multiplayerAccessAllowed,
  }) {
    return switch (_step) {
      NewGameStep.plan => _PlanStep(
        key: const ValueKey('newGame.plan'),
        flow: _flow,
        multiplayerAccessAllowed: multiplayerAccessAllowed,
        playerCountry: _selectedPlayerCountry,
        gameLengthPreset: _selectedGameLengthPreset,
        aiDifficulty: _selectedAiDifficulty,
        onFlowChanged: (flow) => _updateState(() => _flow = flow),
        onPlayerCountryChanged: (country) =>
            _updateState(() => _selectedPlayerCountry = country),
        onGameLengthChanged: (preset) =>
            _updateState(() => _selectedGameLengthPreset = preset),
        onAiDifficultyChanged: (difficulty) =>
            _updateState(() => _selectedAiDifficulty = difficulty),
      ),
      NewGameStep.map => _MapStep(
        key: const ValueKey('newGame.map'),
        official: official,
        yours: yours,
        onMapSelected: _selectMap,
      ),
      NewGameStep.review => buildNewGameReviewStep(
        key: const ValueKey('newGame.review'),
        flow: _flow,
        map: _selectedMap,
        playerCountry: _selectedPlayerCountry,
        gameLengthPreset: _selectedGameLengthPreset,
        aiDifficulty: _selectedAiDifficulty,
        mapPickedManually: _mapPickedManually,
        singlePlayerPlayerCount: review.playerCount,
        mapValidation: _singlePlayerValue(review.validation),
        mapValidationLoading:
            _flow == NewGameFlow.singlePlayer && review.loading,
        mapValidationError: _singlePlayerValue(review.error),
      ),
    };
  }

  T? _singlePlayerValue<T>(T? value) =>
      _flow == NewGameFlow.singlePlayer ? value : null;

  void _selectStep(NewGameStep step) {
    if (step == NewGameStep.review && _selectedMap == null) return;
    _updateState(() => _step = step);
  }

  void _selectMap(MapSelection map) {
    _updateState(() {
      _selectedMap = map;
      _mapPickedManually = true;
      _step = NewGameStep.review;
    });
  }
}
