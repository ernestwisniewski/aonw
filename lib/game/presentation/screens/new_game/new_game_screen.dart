import 'dart:math' as math;

import 'package:aonw/game/application/use_cases/create_local_game_use_case.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/new_game/initial_player_country.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_screen_action_bar.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_screen_review_step.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_setup_options.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_single_player_setup.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/map/widgets/map_selection_tile.dart';
import 'package:aonw/menu/main_menu_update_notice.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_gamepad_input.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_section_header.dart';
import 'package:aonw/shared/widgets/game_ui/gold_divider.dart';
import 'package:aonw/shared/widgets/scrollable_error_view.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'new_game_screen_content.dart';
part 'new_game_screen_layout_widgets.dart';
part 'new_game_screen_map_step.dart';
part 'new_game_screen_plan_step.dart';
part 'new_game_screen_plan_summary_widgets.dart';
part 'new_game_screen_single_player_panels.dart';

class NewGameScreen extends ConsumerStatefulWidget {
  final NewGameFlow flow;
  final bool startAtMap;
  final PlayerCountry? initialPlayerCountry;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  const NewGameScreen({
    this.flow = NewGameFlowX.defaultFlow,
    this.startAtMap = false,
    this.initialPlayerCountry,
    this.gamepadInputListenable,
    super.key,
  });

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  late NewGameFlow _flow = widget.flow;
  NewGameStep _step = NewGameStep.plan;
  MapSelection? _selectedMap;
  late PlayerCountry _selectedPlayerCountry =
      widget.initialPlayerCountry ?? randomInitialPlayerCountry();
  SinglePlayerGameLengthPreset _selectedGameLengthPreset =
      SinglePlayerGameLengthPreset.normal90;
  AiDifficulty _selectedAiDifficulty = AiDifficulty.normal;
  bool _startingSinglePlayer = false;
  bool _autoOpenedMultiplayerLobby = false;
  bool _mapPickedManually = false;

  GameLengthConfig get _selectedGameLength => _selectedGameLengthPreset.config;

  void _updateState(VoidCallback update) => setState(update);

