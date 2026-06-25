import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/initial_player_country.dart';
import 'package:aonw/game/presentation/screens/lobby_auto_start_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby_live_match_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby_match_action_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby_match_navigation_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby_match_status_rules.dart';
import 'package:aonw/game/presentation/screens/lobby_network_session_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby_player_setup_controller.dart';
import 'package:aonw/game/presentation/screens/multiplayer_account_dialog.dart';
import 'package:aonw/game/presentation/screens/new_game_flow.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_player_capacity.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

part 'lobby_screen_form_widgets.dart';
part 'lobby_screen_multiplayer_profile_panel.dart';
part 'lobby_screen_layout_widgets.dart';
part 'lobby_screen_game_setup_widgets.dart';
part 'lobby_screen_action_bar.dart';
part 'lobby_screen_local_setup_panel.dart';
part 'lobby_screen_player_row.dart';
part 'lobby_screen_player_setup_widgets.dart';
part 'lobby_screen_multiplayer_panels.dart';
part 'lobby_screen_queue_countdown.dart';
part 'lobby_network_error_messages.dart';
part 'lobby_screen_private_match_panel.dart';
part 'lobby_screen_multiplayer_status_widgets.dart';
part 'lobby_screen_player_list_widgets.dart';

enum _MultiplayerLobbyMode { home, quickplay, privateHost, privateJoin }

final class _NetworkAuthCancelledException implements Exception {}

class LobbyScreen extends ConsumerStatefulWidget {
  final String mapName;
  final MapSource mapSource;
  final NewGameFlow flow;
  final PlayerCountry? playerCountry;

