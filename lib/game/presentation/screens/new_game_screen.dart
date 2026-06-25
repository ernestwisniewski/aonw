import 'dart:math' as math;

import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/initial_player_country.dart';
import 'package:aonw/game/presentation/screens/new_game_flow.dart';
import 'package:aonw/game/presentation/screens/new_game_single_player_setup.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/map/widgets/map_selection_tile.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_section_header.dart';
import 'package:aonw/shared/widgets/game_ui/gold_divider.dart';
import 'package:aonw/shared/widgets/scrollable_error_view.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'new_game_review_card.dart';
part 'new_game_screen_layout_widgets.dart';
part 'new_game_screen_plan_step.dart';
part 'new_game_screen_single_player_panels.dart';
part 'new_game_screen_plan_summary_widgets.dart';
part 'new_game_screen_map_step.dart';
part 'new_game_screen_review_step.dart';

enum _NewGameStep { plan, map, review }

enum _SinglePlayerGameLengthPreset { short60, normal90, long120, veryLong }

extension _SinglePlayerGameLengthPresetX on _SinglePlayerGameLengthPreset {
  GameLengthConfig get config {
    return switch (this) {
      _SinglePlayerGameLengthPreset.short60 => GameLengthConfig.standard60,
      _SinglePlayerGameLengthPreset.normal90 => GameLengthConfig.normal90,
      _SinglePlayerGameLengthPreset.long120 => GameLengthConfig.long120,
      _SinglePlayerGameLengthPreset.veryLong => GameLengthConfig.unlimited,
    };
  }

  IconData get icon {
    return switch (this) {
      _SinglePlayerGameLengthPreset.short60 => Icons.bolt_outlined,
      _SinglePlayerGameLengthPreset.normal90 => Icons.schedule_outlined,
      _SinglePlayerGameLengthPreset.long120 => Icons.hourglass_bottom_outlined,
      _SinglePlayerGameLengthPreset.veryLong => Icons.all_inclusive,
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      _SinglePlayerGameLengthPreset.short60 => l10n.gameLengthPresetShort60,
      _SinglePlayerGameLengthPreset.normal90 => l10n.gameLengthPresetNormal90,
      _SinglePlayerGameLengthPreset.long120 => l10n.gameLengthPresetLong120,
      _SinglePlayerGameLengthPreset.veryLong => l10n.gameLengthPresetVeryLong,
    };
  }
}

extension _AiDifficultyDisplay on AiDifficulty {
  IconData get icon {
    return switch (this) {
      AiDifficulty.easy => Icons.sentiment_satisfied_alt_outlined,
      AiDifficulty.normal => Icons.psychology_alt_outlined,
      AiDifficulty.hard => Icons.local_fire_department_outlined,
      AiDifficulty.veryHard => Icons.military_tech_outlined,
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      AiDifficulty.easy => l10n.aiDifficultyEasy,
      AiDifficulty.normal => l10n.aiDifficultyNormal,
      AiDifficulty.hard => l10n.aiDifficultyHard,
      AiDifficulty.veryHard => l10n.aiDifficultyVeryHard,
    };
  }
}

class NewGameScreen extends ConsumerStatefulWidget {
  final NewGameFlow flow;
  final bool startAtMap;
  final PlayerCountry? initialPlayerCountry;

  const NewGameScreen({
    this.flow = NewGameFlowX.defaultFlow,
    this.startAtMap = false,
    this.initialPlayerCountry,
    super.key,
  });

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  late NewGameFlow _flow = widget.flow;
  late _NewGameStep _step = _initialStep();
  MapSelection? _selectedMap;
  late PlayerCountry _selectedPlayerCountry =
      widget.initialPlayerCountry ?? randomInitialPlayerCountry();
  _SinglePlayerGameLengthPreset _selectedGameLengthPreset =
      _SinglePlayerGameLengthPreset.normal90;
  AiDifficulty _selectedAiDifficulty = AiDifficulty.normal;
  bool _startingSinglePlayer = false;
  bool _autoOpenedMultiplayerLobby = false;
  bool _mapPickedManually = false;

  GameLengthConfig get _selectedGameLength => _selectedGameLengthPreset.config;