  @override
  void didUpdateWidget(NewGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flow != widget.flow ||
        oldWidget.startAtMap != widget.startAtMap) {
      _flow = widget.flow;
      _step = NewGameStep.plan;
      _selectedMap = null;
      _autoOpenedMultiplayerLobby = false;
      _mapPickedManually = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mapsAsync = ref.watch(availableMapsProvider);
    final multiplayerAccessAllowed = ref.watch(
      mainMenuMultiplayerAccessAllowedProvider,
    );

    return MenuGamepadInputBinding(
      input: widget.gamepadInputListenable,
      onCancel: ref.withMenuBack(_handleBack),
      child: Scaffold(
        backgroundColor: GameUiTheme.bg,
        appBar: GameUiAppBar(
          title: GameText.screenTitle(l10n.newGameTitle),
          onClose: ref.withMenuBack(_handleBack),
        ),
        bottomNavigationBar: mapsAsync.maybeWhen(
          data: (maps) => NewGameActionBar(
            step: _step,
            flow: _flow,
            maps: maps,
            singlePlayerPlayerCount: _selectedSinglePlayerPlayerCount(),
            multiplayerAccessAllowed: multiplayerAccessAllowed,
            selectedMap: _selectedMap,
            startingSinglePlayer: _startingSinglePlayer,
            onStepSelected: _selectStep,
            onContinue: _continueToReview,
            onStart: _startSelectedMap,
          ),
          orElse: () => null,
        ),
        body: MenuRouteBackdrop(
          child: mapsAsync.when(
            loading: () => const _NewGameLoading(),
            error: (error, _) => ScrollableErrorView(
              message: l10n.mapsLoadError('$error'),
              actionLabel: GameText.actionLabel(l10n.retryAction),
              onAction: ref.withMenuClick(
                () => ref.invalidate(availableMapsProvider),
              ),
            ),
            data: (maps) => _buildContent(
              context,
              maps,
              multiplayerAccessAllowed: multiplayerAccessAllowed,
            ),
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    switch (_step) {
      case NewGameStep.plan:
        context.go('/');
      case NewGameStep.map:
        setState(() {
          _step = _selectedMap == null ? NewGameStep.plan : NewGameStep.review;
        });
      case NewGameStep.review:
        setState(() => _step = NewGameStep.plan);
    }
  }

  void _continueToReview(
    List<MapSelection> maps,
    bool multiplayerAccessAllowed,
  ) {
    if (_flow == NewGameFlow.multiplayer) {
      if (!multiplayerAccessAllowed) return;
      _openLobby(_randomMultiplayerMap(maps));
      return;
    }
    setState(() {
      _selectedMap ??= _randomGameMap(maps);
      _step = NewGameStep.review;
    });
  }

  Future<void> _startSelectedMap(
    MapSelection map, {
    required bool multiplayerAccessAllowed,
  }) async {
    if (!_flow.enabled) return;
    if (_flow == NewGameFlow.singlePlayer) {
      await _startSinglePlayer(map);
      return;
    }
    if (multiplayerAccessAllowed) _openLobby(map);
  }

  Future<void> _startSinglePlayer(MapSelection map) async {
    setState(() => _startingSinglePlayer = true);
    final gameLength = _selectedGameLength;
    final aiDifficulty = _selectedAiDifficulty;
    try {
      final l10n = context.l10n;
      final mapData = await ref.read(activeMapProvider(map).future);
      final playerCount = NewGameSinglePlayerSetup.playerCountForWorldMap(
        mapData,
      );
      final validation = MapValidator.validate(
        mapData: mapData,
        playerCount: playerCount,
        gameLength: gameLength,
      );
      if (validation.errors.isNotEmpty) {
        if (!mounted) return;
        GameToast.show(
          context,
          message: l10n.mapValidationErrorTitle,
          tone: GameToastTone.warning,
        );
        return;
      }

      final saveId =
          await CreateLocalGameUseCase(
            repository: ref.read(gameRepositoryProvider),
            clock: ref.read(gameClockProvider),
          ).execute(
            selection: map,
            mapData: mapData,
            gameMode: NewGameFlow.singlePlayer.gameMode,
            matchRules: MatchRules.forGameLength(gameLength),
            players: NewGameSinglePlayerSetup.players(
              selectedPlayerCountry: _selectedPlayerCountry,
              aiDifficulty: aiDifficulty,
              leaderNameFor: (country) =>
                  GameDisplayNames.playerCountryLeader(l10n, country),
              playerCount: playerCount,
            ),
          );
      if (!mounted) return;
      context.go(
        '/game?saveId=$saveId'
        '&name=${Uri.encodeComponent(map.name)}'
        '&source=${map.source.name}',
      );
    } finally {
      if (mounted) setState(() => _startingSinglePlayer = false);
    }
  }

  void _openLobby(MapSelection map) {
    if (!ref.read(mainMenuMultiplayerAccessAllowedProvider)) return;
    context.go(
      '/lobby?name=${Uri.encodeComponent(map.name)}'
      '&source=${map.sourceQueryValue}'
      '&mode=${_flow.queryValue}'
      '&country=${_selectedPlayerCountry.name}',
    );
  }

  MapSelection _randomMultiplayerMap(List<MapSelection> maps) {
    return _randomGameMap(maps);
  }

  MapSelection _randomGameMap(List<MapSelection> maps) {
    final official = maps
        .where((map) => map.source == MapSource.asset)
        .toList(growable: false);
    final candidates = official.isNotEmpty ? official : maps;
    if (candidates.isEmpty) {
      return const MapSelection(
        name: MapSelection.defaultMapName,
        source: MapSource.asset,
      );
    }
    if (candidates.length == 1) return candidates.first;
    final now = ref.read(gameClockProvider).now();
    final random = math.Random(now.microsecondsSinceEpoch);
    return candidates[random.nextInt(candidates.length)];
  }

  int _selectedSinglePlayerPlayerCount() {
    final map = _selectedMap;
    if (map == null) return NewGameFlowX.singlePlayerPlayerCount;
    final mapAsync = ref.watch(activeMapProvider(map));
    return switch (mapAsync) {
      AsyncData(:final value) =>
        NewGameSinglePlayerSetup.playerCountForWorldMap(value),
      _ => NewGameSinglePlayerSetup.playerCountForMapName(map.name),
    };
  }
}
