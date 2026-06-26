import 'package:aonw/app/not_found_screen.dart';
import 'package:aonw/developer/assets_editor_screen.dart';
import 'package:aonw/editor/editor_map_picker_screen.dart';
import 'package:aonw/editor/map_editor_screen.dart';
import 'package:aonw/game/presentation/screens.dart';
import 'package:aonw/game/presentation/screens/new_game/initial_player_country.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/menu/credits_screen.dart';
import 'package:aonw/menu/main_menu_screen.dart';
import 'package:aonw/menu/manual_screen.dart';
import 'package:aonw/menu/options_screen.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  return GoRouter(
    errorBuilder: (context, state) =>
        NotFoundScreen(path: state.uri.toString()),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
      GoRoute(
        path: '/options',
        builder: (context, state) => const OptionsScreen(),
      ),
      GoRoute(
        path: '/manual',
        builder: (context, state) => const ManualScreen(),
      ),
      GoRoute(
        path: '/new-game',
        builder: (context, state) => NewGameScreen(
          flow: NewGameFlowX.fromQuery(state.uri.queryParameters['mode']),
          startAtMap: state.uri.queryParameters['direct'] == 'true',
        ),
      ),
      GoRoute(
        path: '/lobby',
        builder: (context, state) {
          final source = MapSelection.sourceFromQuery(
            state.uri.queryParameters['source'],
          );
          final name =
              state.uri.queryParameters['name'] ?? MapSelection.defaultMapName;
          final flow = NewGameFlowX.fromQuery(
            state.uri.queryParameters['mode'],
          );
          final country = _playerCountryFromQuery(
            state.uri.queryParameters['country'],
          );
          return LobbyScreen(
            mapName: name,
            mapSource: source,
            flow: flow,
            playerCountry: country,
          );
        },
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final source = MapSelection.sourceFromQuery(
            state.uri.queryParameters['source'],
          );
          final name =
              state.uri.queryParameters['name'] ?? MapSelection.defaultMapName;
          final saveId = state.uri.queryParameters['saveId'] ?? '';
          return GameScreen(
            selection: MapSelection(name: name, source: source),
            saveId: saveId,
          );
        },
      ),
      GoRoute(
        path: '/replay',
        builder: (context, state) {
          final saveId = state.uri.queryParameters['saveId'] ?? '';
          return ReplayScreen(saveId: saveId);
        },
      ),
      GoRoute(
        path: '/load-game',
        builder: (context, state) => const LoadGameScreen(),
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) => const EditorMapPickerScreen(),
      ),
      GoRoute(
        path: '/developer/assets',
        builder: (context, state) => const AssetsEditorScreen(),
      ),
      GoRoute(
        path: '/editor/map',
        builder: (context, state) {
          final name = state.uri.queryParameters['name'];
          if (name == null) {
            return const MapEditorScreen();
          }

          final source = MapSelection.sourceFromQuery(
            state.uri.queryParameters['source'],
          );
          return MapEditorScreen(
            selection: MapSelection(name: name, source: source),
          );
        },
      ),
      GoRoute(
        path: '/credits',
        builder: (context, state) => const CreditsScreen(),
      ),
    ],
  );
}

PlayerCountry _playerCountryFromQuery(String? value) {
  return playerCountryFromName(value) ?? randomInitialPlayerCountry();
}
