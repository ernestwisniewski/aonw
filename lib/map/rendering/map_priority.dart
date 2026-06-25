abstract final class MapPriority {
  static const int terrain = 0;
  static const int territory = 100;
  static const int eraTint = 200;
  static const int fog = 300;
  static const int sprite = 1000;
  static const int contextOverlay = 4000;
  static const int intentOverlay = 5000;
  static const int particles = 6000;
  static const int floatingText = 8000;
  static const int hudPin = 9000;

  static const int rowStride = 1000;

  static const int mapObjective = 15;
  static const int fieldImprovement = 16;
  static const int artifact = 17;
  static const int city = 18;
  static const int unit = 20;

  static const int cityManagementOverlay = contextOverlay + 10;
  static const int combatIntentOverlay = intentOverlay + 40;
  static const int hoverIntentOverlay = intentOverlay + 90;
  static const int selectionOverlay = intentOverlay + 750;
  static const int productionParticles = particles + 500;

  static const int movePreviewRoute = hudPin + rowStride * 100;
  static const int movePreviewPill = hudPin + rowStride * 1000;
  static const int actionPalette = movePreviewPill + 100;

  static int perTile(int base, {required int col, required int row}) {
    return base + row * rowStride + col;
  }

  static int perTileUnit({
    required int mapRows,
    required int col,
    required int row,
  }) {
    return mapRows * rowStride + perTile(unit, col: col, row: row);
  }
}
