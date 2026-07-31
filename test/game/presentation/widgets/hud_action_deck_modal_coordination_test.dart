part of 'hud_action_deck_test.dart';

const _player = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
  players: const [_player],
);

const _turnActions = [
  HudTurnActionOption(index: 0, label: 'Warrior 1', kindLabel: 'Unit'),
  HudTurnActionOption(index: 1, label: 'Capital production', kindLabel: 'City'),
  HudTurnActionOption(
    index: 2,
    label: 'Choose research',
    kindLabel: 'Research',
  ),
];

const _detailTestSelection = SelectionViewModel(
  icon: GameIcons.terrain,
  color: Colors.white,
  title: 'Plain',
  subtitle: 'Map tile',
  items: [
    SelectionInfoItem(
      icon: GameIcons.terrain,
      label: 'Terrain',
      value: 'Plain',
      color: Colors.white,
    ),
    SelectionInfoItem(
      icon: GameIcons.info,
      label: 'Description',
      value: 'Field',
      color: Colors.white,
    ),
  ],
  selectionKey: 'tile:0,0',
);

GameState _attackState(String attackerUnitId) => GameState(
  interaction: GameInteractionState(
    pendingAction: PendingAttackTargeting(
      ownerPlayerId: 'player_1',
      attackerUnitId: attackerUnitId,
      defenderCol: 1,
      defenderRow: 0,
    ),
  ),
);

HudCombatPreview _combatPreview({
  required String attackerUnitId,
  required String defenderUnitId,
  required String attackerName,
  required String defenderName,
}) => HudCombatPreview(
  attackerUnitId: attackerUnitId,
  defenderUnitId: defenderUnitId,
  attackerName: attackerName,
  defenderName: defenderName,
  targetIsCity: false,
  attackerHpBefore: 10,
  defenderHpBefore: 10,
  attackerMaxHp: 10,
  defenderMaxHp: 10,
  attackerHpAfter: 8,
  defenderHpAfter: 6,
  attackerAttack: 6,
  attackerDefense: 3,
  defenderAttack: 4,
  defenderDefense: 2,
  defenderRange: 1,
  attackDamage: 4,
  retaliationDamage: 2,
  attackerKilled: false,
  defenderKilled: false,
  defenderRetreated: false,
  distance: 1,
  range: 1,
);

void _registerDetailModalCoordinationTests() {
  testWidgets('detail modal blocks auto-flow until it is fully closed', (
    tester,
  ) async {
    final commands = <GameCommand>[];
    final container = ProviderContainer(
      overrides: [
        hudCommandDispatcherProvider.overrideWith(
          (ref) => _RecordingHudCommandDispatcher(ref, commands),
        ),
      ],
    );
    addTearDown(container.dispose);
    String? openChipId = SelectionInfoChipId.terrain;

    Future<void> pump() => _pumpDeck(
      tester,
      gameState: const GameState(),
      remainingActionCount: 1,
      selection: _detailTestSelection,
      openSelectionDetailChipId: openChipId,
      providerContainer: container,
    );

    await pump();
    expect(commands, isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SelectionDetailSheet), findsOneWidget);
    expect(commands, isEmpty);

    openChipId = null;
    await pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(commands, isEmpty);

    await tester.pumpAndSettle();
    expect(commands.whereType<FocusNextPendingActionCommand>(), hasLength(1));
  });

  testWidgets('detail modal reopens the latest request after closing', (
    tester,
  ) async {
    String? openChipId = SelectionInfoChipId.terrain;

    Future<void> pump() => _pumpDeck(
      tester,
      selection: _detailTestSelection,
      openSelectionDetailChipId: openChipId,
    );

    await pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const Key('selectionInfo.detail.terrain')),
      findsOneWidget,
    );

    tester
        .widget<IconButton>(find.byKey(const Key('selectionInfo.detail.close')))
        .onPressed!();
    openChipId = SelectionInfoChipId.description;
    await pump();
    await tester.pumpAndSettle();

    expect(find.byType(SelectionDetailSheet), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.detail.description')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selectionInfo.detail.terrain')), findsNothing);
  });
}