  @override
  void didUpdateWidget(NewGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flow != widget.flow ||
        oldWidget.startAtMap != widget.startAtMap) {
      _flow = widget.flow;
      _step = _initialStep();
      _selectedMap = null;
      _autoOpenedMultiplayerLobby = false;
      _mapPickedManually = false;
    }
  }

  _NewGameStep _initialStep() {
    if (!widget.flow.enabled) return _NewGameStep.plan;
    return _NewGameStep.plan;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mapsAsync = ref.watch(availableMapsProvider);

    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      appBar: GameUiAppBar(
        title: GameText.screenTitle(l10n.newGameTitle),
        onClose: ref.withMenuBack(_handleBack),
      ),
      bottomNavigationBar: mapsAsync.maybeWhen(
        data: (maps) => _buildActionBar(
          context,
          maps,
          singlePlayerPlayerCount: _selectedSinglePlayerPlayerCount(),
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
          data: (maps) => _buildContent(context, maps),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<MapSelection> maps) {
    final l10n = context.l10n;
    if (widget.startAtMap &&
        _flow == NewGameFlow.multiplayer &&
        !_autoOpenedMultiplayerLobby) {
      _autoOpenedMultiplayerLobby = true;
      final map = _randomMultiplayerMap(maps);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openLobby(map);
      });
      return const _NewGameLoading();
    }

    final official = maps.where((m) => m.source == MapSource.asset).toList();
    final yours = maps.where((m) => m.source == MapSource.saved).toList();
    final reviewMapAsync = _selectedMap == null
        ? null
        : ref.watch(activeMapProvider(_selectedMap!));
    final reviewSinglePlayerPlayerCount = switch (reviewMapAsync) {
      AsyncData(:final value) => NewGameSinglePlayerSetup.playerCountForMapData(
        value,
      ),
      _ => NewGameSinglePlayerSetup.playerCountForMapName(_selectedMap?.name),
    };
    final reviewMapValidation = switch (reviewMapAsync) {
      AsyncData(:final value) => MapValidator.validate(
        mapData: value,
        playerCount: reviewSinglePlayerPlayerCount,
        gameLength: _selectedGameLength,
      ),
      _ => null,
    };
    final reviewMapValidationLoading = switch (reviewMapAsync) {
      AsyncLoading() => true,
      _ => false,
    };
    final reviewMapValidationError = switch (reviewMapAsync) {
      AsyncError(:final error) => error,
      _ => null,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        GameUiScreenHeader(
          icon: _flow.icon,
          title: l10n.newGameIntroTitle,
          subtitle: l10n.newGameIntroSubtitle,
          meta: [
            MenuMetricPill(
              icon: Icons.public_outlined,
              label: l10n.officialMapsCount(official.length),
            ),
            MenuMetricPill(
              icon: Icons.edit_location_alt_outlined,
              label: l10n.yourMapsCount(yours.length),
            ),
          ],
        ),
        _NewGameStepRail(
          step: _step,
          onStepSelected: (step) {
            if (step == _NewGameStep.review && _selectedMap == null) return;
            setState(() => _step = step);
          },
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: GameMotion.scene,
          switchInCurve: GameMotion.enter,
          switchOutCurve: GameMotion.exit,
          child: switch (_step) {
            _NewGameStep.plan => _PlanStep(
              key: const ValueKey('newGame.plan'),
              flow: _flow,
              playerCountry: _selectedPlayerCountry,
              gameLengthPreset: _selectedGameLengthPreset,
              aiDifficulty: _selectedAiDifficulty,
              onFlowChanged: (flow) => setState(() => _flow = flow),
              onPlayerCountryChanged: (country) =>
                  setState(() => _selectedPlayerCountry = country),
              onGameLengthChanged: (preset) =>
                  setState(() => _selectedGameLengthPreset = preset),
              onAiDifficultyChanged: (difficulty) =>
                  setState(() => _selectedAiDifficulty = difficulty),
            ),
            _NewGameStep.map => _MapStep(
              key: const ValueKey('newGame.map'),
              official: official,
              yours: yours,
              onMapSelected: (map) => setState(() {
                _selectedMap = map;
                _mapPickedManually = true;
                _step = _NewGameStep.review;
              }),
            ),
            _NewGameStep.review => _ReviewStep(
              key: const ValueKey('newGame.review'),
              flow: _flow,
              map: _selectedMap,
              playerCountry: _selectedPlayerCountry,
              gameLengthPreset: _selectedGameLengthPreset,
              aiDifficulty: _selectedAiDifficulty,
              mapPickedManually: _mapPickedManually,
              singlePlayerPlayerCount: reviewSinglePlayerPlayerCount,
              mapValidation: _flow == NewGameFlow.singlePlayer
                  ? reviewMapValidation
                  : null,
              mapValidationLoading: _flow == NewGameFlow.singlePlayer
                  ? reviewMapValidationLoading
                  : false,
              mapValidationError: _flow == NewGameFlow.singlePlayer
                  ? reviewMapValidationError
                  : null,
            ),
          },
        ),
      ],
    );
  }

  Widget? _buildActionBar(
    BuildContext context,
    List<MapSelection> maps, {
    required int singlePlayerPlayerCount,
  }) {
    final l10n = context.l10n;
    final singlePlayerAiOpponentCount =
        NewGameSinglePlayerSetup.aiOpponentCountForPlayerCount(
          singlePlayerPlayerCount,
        );
    return switch (_step) {
      _NewGameStep.plan => MenuActionBar(
        primaryKey: _flow == NewGameFlow.multiplayer
            ? const Key('newGame.multiplayerLobbyAction')
            : null,
        summary: _NewGameActionSummary(
          icon: _flow.icon,
          title: _flow.menuLabel(l10n),
          subtitle: _flowDescription(l10n, _flow),
        ),
        primaryLabel: GameText.actionLabel(
          _flow == NewGameFlow.multiplayer
              ? l10n.newGameStartSetupAction
              : l10n.continueAction,
        ),
        primaryIcon: Icons.arrow_forward_rounded,
        onPrimary: _flow.enabled
            ? ref.withMenuClick(() => _continueToReview(maps))
            : null,
      ),
      _NewGameStep.map => MenuActionBar(
        summary: _NewGameActionSummary(
          icon: Icons.map_outlined,
          title: l10n.newGameMapTitle,
          subtitle: l10n.newGameMapSubtitle,
        ),
        secondaryLabel: GameText.actionLabel(l10n.backAction),
        secondaryIcon: Icons.arrow_back_rounded,
        onSecondary: ref.withMenuClick(
          () => setState(() {
            _step = _selectedMap == null
                ? _NewGameStep.plan
                : _NewGameStep.review;
          }),
        ),
      ),
      _NewGameStep.review => MenuActionBar(
        summary: _NewGameActionSummary(
          icon: _flow.icon,
          title: _selectedMap?.displayName ?? l10n.noMapsTitle,
          subtitle: _flow == NewGameFlow.singlePlayer
              ? l10n.newGameReviewSinglePlayerSubtitle(
                  singlePlayerAiOpponentCount,
                )
              : l10n.newGameReviewSubtitle,
        ),
        secondaryLabel: GameText.actionLabel(l10n.newGameChangeMapAction),
        secondaryIcon: Icons.map_outlined,
        onSecondary: ref.withMenuClick(
          () => setState(() => _step = _NewGameStep.map),
        ),
        primaryLabel: GameText.actionLabel(
          _flow == NewGameFlow.singlePlayer
              ? l10n.startGameAction
              : l10n.newGameStartSetupAction,
        ),
        primaryIcon: _flow == NewGameFlow.singlePlayer
            ? Icons.play_arrow_rounded
            : Icons.arrow_forward_rounded,
        primaryBusy: _startingSinglePlayer,
        onPrimary:
            _selectedMap == null || _startingSinglePlayer || !_flow.enabled
            ? null
            : ref.withMenuClickAsync(() => _startSelectedMap(_selectedMap!)),
      ),
    };
  }

  void _handleBack() {
    switch (_step) {
      case _NewGameStep.plan:
        context.go('/');
      case _NewGameStep.map:
        setState(() {
          _step = _selectedMap == null
              ? _NewGameStep.plan
              : _NewGameStep.review;
        });
      case _NewGameStep.review:
        setState(() => _step = _NewGameStep.plan);
    }
  }

  void _continueToReview(List<MapSelection> maps) {
    if (_flow == NewGameFlow.multiplayer) {
      _openLobby(_randomMultiplayerMap(maps));
      return;
    }
    setState(() {
      _selectedMap ??= _randomGameMap(maps);
      _step = _NewGameStep.review;
    });
  }

  Future<void> _startSelectedMap(MapSelection map) async {
    if (!_flow.enabled) return;
    if (_flow == NewGameFlow.singlePlayer) {
      await _startSinglePlayer(map);
      return;
    }
    _openLobby(map);
  }

  Future<void> _startSinglePlayer(MapSelection map) async {
    setState(() => _startingSinglePlayer = true);
    final gameLength = _selectedGameLength;
    final aiDifficulty = _selectedAiDifficulty;
    try {
      final l10n = context.l10n;
      final mapData = await ref.read(activeMapProvider(map).future);
      final playerCount = NewGameSinglePlayerSetup.playerCountForMapData(
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

      final saveRepository = ref.read(gameRepositoryProvider);
      final now = ref.read(gameClockProvider).now();
      final saveId = await saveRepository.create(
        NewGameRequest(
          name: saveRepository.defaultSaveName(map.displayName, now),
          mapName: map.name,
          mapSource: map.source,
          gameMode: NewGameFlow.singlePlayer.gameMode,
          matchRules: MatchRules.forGameLength(gameLength),
          players: NewGameSinglePlayerSetup.players(
            selectedPlayerCountry: _selectedPlayerCountry,
            aiDifficulty: aiDifficulty,
            leaderNameFor: (country) =>
                GameDisplayNames.playerCountryLeader(l10n, country),
            playerCount: playerCount,
          ),
          mapData: mapData,
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
      AsyncData(:final value) => NewGameSinglePlayerSetup.playerCountForMapData(
        value,
      ),
      _ => NewGameSinglePlayerSetup.playerCountForMapName(map.name),
    };
  }
}
