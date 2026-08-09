import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/use_cases/create_local_game_use_case.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_controller.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_multiplayer_access_gate.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_network_failure_text.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_network_session_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_player_setup_controller.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_screen_multiplayer_action_summary.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_screen_queue_countdown.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_session_effect_error_reporter.dart';
import 'package:aonw/game/presentation/screens/lobby/multiplayer_account_dialog.dart';
import 'package:aonw/game/presentation/screens/new_game/initial_player_country.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_player_capacity.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

part 'lobby_network_error_messages.dart';
part 'lobby_screen_action_bar.dart';
part 'lobby_screen_form_widgets.dart';
part 'lobby_screen_game_setup_widgets.dart';
part 'lobby_screen_layout_widgets.dart';
part 'lobby_screen_local_setup_panel.dart';
part 'lobby_screen_map_capacity.dart';
part 'lobby_screen_multiplayer_panel_builder.dart';
part 'lobby_screen_multiplayer_panels.dart';
part 'lobby_screen_multiplayer_profile_panel.dart';
part 'lobby_screen_multiplayer_status_widgets.dart';
part 'lobby_screen_player_list_widgets.dart';
part 'lobby_screen_player_row.dart';
part 'lobby_screen_player_setup_widgets.dart';
part 'lobby_screen_private_match_panel.dart';
part 'lobby_screen_public_lobby_panel.dart';
part 'lobby_screen_session_actions.dart';
part 'lobby_screen_state_actions.dart';
part 'lobby_screen_state_lifecycle.dart';
part 'lobby_screen_state_view.dart';

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
  late final LobbyConnectionController _connection;
  _GameLengthPreset _gameLengthPreset = _GameLengthPreset.unlimited;
  bool _starting = false;
  bool _localizedDefaultsApplied = false;
  late final String _multiplayerDefaultPlayerName;
  int? _scheduledMapMaximumPlayers;

  @override
  void initState() {
    super.initState();
    _initializeLobbyState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyLocalizedDefaults();
  }

  @override
  void dispose() {
    _disposeLobbyState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LobbyMultiplayerAccessGate(widget.flow, _buildLobbyScreen);
  }

  void _refreshState() => setState(() {});

  void _mutateState(VoidCallback mutation) => setState(mutation);
}
