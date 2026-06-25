enum MapViewMode {
  graphic,
  tile;

  bool get showsImage => this == MapViewMode.graphic;

  bool get usesOutlineHexes => this == MapViewMode.graphic;

  bool get showsExtrusion => this == MapViewMode.tile;

  bool get showsIcons => this == MapViewMode.tile;
}
