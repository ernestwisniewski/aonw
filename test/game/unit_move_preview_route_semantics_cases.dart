part of 'unit_move_preview_layer_test.dart';

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
