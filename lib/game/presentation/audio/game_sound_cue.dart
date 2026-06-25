enum GameSoundCue {
  uiPanelOpen('ui_panel_open'),
  uiPanelClose('ui_panel_close'),
  menuClick('menu_click'),
  menuBack('menu_back'),
  mapTileSelect('map_tile_select'),
  movePreview('move_preview'),
  moveConfirm('move_confirm'),
  attack('attack'),
  city('city'),
  newTurn('new_turn'),
  technology('technology'),
  walk('walk');

  const GameSoundCue(this.assetName);

  final String assetName;
}
