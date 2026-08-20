import 'package:aonw/game/presentation/audio/game_sound_cue.dart';

/// Explicit runtime audio manifest. Multiple semantic cues may share one file.
abstract final class AudioAssetCatalog {
  static const Map<GameSoundCue, String> effects = {
    GameSoundCue.uiPanelOpen: 'assets/sounds/ui_panel_open.wav',
    GameSoundCue.uiPanelClose: 'assets/sounds/menu_back.wav',
    GameSoundCue.menuClick: 'assets/sounds/menu_click.wav',
    GameSoundCue.menuBack: 'assets/sounds/menu_back.wav',
    GameSoundCue.mapTileSelect: 'assets/sounds/map_tile_select.wav',
    GameSoundCue.movePreview: 'assets/sounds/map_tile_select.wav',
    GameSoundCue.moveConfirm: 'assets/sounds/move_confirm.wav',
    GameSoundCue.attack: 'assets/sounds/attack.wav',
    GameSoundCue.city: 'assets/sounds/city.wav',
    GameSoundCue.newTurn: 'assets/sounds/new_turn.wav',
    GameSoundCue.technology: 'assets/sounds/technology.wav',
    GameSoundCue.walk: 'assets/sounds/walk.wav',
  };

  static const List<String> music = [
    'assets/sounds/music/korona1.mp3',
    'assets/sounds/music/korona2.mp3',
    'assets/sounds/music/kroniki1.mp3',
    'assets/sounds/music/kroniki2.mp3',
    'assets/sounds/music/oddech1.mp3',
    'assets/sounds/music/oddech2.mp3',
    'assets/sounds/music/szepty1.mp3',
    'assets/sounds/music/szepty2.mp3',
  ];

  static const List<String> nature = [
    'assets/sounds/nature/656124__itsthegoodstuff__nature-ambiance.mp3',
  ];

  static String effectFor(GameSoundCue cue) => effects[cue]!;

  static String assetSourcePath(String assetPath) {
    const prefix = 'assets/';
    return assetPath.startsWith(prefix)
        ? assetPath.substring(prefix.length)
        : assetPath;
  }
}
