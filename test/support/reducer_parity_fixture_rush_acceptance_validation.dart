part of 'reducer_parity_fixture.dart';

typedef _RushAcceptanceValidator =
    bool Function(
      ReducerParityFixture fixture,
      GameCity city,
      CityProductionQueue queue,
      bool complete,
    );

final _rushAcceptanceValidators =
    <_RushAcceptanceMode, _RushAcceptanceValidator>{
      _RushAcceptanceMode.partial: _isReviewedPartialRush,
      _RushAcceptanceMode.buildingCompletion: _isReviewedBuildingCompletionRush,
      _RushAcceptanceMode.unitCompletion: _isReviewedUnitCompletionRush,
      _RushAcceptanceMode.blockedUnitCompletion:
          _isReviewedBlockedUnitCompletionRush,
      _RushAcceptanceMode.wonderCompletion: _isReviewedWonderCompletionRush,
      _RushAcceptanceMode.completedWonderRefund:
          _isReviewedCompletedWonderRefundRush,
    };

bool _isReviewedPartialRush(
  ReducerParityFixture fixture,
  GameCity city,
  CityProductionQueue queue,
  bool complete,
) =>
    queue.target ==
        const BuildingProductionTarget(CityBuildingType.marketplace) &&
    !complete &&
    city.specialization == CitySpecializationType.industry &&
    city.buildings.contains(CityBuildingType.workshop) &&
    city.wonders.contains(WonderType.motherFactory) &&
    fixture.state.wonderRegistry.ownerOf(WonderType.motherFactory) ==
        city.ownerPlayerId &&
    StabilityPolicy.bandFor(
          fixture.state.playerStabilityNet[city.ownerPlayerId] ?? 0,
        ) ==
        StabilityBand.unrest;

bool _isReviewedBuildingCompletionRush(
  ReducerParityFixture fixture,
  GameCity city,
  CityProductionQueue queue,
  bool complete,
) => queue.target is BuildingProductionTarget && complete;

bool _isReviewedUnitCompletionRush(
  ReducerParityFixture fixture,
  GameCity city,
  CityProductionQueue queue,
  bool complete,
) =>
    queue.target is UnitProductionTarget &&
    complete &&
    _hasReviewedRushUnitArtifact(fixture, city) &&
    _reviewedRushProducedUnit(fixture, city, queue) != null;

bool _hasReviewedRushUnitArtifact(ReducerParityFixture fixture, GameCity city) {
  final storedArtifacts = WorldArtifactBonuses.storedInCity(
    cityId: city.id,
    artifacts: fixture.state.artifacts,
  ).toList();
  return storedArtifacts.length == 1 &&
      storedArtifacts.single.type == WorldArtifactType.heroSword &&
      WorldArtifactBonuses.producedUnitExperienceFor(
            cityId: city.id,
            artifacts: fixture.state.artifacts,
          ) ==
          2;
}

bool _isReviewedBlockedUnitCompletionRush(
  ReducerParityFixture fixture,
  GameCity city,
  CityProductionQueue queue,
  bool complete,
) =>
    queue.target is UnitProductionTarget &&
    complete &&
    _reviewedRushProducedUnit(fixture, city, queue) == null;

bool _isReviewedWonderCompletionRush(
  ReducerParityFixture fixture,
  GameCity city,
  CityProductionQueue queue,
  bool complete,
) =>
    queue.target == const WonderProductionTarget(WonderType.greatLibrary) &&
    complete &&
    !fixture.state.wonderRegistry.isCompleted(WonderType.greatLibrary) &&
    _hasReviewedGreatLibraryTechnology(fixture, city) &&
    _hasReviewedGreatLibraryCompetitor(fixture, city, queue);

bool _isReviewedCompletedWonderRefundRush(
  ReducerParityFixture fixture,
  GameCity city,
  CityProductionQueue queue,
  bool complete,
) =>
    queue.target == const WonderProductionTarget(WonderType.greatLibrary) &&
    complete &&
    fixture.state.wonderRegistry.isCompleted(WonderType.greatLibrary);