Future<void> _pumpDeck(
  WidgetTester tester, {
  ValueNotifier<Set<String>>? animatingUnitIdsListenable,
  GameState gameState = const GameState(),
  bool readyToEndTurn = false,
  int remainingActionCount = 0,
  int currentActionIndex = 0,
  List<HudTurnActionOption> turnActionOptions = const [],
  bool useBottomGlobalActions = false,
  List<Widget> mainGlobalActions = const [],
  bool activityLogAvailable = false,
  SelectionViewModel? selection,
  String? openSelectionDetailChipId,
  List<Widget> selectionActions = const [],
  CityFoundingDraft? cityFoundingDraft,
  HudCombatPreview? combatPreview,
  bool showSelectionInfo = true,
  bool selectionDetailPeek = false,
  bool panelOpen = false,
  Size? screenSize,
  double? textScaleFactor,
  ValueChanged<String>? onToggleSelectionDetail,
  VoidCallback? onCloseSelectionDetail,
  ProviderContainer? providerContainer,
}) async {
  if (screenSize != null) {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget deck = Align(
    alignment: Alignment.bottomCenter,
    child: HudActionDeck(
      animatingUnitIdsListenable:
          animatingUnitIdsListenable ?? ValueNotifier(<String>{}),
      gameSave: _save,
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      gameState: gameState,
      readyToEndTurn: readyToEndTurn,
      remainingActionCount: remainingActionCount,
      currentActionIndex: currentActionIndex,
      turnActionOptions: turnActionOptions,
      actionHintLabel: 'Next step: Warrior',
      nextActionObjectiveAdvice: null,
      selection: selection,
      openSelectionDetailChipId: openSelectionDetailChipId,
      selectionActions: selectionActions,
      cityFoundingDraft: cityFoundingDraft,
      combatPreview: combatPreview,
      cityRuleset: CityRulesets.standard,
      technologyRuleset: TechnologyRulesets.standard,
      useBottomGlobalActions: useBottomGlobalActions,
      mainGlobalActions: mainGlobalActions,
      activityLogAvailable: activityLogAvailable,
      activityLogModeActive: false,
      showSelectionInfo: showSelectionInfo,
      selectionDetailPeek: selectionDetailPeek,
      panelOpen: panelOpen,
      cityProductionPanelOpen: panelOpen,
      onToggleSelectionDetail: onToggleSelectionDetail ?? (_) {},
      onCloseSelectionDetail: onCloseSelectionDetail ?? () {},
    ),
  );

  final app = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        if (textScaleFactor != null) {
          deck = MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: deck,
          );
        }
        return Scaffold(body: deck);
      },
    ),
  );

  await tester.pumpWidget(
    providerContainer == null
        ? ProviderScope(child: app)
        : UncontrolledProviderScope(container: providerContainer, child: app),
  );
}

WorkerActionPanelViewModel _workerAction({
  FieldImprovementType? selectedImprovementType,
}) => WorkerActionPanelViewModel(
  unitId: 'worker_1',
  unitName: 'Worker',
  currentHex: const CityHex(col: 0, row: 0),
  movementPoints: 2,
  selectionActive: true,
  selectedImprovementType: selectedImprovementType,
  activeJob: null,
  options: [
    WorkerImprovementOptionViewModel(
      improvementType: FieldImprovementType.farm,
      title: 'Farm',
      yield: const TileYield(food: 1, production: 0, gold: 0, defense: 0),
      buildTurns: 2,
      state: selectedImprovementType == FieldImprovementType.farm
          ? WorkerImprovementOptionState.selected
          : WorkerImprovementOptionState.recommended,
      reason: '+1 food',
      canSelect: true,
      score: 10,
    ),
    const WorkerImprovementOptionViewModel(
      improvementType: FieldImprovementType.mine,
      title: 'Mine',
      yield: TileYield(food: 0, production: 2, gold: 0, defense: 0),
      buildTurns: 3,
      state: WorkerImprovementOptionState.available,
      reason: '+2 prod.',
      canSelect: true,
      score: 8,
    ),
  ],
);

final class _RecordingHudCommandDispatcher extends HudCommandDispatcher {
  _RecordingHudCommandDispatcher(super.ref, this.commands);

  final List<GameCommand> commands;

  @override
  Future<void> dispatch(GameCommand command) async => commands.add(command);
}
