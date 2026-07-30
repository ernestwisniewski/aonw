/// Approved characterization of the canonical economy contract.
const richEconomyEventGolden = <Map<String, Object?>>[
  {'type': 'ResearchPointsGained', 'playerId': 'p1', 'points': 3},
  {
    'type': 'TechnologyResearched',
    'playerId': 'p1',
    'technologyId': 'agriculture',
  },
  {'type': 'CityFounded', 'cityId': 'city_p1_5_3', 'ownerPlayerId': 'p1'},
  {
    'type': 'ArtifactCarried',
    'artifactId': 'artifact_excavated',
    'ownerPlayerId': 'p1',
    'unitId': 'scout_p1',
    'col': 2,
    'row': 2,
  },
  {
    'type': 'CityProducedUnit',
    'cityId': 'city_p2',
    'unitType': 'warrior',
    'producedUnitId': 'city_p2_warrior_1',
  },
  {'type': 'ResearchPointsGained', 'playerId': 'p2', 'points': 3},
  {'type': 'WorkerCompletedJob', 'unitId': 'worker_p2'},
  {
    'type': 'MapObjectiveSecured',
    'playerId': 'p1',
    'objectiveId': 'pass_1',
    'objectiveType': 'strategicPass',
    'col': 1,
    'row': 0,
    'holdTurns': 2,
    'requiredHoldTurns': 2,
    'victoryPoints': 3,
    'goldPerTurn': 4,
  },
  {
    'type': 'StabilityBandChanged',
    'playerId': 'base_only',
    'previousBand': 'strained',
    'newBand': 'stable',
    'net': 3,
  },
  {
    'type': 'StabilityBandChanged',
    'playerId': 'p1',
    'previousBand': 'unrest',
    'newBand': 'stable',
    'net': 2,
  },
  {
    'type': 'StabilityBandChanged',
    'playerId': 'p2',
    'previousBand': 'stable',
    'newBand': 'content',
    'net': 9,
  },
];

const richEconomyScienceGolden = <String, Object>{
  'total': 2,
  'byCityId': <String, int>{'city_p1': 1, 'city_p2': 1},
  'sources': <Map<String, Object>>[
    {'cityId': 'city_p1', 'amount': 1, 'label': 'City research project'},
    {'cityId': 'city_p2', 'amount': 1, 'label': 'World artifact'},
  ],
};
