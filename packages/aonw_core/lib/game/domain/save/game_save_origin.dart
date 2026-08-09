enum GameSaveOrigin { local, network, legacy }

GameSaveOrigin gameSaveOriginFromJson(Object? value) {
  if (value is String) {
    for (final origin in GameSaveOrigin.values) {
      if (origin.name == value) return origin;
    }
  }
  return GameSaveOrigin.legacy;
}

String gameSaveOriginToJson(GameSaveOrigin origin) => origin.name;
