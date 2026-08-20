part of 'unit_move_preview_layer_test.dart';

const _confirmationEtaSteps = [
  UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
  UnitMovementStep(col: 1, row: 0, enterCost: 3, cumulativeCost: 3),
  UnitMovementStep(col: 2, row: 0, enterCost: 3, cumulativeCost: 6),
  UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 8),
];

UnitMovementPlan _confirmationEtaPlan() =>
    _plan(targetCol: 3, totalCost: 8, steps: _confirmationEtaSteps);

UnitMovementPlan _linearPlan({
  required int totalCost,
  required int availableMovementUnits,
}) {
  return _plan(
    targetCol: totalCost,
    totalCost: totalCost,
    availableMovementUnits: availableMovementUnits,
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
  final plan = UnitMovementPlanner(mapData: map, units: [unit]).planMove(
    unit: unit,
    targetTile: map.tileAt(targetCol, 0)!,
    canEnterStepBeyondCapacity: (_) => true,
  );
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
      availableMovementUnits: 2,
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
    final fullPlan = _linearPlan(totalCost: 4, availableMovementUnits: 3);
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

  test('exhausted queued route marks every future step unreachable', () {
    final parent = Component();
    final fullPlan = _linearPlan(totalCost: 3, availableMovementUnits: 0);
    final remainingPlan = fullPlan.remainingFromStepIndex(1);

    UnitMovePreviewLayer().syncMany(
      parent: parent,
      previews: [
        UnitMovePreviewLayerEntry(
          id: 'exhausted-queued',
          preview: remainingPlan,
          displaySteps: fullPlan.steps,
          travelledUpToIndex: 1,
        ),
      ],
    );

    expect(remainingPlan.canMoveNow, isFalse);
    expect(_singlePreviewIn(parent).reachablePoints, [
      isTrue,
      isTrue,
      isFalse,
      isFalse,
    ]);
  });

  test('later-turn destination marker stays white', () async {
    const width = 128;
    const height = 64;
    const targetX = 96;
    const targetY = 32;
    final preview = UnitMovePreview(
      points: [
        Vector2(24, targetY.toDouble()),
        Vector2(targetX.toDouble(), targetY.toDouble()),
      ],
      reachablePoints: const [true, false],
    );
    expect(preview.destinationMarkerHasBorderForTesting, isFalse);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    preview.render(canvas);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    final bytes = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    image.dispose();
    const pixelOffset = ((targetY * width) + targetX) * 4;

    expect(bytes, isNotNull);
    expect(
      bytes!.getUint8(pixelOffset),
      closeTo((preview.routeColor.toARGB32() >> 16) & 0xFF, 3),
    );
    expect(
      bytes.getUint8(pixelOffset + 1),
      closeTo((preview.routeColor.toARGB32() >> 8) & 0xFF, 3),
    );
    expect(
      bytes.getUint8(pixelOffset + 2),
      closeTo(preview.routeColor.toARGB32() & 0xFF, 3),
    );
  });

  test('this-turn destination uses the large bordered route marker', () {
    final preview = UnitMovePreview(
      points: [Vector2(24, 32), Vector2(96, 32)],
      reachablePoints: const [true, true],
    );

    expect(preview.destinationMarkerHasBorderForTesting, isTrue);
  });

  test('cost label uses the unit movement cap supplied by the domain', () {
    final parent = Component();
    final layer = UnitMovePreviewLayer(turnCostLabelBuilder: _turnCountLabel)
      ..syncMany(
        parent: parent,
        previews: [
          UnitMovePreviewLayerEntry(
            id: 'artifact-carrier',
            preview: _linearPlan(totalCost: 5, availableMovementUnits: 2),
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

UnitMovementPlan _plan({
  int targetCol = 1,
  int targetRow = 0,
  int totalCost = 1,
  int availableMovementUnits = 5,
  List<UnitMovementStep>? steps,
}) => UnitMovementPlan(
  unitId: 'commander_player_1',
  targetCol: targetCol,
  targetRow: targetRow,
  totalCost: totalCost,
  availableMovementUnits: availableMovementUnits,
  steps:
      steps ??
      [
        const UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(
          col: targetCol,
          row: targetRow,
          enterCost: totalCost,
          cumulativeCost: totalCost,
        ),
      ],
);

String _turnCountLabel(int turns) => AppLocalizationsEn().turnCountLabel(turns);

List<UnitMovePreview> _previewsIn(Component parent) {
  return parent.children.query<UnitMovePreview>().toList(growable: false);
}

UnitMovePreview _singlePreviewIn(Component parent) =>
    _previewsIn(parent).single;

List<MapPillComponent> _pillsIn(Component parent) {
  return parent.children.query<MapPillComponent>().toList(growable: false);
}

MapPillComponent _singlePillIn(Component parent) => _pillsIn(parent).single;
