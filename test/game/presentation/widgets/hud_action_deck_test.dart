import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/end_turn_button.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/action_deck/hud_action_deck.dart';
import 'package:aonw/game/presentation/widgets/hud/combat/hud_combat_preview.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_context_line.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/turn_action_hint.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/selection_info.dart';
import 'package:aonw/game/presentation/widgets/theme/city_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  testWidgets('HudActionDeck keeps the bottom command rail to one CTA', (
    tester,
  ) async {
    final animating = ValueNotifier(<String>{});

    await _pumpDeck(
      tester,
      animatingUnitIdsListenable: animating,
      useBottomGlobalActions: true,
      activityLogAvailable: true,
    );

    expect(find.byKey(const Key('hudActionDeck.surface')), findsOneWidget);
    expect(
      find.byKey(const Key('hudActionDeck.line.commands')),
      findsOneWidget,
    );
    expect(find.text('Next step: Warrior'), findsNothing);
    expect(find.text('ACTION'), findsOneWidget);
    expect(find.byKey(const Key('globalHud.action.research')), findsNothing);
    expect(
      find.byKey(const Key('globalHud.deckAction.activityLog')),
      findsNothing,
    );
    final commandLineRect = tester.getRect(
      find.byKey(const Key('hudActionDeck.line.commands')),
    );
    final endTurnRect = tester.getRect(find.byType(EndTurnButton));
    expect(
      (endTurnRect.center.dx - commandLineRect.center.dx).abs(),
      lessThanOrEqualTo(1),
    );
  });

  testWidgets('HudActionDeck disables action mode while a unit is animating', (
    tester,
  ) async {
    final animating = ValueNotifier(<String>{});

    await _pumpDeck(tester, animatingUnitIdsListenable: animating);

    expect(find.text('ACTION'), findsOneWidget);
    final commandLineRect = tester.getRect(
      find.byKey(const Key('hudActionDeck.line.commands')),
    );
    final endTurnRect = tester.getRect(find.byType(EndTurnButton));
    expect(
      (endTurnRect.center.dx - commandLineRect.center.dx).abs(),
      lessThanOrEqualTo(1),
    );

    animating.value = {'unit_1'};
    await tester.pump();

    expect(find.text('Next step: Warrior'), findsNothing);
    expect(find.text('WAITING'), findsOneWidget);
  });

  testWidgets('HudActionDeck pulses action border after an action disappears', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      remainingActionCount: 3,
      turnActionOptions: _turnActions,
    );

    expect(
      find.byKey(const Key('endTurnButton.animatedActionBorder')),
      findsNothing,
    );

    await _pumpDeck(
      tester,
      remainingActionCount: 2,
      turnActionOptions: _turnActions.take(2).toList(growable: false),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('endTurnButton.animatedActionBorder')),
      findsOneWidget,
    );

    await tester.tap(find.text('ACTION'));
    await tester.pump();

    expect(
      find.byKey(const Key('endTurnButton.animatedActionBorder')),
      findsNothing,
    );
  });

  testWidgets('HudActionDeck omits activity log from the bottom action rail', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      useBottomGlobalActions: true,
      activityLogAvailable: true,
    );

    expect(
      find.byKey(const Key('globalHud.deckAction.activityLog')),
      findsNothing,
    );
  });

  testWidgets('HudActionDeck caps surface width on wide layouts', (
    tester,
  ) async {
    await _pumpDeck(tester, screenSize: const Size(1200, 900));

    expect(
      tester.getSize(find.byKey(const Key('hudActionDeck.surface'))).width,
      HudActionDeck.wideMaxWidth,
    );
  });

  testWidgets('HudActionDeck uses compact surface while a panel is open', (
    tester,
  ) async {
    await _pumpDeck(tester, screenSize: const Size(1200, 900), panelOpen: true);

    expect(
      tester.getSize(find.byKey(const Key('hudActionDeck.surface'))).width,
      HudActionDeck.panelOpenMaxWidth,
    );
  });

  testWidgets('HudActionDeck omits the empty action line', (tester) async {
    await _pumpDeck(
      tester,
      selection: const SelectionViewModel(
        icon: GameIcons.terrain,
        color: Colors.white,
        title: 'Plain',
        subtitle: 'Map tile',
        items: [],
        selectionKey: 'tile:0,0',
      ),
    );

    expect(find.byKey(const Key('hudActionDeck.line.context')), findsOneWidget);
    expect(find.byKey(const Key('hudActionDeck.line.actions')), findsNothing);
    expect(
      find.byKey(const Key('hudActionDeck.line.commands')),
      findsOneWidget,
    );
  });

  testWidgets('places action controls above the selection infobar', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      selection: const SelectionViewModel(
        icon: GameIcons.production,
        color: Colors.white,
        title: 'Worker',
        subtitle: 'Move 2/3',
        assetIcon: SelectionAssetIconViewModel.unit(GameUnitType.worker),
        items: [],
        selectionKey: 'unit:worker_1',
      ),
      selectionActions: [
        SelectionCommandChip(icon: GameIcons.move, label: 'Move', onTap: () {}),
      ],
    );

    final actionLine = tester.getRect(
      find.byKey(const Key('hudActionDeck.line.actions')),
    );
    final commandLine = tester.getRect(
      find.byKey(const Key('hudActionDeck.line.commands')),
    );
    final contextLine = tester.getRect(
      find.byKey(const Key('hudActionDeck.line.context')),
    );
    final selectionSurface = tester.getRect(
      find.byKey(const Key('hudActionDeck.selectionSurface')),
    );
    final surfaceDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const Key('hudActionDeck.selectionSurface')),
                )
                .decoration
            as BoxDecoration;
    final surfaceBorder = surfaceDecoration.border! as Border;
    final titleRect = tester.getRect(find.text('Worker'));
    final subtitleRect = tester.getRect(find.text('Move 2/3'));

    expect(actionLine.bottom, lessThanOrEqualTo(selectionSurface.top));
    expect(selectionSurface.bottom, lessThanOrEqualTo(commandLine.top));
    expect(selectionSurface.inflate(0.5).contains(contextLine.topLeft), isTrue);
    expect(
      selectionSurface.inflate(0.5).contains(contextLine.bottomRight),
      isTrue,
    );
    expect(contextLine.height, HudSelectionContextMetrics.lineHeight);
    expect(selectionSurface.width, lessThan(commandLine.width * 0.6));
    expect(surfaceDecoration.color, GameUiTheme.surface.withAlpha(210));
    expect(
      surfaceBorder.top.color,
      GameUiTheme.gold.withAlpha(BorderEmphasis.regular.alpha),
    );
    expect(titleRect.bottom, lessThanOrEqualTo(subtitleRect.top));
    expect(
      find.byKey(const Key('hudActionDeck.selectionAssetIcon.unit')),
      findsOneWidget,
    );
    final unitSprite = tester.widget<UnitSpriteIcon>(
      find.byType(UnitSpriteIcon),
    );
    expect(unitSprite.size, closeTo(contextLine.height, 0.01));
    expect(find.textContaining('Worker'), findsOneWidget);
    expect(find.textContaining('Move 2/3'), findsOneWidget);
  });

  testWidgets('uses compact landscape deck with action beside selection', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      screenSize: const Size(720, 390),
      selection: const SelectionViewModel(
        icon: GameIcons.production,
        color: Colors.white,
        title: 'Worker',
        subtitle: 'Move 2/3',
        assetIcon: SelectionAssetIconViewModel.unit(GameUnitType.worker),
        items: [],
        selectionKey: 'unit:worker_1',
      ),
      selectionActions: [
        SelectionCommandChip(icon: GameIcons.move, label: 'Move', onTap: () {}),
      ],
    );

    expect(
      find.byKey(const Key('hudActionDeck.compactSurface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudActionDeck.compactCollapse')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudActionDeck.selectionSurface')),
      findsNothing,
    );
    expect(find.byKey(const Key('hudActionDeck.line.actions')), findsOneWidget);
    expect(find.byKey(const Key('hudActionDeck.line.context')), findsOneWidget);
    expect(
      find.byKey(const Key('hudActionDeck.line.commands')),
      findsOneWidget,
    );

    final contextLine = tester.getRect(
      find.byKey(const Key('hudActionDeck.line.context')),
    );
    final commandLine = tester.getRect(
      find.byKey(const Key('hudActionDeck.line.commands')),
    );
    final compactSurface = tester.getRect(
      find.byKey(const Key('hudActionDeck.compactSurface')),
    );

    expect(commandLine.left, greaterThan(contextLine.left));
    expect(
      (commandLine.center.dy - contextLine.center.dy).abs(),
      lessThanOrEqualTo(1),
    );
    expect(compactSurface.contains(commandLine.center), isTrue);
  });

  testWidgets('collapses compact landscape deck to a small command strip', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      screenSize: const Size(720, 390),
      selection: const SelectionViewModel(
        icon: GameIcons.production,
        color: Colors.white,
        title: 'Worker',
        subtitle: 'Move 2/3',
        assetIcon: SelectionAssetIconViewModel.unit(GameUnitType.worker),
        items: [],
        selectionKey: 'unit:worker_1',
      ),
      selectionActions: [
        SelectionCommandChip(icon: GameIcons.move, label: 'Move', onTap: () {}),
      ],
    );

    final expandedHeight = tester
        .getRect(find.byKey(const Key('hudActionDeck.surface')))
        .height;

    await tester.tap(find.byKey(const Key('hudActionDeck.compactCollapse')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('hudActionDeck.compactCollapsed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudActionDeck.compactExpand')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('hudActionDeck.compactSurface')), findsNothing);
    expect(find.byKey(const Key('hudActionDeck.line.actions')), findsNothing);
    expect(find.byKey(const Key('hudActionDeck.line.context')), findsNothing);
    expect(
      find.byKey(const Key('hudActionDeck.line.commands')),
      findsOneWidget,
    );

    final collapsedHeight = tester
        .getRect(find.byKey(const Key('hudActionDeck.surface')))
        .height;
    expect(collapsedHeight, lessThan(expandedHeight));

    await tester.tap(find.byKey(const Key('hudActionDeck.compactExpand')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('hudActionDeck.compactSurface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudActionDeck.compactCollapsed')),
      findsNothing,
    );
    expect(find.byKey(const Key('hudActionDeck.line.context')), findsOneWidget);
  });

  testWidgets('selection context grows for the largest text setting', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      textScaleFactor: 1.3,
      selection: const SelectionViewModel(
        icon: GameIcons.production,
        color: Colors.white,
        title: 'Worker',
        subtitle: 'Move 2/3',
        assetIcon: SelectionAssetIconViewModel.unit(GameUnitType.worker),
        items: [],
        selectionKey: 'unit:worker_1',
      ),
      selectionActions: [
        SelectionCommandChip(icon: GameIcons.move, label: 'Move', onTap: () {}),
      ],
    );

    expect(tester.takeException(), isNull);

    final contextLine = tester.getRect(
      find.byKey(const Key('hudActionDeck.line.context')),
    );
    final selectionSurface = tester.getRect(
      find.byKey(const Key('hudActionDeck.selectionSurface')),
    );

    expect(
      contextLine.height,
      greaterThan(HudSelectionContextMetrics.lineHeight),
    );
    final unitSprite = tester.widget<UnitSpriteIcon>(
      find.byType(UnitSpriteIcon),
    );
    expect(unitSprite.size, closeTo(contextLine.height, 0.01));
    expect(
      selectionSurface.inflate(0.5).contains(contextLine.bottomRight),
      isTrue,
    );
  });

  testWidgets('omits city detail chips from the bottom context line', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      selection: const SelectionViewModel(
        icon: GameIcons.cityFilled,
        color: Colors.white,
        title: 'Capital',
        subtitle: 'City',
        assetIcon: SelectionAssetIconViewModel.city(
          cityVisualLevel: 2,
          cityTechnologyProfileIndex: 3,
        ),
        items: [
          SelectionInfoItem(
            icon: GameIcons.city,
            label: 'Buildings',
            value: '39',
            color: Colors.white,
          ),
        ],
        selectionKey: 'city:city_1',
      ),
    );

    final contextLine = tester.getRect(
      find.byKey(const Key('hudActionDeck.line.context')),
    );

    expect(contextLine.width, greaterThan(0));
    final citySprite = tester.widget<CitySpriteIcon>(
      find.byKey(const Key('hudActionDeck.selectionAssetIcon.city')),
    );
    expect(citySprite.visualLevel, 2);
    expect(citySprite.technologyProfileIndex, 3);
    expect(
      find.byKey(const Key('hudActionDeck.context.description')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('hudActionDeck.context.buildings')),
      findsNothing,
    );
    expect(find.text('Description'), findsNothing);
    expect(find.text('Buildings 39'), findsNothing);
  });

  testWidgets(
    'HudActionDeck hides selection actions with side selection info',
    (tester) async {
      await _pumpDeck(
        tester,
        selection: const SelectionViewModel(
          icon: GameIcons.warrior,
          color: Colors.white,
          title: 'Warrior',
          subtitle: 'Unit',
          items: [],
        ),
        selectionActions: [
          SelectionCommandChip(
            icon: GameIcons.move,
            label: 'Move',
            onTap: () {},
          ),
        ],
        showSelectionInfo: false,
      );

      expect(find.byKey(const Key('hudActionDeck.line.context')), findsNothing);
      expect(find.byKey(const Key('hudActionDeck.line.actions')), findsNothing);
      expect(find.text('Move'), findsNothing);
      expect(
        find.byKey(const Key('hudActionDeck.line.commands')),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders selection context as text and opens modal details', (
    tester,
  ) async {
    var openChipId = null as String?;

    Future<void> pump() async {
      await _pumpDeck(
        tester,
        selection: const SelectionViewModel(
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
          ],
          selectionKey: 'tile:0,0',
        ),
        openSelectionDetailChipId: openChipId,
        onToggleSelectionDetail: (chipId) {
          openChipId = openChipId == chipId ? null : chipId;
        },
        onCloseSelectionDetail: () {
          openChipId = null;
        },
      );
    }

    await pump();

    expect(find.byType(SelectionActionBar), findsNothing);
    expect(find.byType(SelectionActionChip), findsNothing);
    expect(find.byKey(const Key('hudActionDeck.line.context')), findsOneWidget);
    expect(
      find.byKey(const Key('hudActionDeck.context.terrain')),
      findsOneWidget,
    );
    final titleRect = tester.getRect(find.text('Plain'));
    final chipRect = tester.getRect(
      find.byKey(const Key('hudActionDeck.context.terrain')),
    );
    expect(
      chipRect.left - titleRect.right,
      greaterThanOrEqualTo(HudSelectionContextMetrics.chipsGap),
    );

    await tester.tap(find.byKey(const Key('hudActionDeck.context.terrain')));
    await pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SelectionDetailSheet), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.detail.terrain')),
      findsOneWidget,
    );
  });

  testWidgets('renders selection details as a peek while inspecting map', (
    tester,
  ) async {
    Future<void> pump({required bool peek}) async {
      await _pumpDeck(
        tester,
        selection: const SelectionViewModel(
          icon: GameIcons.terrain,
          color: Colors.white,
          title: 'Plain',
          subtitle: 'Map tile',
          items: [
            SelectionInfoItem(
              icon: GameIcons.info,
              label: 'Description',
              value: 'Field',
              color: Colors.white,
            ),
          ],
          selectionKey: 'tile:0,0',
        ),
        openSelectionDetailChipId: SelectionInfoChipId.description,
        selectionDetailPeek: peek,
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    await pump(peek: true);

    var sheet = tester.widget<SelectionDetailSheet>(
      find.byType(SelectionDetailSheet),
    );
    expect(sheet.peek, isTrue);

    await pump(peek: false);
    await tester.pump();

    sheet = tester.widget<SelectionDetailSheet>(
      find.byType(SelectionDetailSheet),
    );
    expect(sheet.peek, isFalse);
  });

  testWidgets('closes selection detail modal when open chip clears', (
    tester,
  ) async {
    String? openChipId = SelectionInfoChipId.terrain;

    Future<void> pump() async {
      await _pumpDeck(
        tester,
        selection: const SelectionViewModel(
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
          ],
          selectionKey: 'tile:0,0',
        ),
        openSelectionDetailChipId: openChipId,
        onCloseSelectionDetail: () {
          openChipId = null;
        },
      );
    }

    await pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SelectionDetailSheet), findsOneWidget);

    openChipId = null;
    await pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SelectionDetailSheet), findsNothing);
  });

  testWidgets('opens context token info sheet on long press', (tester) async {
    var openChipId = null as String?;

    await _pumpDeck(
      tester,
      selection: const SelectionViewModel(
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
        ],
        selectionKey: 'tile:0,0',
      ),
      onToggleSelectionDetail: (chipId) {
        openChipId = chipId;
      },
    );

    await tester.longPress(
      find.byKey(const Key('hudActionDeck.context.terrain')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Terrain'), findsWidgets);
    expect(find.textContaining('Opens “Terrain” details'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(openChipId, SelectionInfoChipId.terrain);
  });

  testWidgets('worker action mode opens build selection sheet', (tester) async {
    await _pumpDeck(
      tester,
      gameState: const GameState(
        interaction: GameInteractionState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
          ),
        ),
      ),
      selection: SelectionViewModel(
        icon: GameIcons.improvement,
        color: Colors.white,
        title: 'Worker',
        subtitle: 'Building ulepszenia',
        items: const [],
        workerAction: _workerAction(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SelectionDetailSheet), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.detail.workerBuildGuide')),
      findsOneWidget,
    );
    expect(find.text('Tile improvement'), findsOneWidget);
    expect(find.text('Choose improvement'), findsAtLeastNWidgets(1));
    expect(find.text('Farm'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.workerBuild.option.farm')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('selectionInfo.workerBuild.confirm')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('selectionInfo.workerBuild.cancel')),
      findsOneWidget,
    );
  });

  testWidgets('selected attack target opens combat confirmation popup', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      gameState: const GameState(
        interaction: GameInteractionState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'attacker_1',
            defenderCol: 1,
            defenderRow: 0,
          ),
        ),
      ),
      combatPreview: const HudCombatPreview(
        attackerUnitId: 'attacker_1',
        defenderUnitId: 'defender_1',
        attackerUnitType: GameUnitType.warrior,
        defenderUnitType: GameUnitType.spearman,
        attackerName: 'Warrior',
        defenderName: 'Spearman',
        targetIsCity: false,
        attackerModifiers: [
          CounterModifier(
            label: 'counter.spearmanVsMounted.attack',
            target: CombatStatTarget.attack,
            delta: 2,
          ),
        ],
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
        attackDamage: 4,
        retaliationDamage: 2,
        attackerKilled: false,
        defenderKilled: false,
        defenderRetreated: false,
        distance: 1,
        range: 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('hudCombatConfirm.surface')), findsOneWidget);
    expect(find.text('Confirm attack'), findsAtLeastNWidgets(1));
    expect(find.text('Poland: Warrior → Poland: Spearman'), findsOneWidget);
    expect(find.text('Why this forecast?'), findsOneWidget);
    expect(
      find.text(
        'Attack advantage: Poland has 6 attack against 2 defense; the target loses about 4 HP.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Helps the attack (Poland): spearmen against mounted units.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('hudCombatConfirm.forecast')), findsOneWidget);
    expect(
      find.byKey(const Key('hudCombatConfirm.attackerRing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudCombatConfirm.defenderRing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudCombatConfirm.attackerHpAfter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudCombatConfirm.defenderHpAfter')),
      findsOneWidget,
    );
    expect(find.text('8/10'), findsOneWidget);
    expect(find.text('6/10'), findsOneWidget);
    expect(find.byKey(const Key('hudCombatConfirm.cancel')), findsOneWidget);
    expect(find.byKey(const Key('hudCombatConfirm.confirm')), findsOneWidget);
  });

  testWidgets('combat confirmation popup adapts to compact and wide sizes', (
    tester,
  ) async {
    for (final scenario in const [
      (size: Size(320, 480), textScale: 1.15),
      (size: Size(1024, 720), textScale: 1.0),
    ]) {
      await _pumpDeck(
        tester,
        screenSize: scenario.size,
        textScaleFactor: scenario.textScale,
        gameState: const GameState(
          interaction: GameInteractionState(
            pendingAction: PendingAttackTargeting(
              ownerPlayerId: 'player_1',
              attackerUnitId: 'attacker_1',
              defenderCol: 1,
              defenderRow: 0,
            ),
          ),
        ),
        combatPreview: const HudCombatPreview(
          attackerUnitId: 'attacker_1',
          defenderUnitId: 'defender_1',
          attackerName: 'Warrior',
          defenderName: 'Hill defender warrior',
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
          attackDamage: 4,
          retaliationDamage: 2,
          attackerKilled: false,
          defenderKilled: false,
          defenderRetreated: false,
          distance: 1,
          range: 1,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('hudCombatConfirm.surface')), findsOneWidget);
      expect(
        find.byKey(const Key('hudCombatConfirm.forecast')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('hudCombatConfirm.cancel')), findsOneWidget);
      expect(find.byKey(const Key('hudCombatConfirm.confirm')), findsOneWidget);

      final rect = tester.getRect(
        find.byKey(const Key('hudCombatConfirm.surface')),
      );
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(scenario.size.width));
      expect(rect.bottom, lessThanOrEqualTo(scenario.size.height));
    }
  });

  testWidgets('city founding mode keeps bottom action cancellation visible', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      selection: const SelectionViewModel(
        icon: GameIcons.settler,
        color: Colors.white,
        title: 'Settler',
        subtitle: 'Founds new cities',
        items: [],
      ),
      selectionActions: [
        SelectionCommandChip(
          icon: GameIcons.close,
          actionId: 'cancel',
          label: 'Cancel',
          showLabel: true,
          onTap: () {},
        ),
      ],
      openSelectionDetailChipId: SelectionInfoChipId.description,
      cityFoundingDraft: CityFoundingDraft(
        unitId: 'settler_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 0, row: 0),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SelectionDetailSheet), findsNothing);
    expect(
      find.byKey(const Key('selectionInfo.detail.description')),
      findsNothing,
    );
    expect(find.byKey(const Key('hudActionDeck.line.actions')), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.action.cancel')),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byKey(const Key('hudActionDeck.line.context')), findsNothing);
    expect(find.text('Founding a city'), findsNothing);
    expect(find.text('Select 2 city tiles'), findsNothing);
    expect(find.text('Confirm city founding'), findsNothing);
    expect(find.text('0/2'), findsNothing);
  });

  testWidgets('city founding confirm action stays in the bottom action line', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      selection: const SelectionViewModel(
        icon: GameIcons.settler,
        color: Colors.white,
        title: 'Settler',
        subtitle: 'Founds new cities',
        items: [],
      ),
      selectionActions: [
        SelectionCommandChip(
          icon: GameIcons.flag,
          actionId: 'foundCity',
          label: 'Found city',
          showLabel: true,
          onTap: () {},
        ),
        SelectionCommandChip(
          icon: GameIcons.close,
          actionId: 'cancel',
          label: 'Cancel',
          showLabel: true,
          onTap: () {},
        ),
      ],
      cityFoundingDraft: CityFoundingDraft(
        unitId: 'settler_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 0, row: 0),
        controlledHexes: const [
          CityHex(col: 1, row: 0),
          CityHex(col: 0, row: 1),
        ],
      ),
    );

    expect(
      find.byKey(const Key('hudActionDeck.cityFoundingConfirm')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('selectionInfo.action.foundCity')),
      findsOneWidget,
    );
    expect(find.text('Found city'), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.action.cancel')),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byKey(const Key('hudActionDeck.line.actions')), findsOneWidget);
  });

  testWidgets(
    'city expansion confirm action appears above the bottom toolbar',
    (tester) async {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
        preferredExpansionHex: CityHex(col: 1, row: 0),
      );

      await _pumpDeck(
        tester,
        gameState: const GameState(
          cities: [city],
          interaction: GameInteractionState(
            pendingAction: PendingCityExpansionSelection(
              ownerPlayerId: 'player_1',
              cityId: 'city_1',
            ),
          ),
        ),
      );

      final confirmFinder = find.byKey(
        const Key('hudActionDeck.cityExpansionConfirm'),
      );
      final cancelFinder = find.byKey(
        const Key('hudActionDeck.cityExpansionCancel'),
      );
      final commandLineFinder = find.byKey(
        const Key('hudActionDeck.line.commands'),
      );

      expect(confirmFinder, findsOneWidget);
      expect(cancelFinder, findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(
        tester.getRect(confirmFinder).bottom,
        lessThan(tester.getRect(commandLineFinder).top),
      );
      expect(
        tester.getRect(cancelFinder).bottom,
        lessThan(tester.getRect(commandLineFinder).top),
      );
    },
  );

  testWidgets('city expansion confirm waits for a chosen preferred hex', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 0, row: 0),
    );

    await _pumpDeck(
      tester,
      gameState: const GameState(
        cities: [city],
        interaction: GameInteractionState(
          pendingAction: PendingCityExpansionSelection(
            ownerPlayerId: 'player_1',
            cityId: 'city_1',
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('hudActionDeck.cityExpansionConfirm')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('hudActionDeck.cityExpansionCancel')),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
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

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
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
      ),
    ),
  );
}

WorkerActionPanelViewModel _workerAction({
  FieldImprovementType? selectedImprovementType,
}) {
  return WorkerActionPanelViewModel(
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
}
