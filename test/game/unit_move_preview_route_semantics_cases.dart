part of 'unit_move_preview_layer_test.dart';

UnitMovementPlan _linearPlan({
  required int totalCost,
  required int availableMovementPoints,
}) {
  return _plan(
    targetCol: totalCost,
    totalCost: totalCost,
    availableMovementPoints: availableMovementPoints,
    steps: [
      const UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      for (var cost = 1; cost <= totalCost; cost++)
        UnitMovementStep(col: cost, row: 0, enterCost: 1, cumulativeCost: cost),
    ],
  );
}

void _registerGeneratedReachabilityPropertyTest() {
  test('property: rendered reachability matches every generated plan step', () {
    final random = math.Random(0xA0118);
    var roughFirstStepCases = 0;
    for (var scenario = 0; scenario < 160; scenario++) {
      if (_verifyGeneratedReachability(random, scenario)) {
        roughFirstStepCases += 1;
      }
    }
    expect(roughFirstStepCases, greaterThanOrEqualTo(20));
  });
}

bool _verifyGeneratedReachability(math.Random random, int scenario) {
  final forcedRoughFirstStep = scenario % 8 == 0;
  final cols = forcedRoughFirstStep ? 2 : 2 + random.nextInt(8);
  final startCol = forcedRoughFirstStep ? 0 : random.nextInt(cols);
  var targetCol = forcedRoughFirstStep ? 1 : random.nextInt(cols);
  if (targetCol == startCol) targetCol = (targetCol + 1) % cols;
  final movementPoints = forcedRoughFirstStep ? 1 : random.nextInt(7);
  final terrains = [
    for (var col = 0; col < cols; col++)
      forcedRoughFirstStep && col == targetCol
          ? const [TerrainType.snow, TerrainType.hills]
          : _generatedTerrainProfiles[random.nextInt(
              _generatedTerrainProfiles.length,
            )],
  ];
  final map = WorldMap(
    cols: cols,
    rows: 1,
    tiles: [
      for (var col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: terrains[col],
          resources: const [],
          height: 0,
        ),
    ],
  );
  final unit = GameUnit(
    id: 'generated_$scenario',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    name: 'Generated warrior',
    col: startCol,
    row: 0,
    movementPoints: movementPoints,
  );
  final plan = UnitMovementPlanner(
    mapData: map,
    units: [unit],
  ).planMove(unit: unit, targetTile: map.tileAt(targetCol, 0)!);
  expect(plan, isNotNull, reason: 'generated scenario $scenario');
  final resolvedPlan = plan!;
  final parent = Component();
  UnitMovePreviewLayer().sync(parent: parent, preview: resolvedPlan);
  final rendered = _singlePreviewIn(parent);
  expect(rendered.reachablePoints, hasLength(resolvedPlan.steps.length));
  for (var step = 0; step < resolvedPlan.steps.length; step++) {
    expect(
      rendered.reachablePoints[step],
      resolvedPlan.canReachStepThisTurn(resolvedPlan.steps[step]),
      reason: 'generated scenario $scenario, step $step',
    );
  }
  return resolvedPlan.steps[1].enterCost > movementPoints && movementPoints > 0;
}

const _generatedTerrainProfiles = <List<TerrainType>>[
  [TerrainType.grassland],
  [TerrainType.plains, TerrainType.forest],
  [TerrainType.desert],
  [TerrainType.tundra, TerrainType.hills],
  [TerrainType.snow],
  [TerrainType.grassland, TerrainType.jungle, TerrainType.hills],
];

void _registerRouteSemanticsTests() {
  test('rough first step stays reachable when it can consume the turn', () {
    final parent = Component();
    final plan = _plan(
      totalCost: 3,
      availableMovementPoints: 2,
      canSpendTurnEnteringFirstStep: true,
      steps: const [
        UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 1, row: 0, enterCost: 3, cumulativeCost: 3),
      ],
    );

    UnitMovePreviewLayer().sync(parent: parent, preview: plan);

    expect(plan.canMoveNow, isTrue);
    expect(_singlePreviewIn(parent).reachablePoints, [isTrue, isTrue]);
  });

  test('keeps travelled history while coloring the rebased suffix', () {
    final parent = Component();
    final fullPlan = _linearPlan(totalCost: 4, availableMovementPoints: 3);
    final remainingPlan = fullPlan.remainingFromStepIndex(1);

    UnitMovePreviewLayer().syncMany(
      parent: parent,
      previews: [
        UnitMovePreviewLayerEntry(
          id: 'queued',
          preview: remainingPlan,
          displaySteps: fullPlan.steps,
          travelledUpToIndex: 1,
        ),
      ],
    );

    final rendered = _singlePreviewIn(parent);
    expect(rendered.points, hasLength(5));
    expect(rendered.reachablePoints, everyElement(isTrue));
    expect(remainingPlan.estimatedTurns(3), 1);
  });

  test('cost label uses the unit movement cap supplied by the domain', () {
    final parent = Component();
    final layer = UnitMovePreviewLayer(turnCostLabelBuilder: _turnCountLabel)
      ..syncMany(
        parent: parent,
        previews: [
          UnitMovePreviewLayerEntry(
            id: 'artifact-carrier',
            preview: _linearPlan(totalCost: 5, availableMovementPoints: 2),
            unitType: GameUnitType.warrior,
            maxMovementPointsPerTurn:
                UnitMovementBalance.artifactCarrierMovementPointsPerTurn,
          ),
        ],
      );

    expect(
      layer.pillForTesting('artifact-carrier')?.labelForTesting,
      '3 turns',
    );
  });
}
