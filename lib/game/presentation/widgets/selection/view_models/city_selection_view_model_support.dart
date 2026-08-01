part of 'city_selection_view_model_factory.dart';

List<SelectionInfoItem> _objectives(
  GameCity city,
  WorldMap? mapData,
  List<GameUnit> units,
  AppLocalizations l10n,
) => CityObjectiveSelectionItemsFactory.descriptionItems(
  city: city,
  mapData: mapData,
  units: units,
  l10n: l10n,
);

WorldArtifact? _storedArtifactForCity(
  GameCity city,
  List<WorldArtifact> artifacts,
) {
  for (final artifact in artifacts) {
    final location = artifact.location;
    if (location.isStored && location.cityId == city.id) return artifact;
  }
  return null;
}