  const LobbyScreen({
    required this.mapName,
    required this.mapSource,
    this.flow = NewGameFlow.hotSeat,
    this.playerCountry,
    super.key,
  });

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _inviteCodeController;
  late final LobbyPlayerSetupController _players;
  late final LobbyAutoStartCoordinator _autoStartCoordinator;
  late final LobbyLiveMatchCoordinator _liveMatchCoordinator;
  late final LobbyMatchNavigationCoordinator _matchNavigationCoordinator;
  _GameLengthPreset _gameLengthPreset = _GameLengthPreset.unlimited;
  _MultiplayerLobbyMode _multiplayerMode = _MultiplayerLobbyMode.home;
  bool _starting = false;
  bool _networkBusy = false;
  String? _networkError;
  WireMatch? _activeMatch;
  bool _localizedDefaultsApplied = false;
  late final String _multiplayerDefaultPlayerName;
  int? _scheduledMapMaximumPlayers;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _multiplayerDefaultPlayerName = _randomMultiplayerPlayerName(random);
    final initialPlayerCountry =
        widget.playerCountry ?? randomInitialPlayerCountry(random: random);
    final selection = MapSelection(
      name: widget.mapName,
      source: widget.mapSource,
    );
    final saveRepository = ref.read(gameRepositoryProvider);
    final now = ref.read(gameClockProvider).now();
    _nameController = TextEditingController(
      text: saveRepository.defaultSaveName(selection.displayName, now),
    );
    _inviteCodeController = TextEditingController();
    _players = LobbyPlayerSetupController(
      flow: widget.flow,
      primaryCountry: initialPlayerCountry,
      maximumPlayers: MapPlayerCapacityRules.maxPlayersForMapName(
        widget.mapName,
      ),
    );
    if (widget.flow == NewGameFlow.multiplayer) {
      unawaited(_loadStoredMultiplayerDisplayName());
    }
    _autoStartCoordinator = LobbyAutoStartCoordinator(
      now: () => ref.read(gameClockProvider).nowUtc(),
      isQuickplayMode: () =>
          _multiplayerMode == _MultiplayerLobbyMode.quickplay,
      activeMatch: () => _activeMatch,
      canContinue: () => mounted,
      refreshActiveMatch: () => unawaited(_refreshActiveMatch()),
      notifyCountdownChanged: () {
        if (mounted) setState(() {});
      },
    );
    _liveMatchCoordinator = LobbyLiveMatchCoordinator(
      activeMatch: () => _activeMatch,
      canContinue: () => mounted,
      subscribe: _subscribeLobbyMatch,
      applyMatchUpdate: _applyLobbyMatchUpdateNow,
      showError: _showNetworkError,
      reportStreamError: _shouldReportLobbyStreamError,
      defer: (action) => unawaited(Future<void>(action)),
    );
    _matchNavigationCoordinator = LobbyMatchNavigationCoordinator(
      activeMatch: () => _activeMatch,
      canContinue: () => mounted,
      sessionForMatch: ({required session, required match}) {
        return _networkSessionCoordinator().sessionForMatch(
          session: session,
          match: match,
        );
      },
      setSession: (session) {
        ref.read(networkSessionStateProvider.notifier).set(session);
      },
      navigateTo: (location) => context.go(location),
      stopLobbyUpdates: _stopLobbyUpdates,
      defer: (action) => unawaited(Future<void>(action)),
      mapSource: MapSource.asset,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedDefaultsApplied) return;
    _players.applyLocalizedDefaults(_defaultPlayerName);
    _localizedDefaultsApplied = true;
  }

  @override
  void dispose() {
    _stopLobbyUpdates();
    _nameController.dispose();
    _inviteCodeController.dispose();
    _players.dispose();
    super.dispose();
  }

  GameMode get _gameMode => widget.flow.gameMode;

  bool get _isNetworkLobby => widget.flow == NewGameFlow.multiplayer;

  bool get _canEditPlayerKinds => _players.canEditPlayerKinds;

  bool get _canAddPlayers => _players.canAddPlayers;

  bool get _canStart => _players.canStartLocalGame;

  GameLengthConfig get _selectedGameLength => _gameLengthPreset.config;

  MatchRules get _selectedMatchRules {
    return MatchRules.forGameLength(_selectedGameLength);
  }

  void _addPlayer() {
    if (_players.addPlayer(_defaultPlayerName)) setState(() {});
  }

  String _defaultPlayerName(int zeroBasedIndex, PlayerCountry country) {
    final index = zeroBasedIndex + 1;
    final l10n = AppLocalizations.of(context);
    if (widget.flow == NewGameFlow.multiplayer && zeroBasedIndex == 0) {
      return _multiplayerDefaultPlayerName;
    }
    if (widget.flow == NewGameFlow.singlePlayer) {
      return GameDisplayNames.playerCountryLeader(l10n, country);
    }
    return l10n.defaultPlayerName(index);
  }

  String _randomMultiplayerPlayerName(math.Random random) {
    return 'Player${1000 + random.nextInt(9000)}';
  }

  void _removePlayer(int index) {
    if (_players.removePlayer(index)) setState(() {});
  }

  void _setPlayerKind(int index, PlayerKind kind) {
    if (_players.setKind(index, kind)) setState(() {});
  }

  void _setPlayerCountry(int index, PlayerCountry country) {
    if (_players.setCountry(index, country, _defaultPlayerName)) {
      setState(() {});
    }
  }

  Future<void> _start() async {
    if (!_canStart || _starting) return;
    setState(() => _starting = true);

    final gameName = _nameController.text.trim();
    final selection = MapSelection(
      name: widget.mapName,
      source: widget.mapSource,
    );

    try {
      final mapData = await ref.read(activeMapProvider(selection).future);
      if (_applyMapPlayerCapacity(mapData) && mounted) setState(() {});
      final players = _players.buildPlayers(_defaultPlayerName);
      final validation = _validateMapSetup(mapData);
      if (validation.errors.isNotEmpty) return;
      final saveRepository = ref.read(gameRepositoryProvider);
      final now = ref.read(gameClockProvider).now();
      final saveId = await saveRepository.create(
        NewGameRequest(
          name: gameName.isEmpty
              ? saveRepository.defaultSaveName(selection.displayName, now)
              : gameName,
          mapName: widget.mapName,
          mapSource: widget.mapSource,
          gameMode: _gameMode,
          matchRules: _selectedMatchRules,
          players: players,
          mapData: mapData,
        ),
      );
      if (!mounted) return;
      context.go(
        '/game?saveId=$saveId'
        '&name=${Uri.encodeComponent(widget.mapName)}'
        '&source=${widget.mapSource.name}',
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _startQuickplayQueue() async {
    if (!_isNetworkLobby) return;
    if (_networkBusy) return;
    _stopLobbyUpdates();
    setState(() => _multiplayerMode = _MultiplayerLobbyMode.quickplay);
    await _joinQuickplayQueue();
  }

  Future<void> _retryQuickplayQueue() async {
    _stopLobbyUpdates();
    await _startQuickplayQueue();
  }

  Future<void> _joinQuickplayQueue() async {
    await _runNetworkAction(() async {
      await _matchActionCoordinator().joinQuickplay(_matchActionConfig());
    });
  }

  Future<void> _cancelQuickplayQueue() async {
    await _runNetworkAction(() async {
      await _matchActionCoordinator().cancelQuickplay(
        activeMatch: _activeMatch,
      );
    });
    if (!mounted) return;
    setState(() => _multiplayerMode = _MultiplayerLobbyMode.home);
  }

  Future<void> _signOutMultiplayerAccount() async {
    _stopLobbyUpdates();
    await _sessionStore().clear();
    ref.read(networkSessionStateProvider.notifier).set(null);
    if (!mounted) return;
    setState(() {
      _networkError = null;
      _activeMatch = null;
      _multiplayerMode = _MultiplayerLobbyMode.home;
    });
    GameToast.show(
      context,
      message: context.l10n.multiplayerAccountSignedOut,
      tone: GameToastTone.success,
    );
  }

  Future<void> _createPrivateMatch() async {
    _stopLobbyUpdates();
    await _runNetworkAction(() async {
      await _matchActionCoordinator().createPrivate(_matchActionConfig());
      if (!mounted) return;
      setState(() => _multiplayerMode = _MultiplayerLobbyMode.privateHost);
    });
  }

  void _openJoinPrivateMatch() {
    _stopLobbyUpdates();
    setState(() {
      _networkError = null;
      _activeMatch = null;
      _multiplayerMode = _MultiplayerLobbyMode.privateJoin;
    });
  }

  Future<void> _joinPrivateMatch() async {
    await _runNetworkAction(() async {
      await _matchActionCoordinator().joinPrivate(
        inviteCode: _inviteCodeController.text,
        inviteCodeRequiredMessage: context.l10n.multiplayerInviteCodeRequired,
        config: _matchActionConfig(),
      );
      if (!mounted) return;
      setState(() => _multiplayerMode = _MultiplayerLobbyMode.privateJoin);
    });
  }

  Future<void> _startPrivateMatch() async {
    await _runNetworkAction(() async {
      await _matchActionCoordinator().startPrivate(activeMatch: _activeMatch);
    });
  }

  Future<void> _refreshActiveMatch() async {
    if (_networkBusy) return;
    final matchId = _activeMatch?.id;
    if (matchId == null) return;
    try {
      await _matchActionCoordinator().refreshActiveMatch(matchId: matchId);
      if (!mounted) return;
      setState(() => _networkError = null);
    } catch (error) {
      if (!mounted) return;
      _showNetworkError(error);
    }
  }

  Future<void> _shareInviteCode() async {
    final code = _activeMatch?.inviteCode;
    if (code == null || code.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(text: context.l10n.multiplayerInviteShareText(code)),
    );
  }

  Future<void> _copyInviteCode() async {
    final code = _activeMatch?.inviteCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    GameToast.show(
      context,
      message: context.l10n.multiplayerInviteCopied,
      tone: GameToastTone.success,
    );
  }

  Future<void> _runNetworkAction(Future<void> Function() action) async {
    if (_networkBusy) return;
    setState(() {
      _networkBusy = true;
      _networkError = null;
    });
    try {
      await action();
    } catch (error) {
      if (error is _NetworkAuthCancelledException) return;
      if (!mounted) return;
      _showNetworkError(error);
    } finally {
      if (mounted) setState(() => _networkBusy = false);
    }
  }

  void _showNetworkError(Object error) {
    final message = _networkErrorText(error);
    setState(() => _networkError = message);
    GameToast.show(context, message: message, tone: GameToastTone.error);
  }

  bool _shouldReportLobbyStreamError(Object error) {
    if (error is sp.MultiplayerException) return true;
    final match = _activeMatch;
    return match == null || LobbyMatchStatusRules.canEnter(match);
  }

  Future<NetworkSession> _ensureNetworkSession() async {
    final displayName = await _sessionStore().loadDisplayName();
    try {
      return await _networkSessionCoordinator().ensureSession(
        displayName: displayName,
      );
    } on NetworkSignInRequiredException {
      if (!mounted) throw _NetworkAuthCancelledException();
      final client = _sessionClient();
      final auth = await showMultiplayerAccountDialog(
        context: context,
        login: client.login,
        createAccount: client.createAccount,
        socialAuthClientFactory: () =>
            createMultiplayerSocialAuthClient(client.serverpodHost),
        completeSocialAuth: client.completeSocialAuth,
        steamAuth: client.loginWithSteam,
        initialDisplayName: _multiplayerDisplayName(),
      );
      if (auth == null) throw _NetworkAuthCancelledException();
      final session = auth.toSession(
        changedAt: ref.read(gameClockProvider).nowUtc(),
      );
      ref.read(networkSessionStateProvider.notifier).set(session);
      _players.nameControllerAt(0).text = auth.displayName;
      await _sessionStore().saveDisplayName(auth.displayName);
      final stored = auth.toStoredSession(displayName: auth.displayName);
      if (stored != null) await _sessionStore().save(stored);
      return session;
    }
  }

  LobbyMatchActionCoordinator _matchActionCoordinator() {
    final client = _sessionClient();
    return LobbyMatchActionCoordinator(
      ensureSession: _ensureNetworkSession,
      validateMap: _validateQuickplayMap,
      quickplay: client.quickplay,
      createPrivateMatch: client.createPrivateMatch,
      joinPrivateMatch: client.joinPrivateMatch,
      startMatch: client.startMatch,
      loadMatch: client.loadMatch,
      leaveMatch: client.leaveMatch,
      rememberMatch: _rememberActiveMatch,
      watchMatch: _liveMatchCoordinator.watch,
      clearMatch: (session) {
        _clearNetworkActiveMatch(session);
        _activeMatch = null;
      },
      enterMatch: _enterMultiplayerMatch,
      scheduleAutoStartRefresh: _scheduleAutoStartRefresh,
      stopLobbyUpdates: _stopLobbyUpdates,
      canContinue: () => mounted,
    );
  }

  LobbyMatchActionConfig _matchActionConfig() {
    return LobbyMatchActionConfig(
      mapName: widget.mapName,
      displayName: _multiplayerDisplayName(),
      country: _players.countryAt(0),
      mapNotReadyMessage: context.l10n.multiplayerMapNotReady,
      matchRules: MatchRules.standard,
    );
  }

  void _rememberActiveMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    _activeMatch = match;
    ref.read(multiplayerMatchProvider.notifier).upsert(match);
    _networkSessionCoordinator().applyActiveMatch(
      session: session,
      match: match,
    );
  }

  void _clearNetworkActiveMatch(NetworkSession session) {
    _networkSessionCoordinator().clearActiveMatch(session);
  }

  void _enterMultiplayerMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    _matchNavigationCoordinator.enter(session: session, match: match);
  }

  LobbyNetworkSessionCoordinator _networkSessionCoordinator() {
    final client = _sessionClient();
    final store = _sessionStore();
    return LobbyNetworkSessionCoordinator(
      currentSession: () => ref.read(networkSessionProvider),
      setSession: _setNetworkSessionDeferred,
      loadStoredSession: store.load,
      saveStoredSession: store.save,
      clearStoredSession: store.clear,
      saveMatchId: store.saveMatchId,
      refreshToken: client.refresh,
      now: () => ref.read(gameClockProvider).nowUtc(),
    );
  }

  void _setNetworkSessionDeferred(NetworkSession? session) {
    unawaited(
      Future<void>(() {
        if (!mounted) return;
        ref.read(networkSessionStateProvider.notifier).set(session);
      }),
    );
  }

  NetworkSessionClient _sessionClient() {
    return ref.read(networkSessionClientProvider);
  }

  NetworkSessionStore _sessionStore() {
    return ref.read(networkSessionStoreProvider);
  }

  void _stopLobbyUpdates() {
    _autoStartCoordinator.cancel();
    unawaited(_liveMatchCoordinator.close());
  }

  Future<LobbyLiveMatchStreamHandle> _subscribeLobbyMatch({
    required NetworkSession session,
    required WireMatch match,
    required void Function(WireMatch match) onMatch,
    required void Function(Object error, StackTrace stackTrace) onError,
  }) async {
    final handle =
        await LiveEventSubscription(
          serverpodHost: ref.read(apiConfigProvider).baseUrl.toString(),
          connector: ref.read(multiplayerStreamConnectorProvider),
        ).subscribe(
          matchId: match.id,
          token: session.token,
          fromOffset: 0,
          onEvent: (_) {},
          onSnapshotResync: (_) {},
          onMatch: onMatch,
          onError: onError,
        );
    return LiveEventLobbyMatchStreamHandle(handle);
  }

  void _applyLobbyMatchUpdateNow({
    required NetworkSession session,
    required WireMatch match,
  }) {
    if (!mounted || _activeMatch?.id != match.id) return;
    if (!session.isConnected) return;
    _rememberActiveMatch(session: session, match: match);
    if (!mounted) return;
    setState(() => _networkError = null);
    if (LobbyMatchStatusRules.canEnter(match)) {
      _stopLobbyUpdates();
      _enterMultiplayerMatch(session: session, match: match);
    } else {
      _scheduleAutoStartRefresh(match);
    }
  }

  void _scheduleAutoStartRefresh(WireMatch match) {
    _autoStartCoordinator.schedule(match);
  }

  String _multiplayerDisplayName() {
    final value = _players.nameControllerAt(0).text.trim();
    return value.isEmpty
        ? _players.defaultNameFor(0, _defaultPlayerName)
        : value;
  }

  Future<void> _loadStoredMultiplayerDisplayName() async {
    final displayName = await _sessionStore().loadDisplayName();
    if (!mounted || !_isNetworkLobby) return;
    final normalized = displayName.trim();
    if (normalized.isEmpty || normalized == 'Player') return;
    final controller = _players.nameControllerAt(0);
    final current = controller.text.trim();
    if (current.isNotEmpty && current != _multiplayerDefaultPlayerName) {
      return;
    }
    controller.text = normalized;
    setState(() {});
  }

  String _networkErrorText(Object error) {
    return _LobbyNetworkErrorMessages(
      l10n: context.l10n,
      apiHost: ref.read(apiConfigProvider).baseUrl.host,
    ).textFor(error);
  }

  Future<MapValidationResult> _validateQuickplayMap() async {
    final selection = MapSelection(
      name: widget.mapName,
      source: widget.mapSource,
    );
    final mapData = await ref.read(activeMapProvider(selection).future);
    return MapValidator.validate(
      mapData: mapData,
      playerCount: 2,
      gameLength: GameLengthConfig.unlimited,
    );
  }

  MapValidationResult _validateMapSetup(MapData mapData) {
    return MapValidator.validate(
      mapData: mapData,
      playerCount: _players.playerCount,
      gameLength: _selectedGameLength,
    );
  }

  bool _applyMapPlayerCapacity(MapData mapData) {
    return _players.updateMaximumPlayers(
      MapPlayerCapacityRules.maxPlayersForMapData(mapData),
    );
  }

  void _scheduleMapPlayerCapacitySync(MapData mapData) {
    final maximumPlayers = MapPlayerCapacityRules.maxPlayersForMapData(mapData);
    if (_players.maximumPlayers == maximumPlayers ||
        _scheduledMapMaximumPlayers == maximumPlayers) {
      return;
    }
    _scheduledMapMaximumPlayers = maximumPlayers;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduledMapMaximumPlayers = null;
      if (_players.updateMaximumPlayers(maximumPlayers)) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selection = MapSelection(
      name: widget.mapName,
      source: widget.mapSource,
    );
    final mapAsync = ref.watch(activeMapProvider(selection));
    final MapValidationResult? mapValidation;
    switch (mapAsync) {
      case AsyncData(:final value):
        _scheduleMapPlayerCapacitySync(value);
        mapValidation = _validateMapSetup(value);
      default:
        mapValidation = null;
    }
    final mapValidationError = switch (mapAsync) {
      AsyncError(:final error) => error,
      _ => null,
    };
    final mapValidationLoading = switch (mapAsync) {
      AsyncLoading() => true,
      _ => false,
    };
    final hasMapValidationErrors =
        mapValidationError != null ||
        (mapValidation?.errors.isNotEmpty ?? false);
    final lobbyPlayerCount = _isNetworkLobby
        ? LobbyMatchStatusRules.humanPlayerCount(_activeMatch, whenMissing: 1)
        : _players.playerCount;
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      appBar: GameUiAppBar(
        title: GameText.screenTitle(widget.flow.menuLabel(l10n)),
        onClose: ref.withMenuBackAsync(_handleBack),
      ),
      bottomNavigationBar: _buildLobbyActionBar(
        selection: selection,
        hasMapValidationErrors: hasMapValidationErrors,
        l10n: l10n,
      ),
      body: MenuRouteBackdrop(
        maxContentWidth: 980,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            widget.flow.startsLocally ? 18 : 32,
          ),
          children: [
            _LobbyContentInset(
              child: GameUiScreenHeader(
                icon: widget.flow.icon,
                title: _lobbyHeaderTitle(l10n),
                subtitle: _lobbyHeaderSubtitle(l10n),
                meta: [
                  MenuMetricPill(
                    icon: widget.flow.icon,
                    label: widget.flow.summaryLabel(l10n),
                  ),
                  MenuMetricPill(
                    icon: Icons.person_outline,
                    label: _isNetworkLobby
                        ? _networkPlayersSummary(l10n)
                        : '$lobbyPlayerCount',
                  ),
                ],
              ),
            ),
            _LobbyContentInset(
              child: _LobbyStepRail(
                flow: widget.flow,
                multiplayerMode: _multiplayerMode,
                activeMatch: _activeMatch,
              ),
            ),
            const SizedBox(height: 14),
            if (_isNetworkLobby) ...[
              if (_showMultiplayerProfile) ...[
                _LobbyContentInset(child: _buildMultiplayerProfilePanel()),
                const SizedBox(height: 14),
              ],
              _LobbyContentInset(child: _buildMultiplayerPanel()),
            ] else
              _LobbyContentInset(
                child: _buildLocalSetup(
                  l10n: l10n,
                  mapValidation: mapValidation,
                  mapValidationLoading: mapValidationLoading,
                  mapValidationError: mapValidationError,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBack() async {
    if (!_isNetworkLobby) {
      context.go('/new-game?mode=${widget.flow.queryValue}');
      return;
    }

    if (_multiplayerMode == _MultiplayerLobbyMode.quickplay) {
      await _cancelQuickplayQueue();
      return;
    }

    if (_multiplayerMode != _MultiplayerLobbyMode.home) {
      _returnToMultiplayerHome();
      return;
    }

    context.go('/');
  }

  String _lobbyHeaderTitle(AppLocalizations l10n) {
    if (_isNetworkLobby) return l10n.multiplayerLobbyHeaderTitle;
    return l10n.lobbyHeaderTitle;
  }

  String _lobbyHeaderSubtitle(AppLocalizations l10n) {
    if (_isNetworkLobby) return l10n.multiplayerLobbyHeaderSubtitle;
    return l10n.lobbyHeaderSubtitle;
  }

  String _networkPlayersSummary(AppLocalizations l10n) {
    final match = _activeMatch;
    if (match == null) return l10n.matchPlayersCount(1, 4);
    return l10n.matchPlayersCount(
      LobbyMatchStatusRules.humanPlayerCount(match),
      match.maxPlayers,
    );
  }

  Widget _buildLocalSetup({
    required AppLocalizations l10n,
    required MapValidationResult? mapValidation,
    required bool mapValidationLoading,
    required Object? mapValidationError,
  }) {
    return _LobbyLocalSetupPanel(
      l10n: l10n,
      primaryCountryControl: _playerCountryControl(
        0,
        key: const Key('lobby.primaryCountryDropdown'),
      ),
      primaryLeaderName: GameDisplayNames.playerCountryLeader(
        l10n,
        _players.countryAt(0),
      ),
      selectedMapName: MapSelection(
        name: widget.mapName,
        source: widget.mapSource,
      ).displayName,
      nameController: _nameController,
      onNameChanged: (_) => setState(() {}),
      gameLengthPreset: _gameLengthPreset,
      onGameLengthPresetChanged: ref.withMenuClickValue(
        (preset) => setState(() => _gameLengthPreset = preset),
      ),
      mapValidation: mapValidation,
      mapValidationLoading: mapValidationLoading,
      mapValidationError: mapValidationError,
      playerCount: _players.playerCount,
      maximumPlayers: _players.maximumPlayers,
      canAddPlayers: _canAddPlayers,
      playerRowBuilder: _buildPlayerRow,
      onAddPlayer: ref.withMenuClick(_addPlayer),
    );
  }

  Widget? _buildLobbyActionBar({
    required MapSelection selection,
    required bool hasMapValidationErrors,
    required AppLocalizations l10n,
  }) {
    return _LobbyActionBarBuilder(
      l10n: l10n,
      selection: selection,
      flow: widget.flow,
      localPlayerCount: _players.playerCount,
      canStartLocalGame: _canStart,
      starting: _starting,
      hasMapValidationErrors: hasMapValidationErrors,
      multiplayerMode: _multiplayerMode,
      networkBusy: _networkBusy,
      activeMatch: _activeMatch,
      currentUserId: ref.watch(networkSessionProvider)?.userId,
      onStartLocalGame: ref.withMenuClickAsync(_start),
      onRetryQuickplay: ref.withMenuClickAsync(_retryQuickplayQueue),
      onCancelQuickplay: ref.withMenuClickAsync(_cancelQuickplayQueue),
      onJoinPrivateMatch: ref.withMenuClickAsync(_joinPrivateMatch),
      onStartPrivateMatch: ref.withMenuClickAsync(_startPrivateMatch),
      onBackToMultiplayerHome: ref.withMenuClick(_returnToMultiplayerHome),
    ).build();
  }

  void _returnToMultiplayerHome() {
    _stopLobbyUpdates();
    setState(() {
      _networkError = null;
      _activeMatch = null;
      _multiplayerMode = _MultiplayerLobbyMode.home;
    });
  }

  Widget _buildPlayerRow(int index) {
    final canRemove =
        _canAddPlayers &&
        index > 0 &&
        _players.playerCount > LobbyPlayerSetupController.minimumPlayers;
    final countryControl = index == 0
        ? _PlayerCountryBadge(country: _players.countryAt(index))
        : _playerCountryControl(index);

    return _LobbyPlayerRow(
      index: index,
      nameController: _players.nameControllerAt(index),
      nameHint: _players.defaultNameFor(index, _defaultPlayerName),
      countryControl: countryControl,
      kindControl: _playerKindControl(index),
      showKindControl: index > 0,
      canRemove: canRemove,
      onNameChanged: (_) => setState(() {}),
      onRemove: canRemove
          ? ref.withMenuClick(() => _removePlayer(index))
          : null,
    );
  }

  Widget _buildMultiplayerPanel() {
    final panel = switch (_multiplayerMode) {
      _MultiplayerLobbyMode.home => _MultiplayerHomePanel(
        busy: _networkBusy,
        error: _networkError,
        onQuickplay: ref.withMenuClickAsync(_startQuickplayQueue),
        onCreatePrivate: ref.withMenuClickAsync(_createPrivateMatch),
        onJoinPrivate: ref.withMenuClick(_openJoinPrivateMatch),
      ),
      _MultiplayerLobbyMode.quickplay => _MultiplayerQueuePanel(
        busy: _networkBusy,
        error: _networkError,
        match: _activeMatch,
        currentUserId: ref.watch(networkSessionProvider)?.userId,
        nowUtc: ref.watch(gameClockProvider).nowUtc(),
      ),
      _MultiplayerLobbyMode.privateHost ||
      _MultiplayerLobbyMode.privateJoin => _PrivateMatchPanel(
        busy: _networkBusy,
        error: _networkError,
        match: _activeMatch,
        currentUserId: ref.watch(networkSessionProvider)?.userId,
        inviteCodeController: _inviteCodeController,
        joining:
            _multiplayerMode == _MultiplayerLobbyMode.privateJoin &&
            _activeMatch == null,
        onShare: ref.withMenuClickAsync(_shareInviteCode),
        onCopy: ref.withMenuClickAsync(_copyInviteCode),
        onBack: ref.withMenuClick(_returnToMultiplayerHome),
      ),
    };
    return panel;
  }

  bool get _showMultiplayerProfile =>
      _activeMatch == null &&
      (_multiplayerMode == _MultiplayerLobbyMode.home ||
          _multiplayerMode == _MultiplayerLobbyMode.privateJoin);

  Widget _buildMultiplayerProfilePanel() {
    return _MultiplayerProfilePanel(
      nicknameController: _players.nameControllerAt(0),
      countryControl: _playerCountryControl(
        0,
        key: const Key('multiplayer.countryDropdown'),
      ),
      onNicknameChanged: (_) => setState(() {}),
      signedIn: ref.watch(networkSessionProvider) != null,
      onSignOut: ref.withMenuClickAsync(_signOutMultiplayerAccount),
    );
  }

  Widget _playerKindControl(int index) {
    if (_canEditPlayerKinds) {
      return _PlayerKindToggle(
        value: _players.kindAt(index),
        onChanged: ref.withMenuClickValue(
          (kind) => _setPlayerKind(index, kind),
        ),
      );
    }
    return _PlayerKindBadge(value: _players.kindAt(index));
  }

  Widget _playerCountryControl(int index, {Key? key}) {
    return _PlayerCountryDropdown(
      key: key,
      value: _players.countryAt(index),
      options: _players.countryOptionsFor(index),
      onChanged: ref.withMenuClickValue(
        (country) => _setPlayerCountry(index, country),
      ),
    );
  }
}
