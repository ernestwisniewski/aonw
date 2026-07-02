import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/notifications/game_event_notification_card.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats stability band changes for the owning player', () {
    final message = GameEventNotificationMessage.from(
      AppLocalizationsEn(),
      const GameEventNotification(
        id: 1,
        event: StabilityBandChangedEvent(
          playerId: 'player_1',
          previousBand: StabilityBand.stable,
          newBand: StabilityBand.strained,
          net: -2,
        ),
        state: GameState(activePlayerId: 'player_1'),
        playerId: 'player_1',
      ),
      null,
    );

    expect(message.title, 'Empire stability changed');
    expect(message.body, contains('Strained (-2)'));
    expect(
      message.thumbnail,
      const TypeMatcher<IconEventNotificationThumbnail>(),
    );
  });

  testWidgets('dismiss animation uses shared HUD motion tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameEventNotificationCard(
            message: GameEventNotificationMessage(
              title: 'Technology discovered',
              body: 'Agriculture',
            ),
            dismissing: true,
            fadeDuration: GameMotion.scene,
          ),
        ),
      ),
    );

    final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );

    expect(slide.duration, GameMotion.scene);
    expect(slide.curve, GameMotion.exit);
    expect(slide.offset, const Offset(0, -0.08));
    expect(opacity.duration, GameMotion.scene);
    expect(opacity.curve, GameMotion.exit);
    expect(opacity.opacity, 0);
  });

  testWidgets('renders thumbnails for technology, building and unit toasts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              GameEventNotificationCard(
                message: GameEventNotificationMessage(
                  title: 'Technology discovered',
                  body: 'Agriculture',
                  thumbnail: const TechnologyEventNotificationThumbnail(
                    TechnologyId.agriculture,
                  ),
                ),
                dismissing: false,
                fadeDuration: Duration.zero,
              ),
              GameEventNotificationCard(
                message: GameEventNotificationMessage(
                  title: 'Construction complete',
                  body: 'Roma: Granary',
                  thumbnail: const BuildingEventNotificationThumbnail(
                    CityBuildingType.granary,
                  ),
                ),
                dismissing: false,
                fadeDuration: Duration.zero,
              ),
              GameEventNotificationCard(
                message: GameEventNotificationMessage(
                  title: 'Unit trained',
                  body: 'Roma: Worker',
                  thumbnail: const UnitEventNotificationThumbnail(
                    GameUnitType.worker,
                  ),
                ),
                dismissing: false,
                fadeDuration: Duration.zero,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TechnologySpriteIcon), findsOneWidget);
    expect(find.byType(BuildingSpriteIcon), findsOneWidget);
    expect(find.byType(UnitSpriteIcon), findsOneWidget);
  });

  testWidgets('notification formatter assigns concrete toast thumbnails', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: 'Worker',
      col: 1,
      row: 1,
    );
    final state = GameState(
      activePlayerId: 'player_1',
      cities: const [city],
      units: [worker],
    );
    final save = GameSave(
      id: 'save',
      name: 'Game',
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      turn: 1,
      playerStates: const {'player_1': PlayerTurnState.active},
      savedAt: DateTime.utc(2026, 5, 3),
      camera: CameraState.zero,
      players: const [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final tech = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 1,
                event: const TechnologyResearchedEvent(
                  playerId: 'player_1',
                  technologyId: TechnologyId.agriculture,
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );
            final building = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 2,
                event: const CityBuiltBuildingEvent(
                  cityId: 'city_1',
                  buildingType: CityBuildingType.granary,
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );
            final unit = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 3,
                event: const CityProducedUnitEvent(
                  cityId: 'city_1',
                  unitType: GameUnitType.worker,
                  producedUnitId: 'worker_2',
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );
            final workerJob = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 4,
                event: const WorkerCompletedJobEvent(unitId: 'worker_1'),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );
            final unitMove = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 5,
                event: const UnitMovedEvent(
                  unitId: 'worker_1',
                  fromCol: 1,
                  fromRow: 1,
                  toCol: 2,
                  toRow: 1,
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );
            final experience = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 6,
                event: const UnitGainedExperienceEvent(
                  unitId: 'worker_1',
                  ownerPlayerId: 'player_1',
                  amount: 2,
                  totalExperience: 7,
                  rank: UnitVeterancyRank.veteran,
                  promoted: true,
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );
            final unitAttack = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 7,
                event: const UnitAttackedEvent(
                  attackerUnitId: 'worker_1',
                  attackerOwnerPlayerId: 'player_1',
                  defenderUnitId: 'missing',
                  defenderOwnerPlayerId: 'player_2',
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );
            final science = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 8,
                event: const ResearchPointsGainedEvent(
                  playerId: 'player_1',
                  points: 4,
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );
            final resource = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 9,
                event: const StrategicResourceDiscoveredEvent(
                  playerId: 'player_1',
                  resourceType: ResourceType.oil,
                  controlledCount: 1,
                  rivalControlledCount: 2,
                  unclaimedCount: 1,
                  pressure: StrategicResourceDiscoveryPressure.expansionRace,
                  nearestUnclaimedCol: 4,
                  nearestUnclaimedRow: 0,
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );
            final mapObjective = GameEventNotificationMessage.from(
              l10n,
              GameEventNotification(
                id: 10,
                event: const MapObjectiveSecuredEvent(
                  playerId: 'player_1',
                  objectiveId: 'pass_1',
                  objectiveType: MapObjectiveType.strategicPass,
                  col: 2,
                  row: 1,
                  holdTurns: 3,
                  requiredHoldTurns: 3,
                  victoryPoints: 2,
                  goldPerTurn: 1,
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );

            expect(tech.thumbnail, isA<TechnologyEventNotificationThumbnail>());
            expect(
              building.thumbnail,
              isA<BuildingEventNotificationThumbnail>(),
            );
            expect(unit.thumbnail, isA<UnitEventNotificationThumbnail>());
            expect(workerJob.thumbnail, isA<UnitEventNotificationThumbnail>());
            expect(unitMove.thumbnail, isA<UnitEventNotificationThumbnail>());
            expect(experience.body, 'Worker: +2 XP (Veteran)');
            expect(unitAttack.thumbnail, isA<UnitEventNotificationThumbnail>());
            expect(
              science.thumbnail,
              isA<IconEventNotificationThumbnail>().having(
                (thumbnail) => thumbnail.kind,
                'kind',
                EventNotificationIconThumbnailKind.science,
              ),
            );
            expect(resource.title, 'Strategic resource discovered');
            expect(resource.body, 'Alice: oil');
            expect(resource.details, [
              'Controlled: 1',
              'Rivals: 2',
              'Unclaimed: 1',
              'Settlement race: claim the nearest deposit before rivals.',
              'Deposit outside borders at 4:0; consider founding a city.',
            ]);
            expect(
              resource.thumbnail,
              isA<IconEventNotificationThumbnail>().having(
                (thumbnail) => thumbnail.kind,
                'kind',
                EventNotificationIconThumbnailKind.science,
              ),
            );
            expect(mapObjective.title, 'Map objective secured');
            expect(mapObjective.body, 'Alice: Strategic pass');
            expect(mapObjective.details, [
              'Held: 3/3',
              'Position: 2:1',
              '+2 victory points',
              '+1 gold/turn',
            ]);
            expect(
              mapObjective.thumbnail,
              isA<IconEventNotificationThumbnail>().having(
                (thumbnail) => thumbnail.kind,
                'kind',
                EventNotificationIconThumbnailKind.success,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('combat formatter summarizes damage and retaliation', (
    tester,
  ) async {
    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 1,
    );
    final defender = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 2,
      row: 1,
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [attacker.copyWithHitPoints(8), defender.copyWithHitPoints(4)],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final message = GameEventNotificationMessage.from(
              AppLocalizations.of(context),
              GameEventNotification(
                id: 1,
                event: CombatResolvedEvent(
                  attackerUnitId: 'warrior_1',
                  defenderUnitId: 'enemy_1',
                  outcome: CombatOutcome(
                    attackerUnitId: 'warrior_1',
                    defenderUnitId: 'enemy_1',
                    attackerHpAfter: 8,
                    defenderHpAfter: 4,
                    attackerKilled: false,
                    defenderKilled: false,
                    steps: [AttackStep(damage: 3), RetaliationStep(damage: 2)],
                  ),
                ),
                state: state,
                playerId: 'player_1',
              ),
              null,
            );

            expect(message.title, 'Combat');
            expect(
              message.body,
              'Warrior (player_1) attacked Warrior Enemy (player_2) - HP 8:4',
            );
            expect(message.details, [
              'Warrior Enemy: -3 HP -> 4 HP',
              'Warrior: -2 HP -> 8 HP',
              'Attack: -3 HP',
              'Retaliation: -2 HP',
            ]);
            expect(message.thumbnail, isA<UnitEventNotificationThumbnail>());
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('diplomacy formatter labels proposal outcomes explicitly', (
    tester,
  ) async {
    final save = GameSave(
      id: 'save',
      name: 'Game',
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      turn: 1,
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      savedAt: DateTime.utc(2026, 5, 3),
      camera: CameraState.zero,
      players: const [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
        Player(id: 'player_2', name: 'Bob', colorValue: 0xFFC45050),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final rejected = GameEventNotificationMessage.from(
              l10n,
              const GameEventNotification(
                id: 1,
                event: DiplomaticProposalRespondedEvent(
                  proposalId: 'proposal_1',
                  fromPlayerId: 'player_1',
                  toPlayerId: 'player_2',
                  kind: DiplomaticProposalKind.truce,
                  accepted: false,
                ),
                state: GameState(activePlayerId: 'player_2'),
                playerId: 'player_1',
                turn: 4,
              ),
              save,
            );
            final expired = GameEventNotificationMessage.from(
              l10n,
              const GameEventNotification(
                id: 2,
                event: DiplomaticProposalExpiredEvent(
                  proposalId: 'proposal_2',
                  fromPlayerId: 'player_1',
                  toPlayerId: 'player_2',
                  kind: DiplomaticProposalKind.truce,
                ),
                state: GameState(activePlayerId: 'player_2'),
                playerId: 'player_2',
                turn: 5,
              ),
              save,
            );

            expect(rejected.title, 'Proposals: Truce proposal');
            expect(rejected.body, contains('Declined'));
            expect(rejected.body, contains('T4'));
            expect(expired.title, 'Proposals: Truce proposal');
            expect(expired.body, contains('Expired'));
            expect(expired.body, contains('T5'));
            expect(rejected.body, isNot(contains('Blocked')));
            expect(expired.body, isNot(contains('Blocked')));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('diplomacy formatter shares leader history wording', (
    tester,
  ) async {
    final save = GameSave(
      id: 'save',
      name: 'Game',
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      turn: 6,
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      savedAt: DateTime.utc(2026, 5, 3),
      camera: CameraState.zero,
      players: const [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
        Player(id: 'player_2', name: 'Bob', colorValue: 0xFFC45050),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final dispatch = GameEventNotificationMessage.from(
              l10n,
              const GameEventNotification(
                id: 1,
                event: DiplomaticMessageSentEvent(
                  messageId: 'message_1',
                  fromPlayerId: 'player_1',
                  toPlayerId: 'player_2',
                  topic: DiplomaticMessageTopic.commonEnemy,
                  category: DiplomaticMessageCategory.cooperation,
                  expiresOnTurn: 8,
                ),
                state: GameState(activePlayerId: 'player_1'),
                playerId: 'player_1',
                turn: 4,
              ),
              save,
            );
            final score = GameEventNotificationMessage.from(
              l10n,
              const GameEventNotification(
                id: 2,
                event: DiplomaticScoreChangedEvent(
                  playerAId: 'player_1',
                  playerBId: 'player_2',
                  delta: 12,
                  scoreAfter: 24,
                  reason: DiplomaticScoreChangeReason.messageResponse,
                ),
                state: GameState(activePlayerId: 'player_1'),
                playerId: 'player_1',
                turn: 5,
              ),
              save,
            );

            expect(
              dispatch.title,
              'Dispatches: A common enemy threatens us both.',
            );
            expect(dispatch.body, 'Alice -> Bob · T4 -> T8');
            expect(score.title, 'Dispatch response');
            expect(score.body, 'Alice / Bob · Relations: 24 · T5');
            expect(score.details, ['+12']);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('combat formatter localizes modifier labels', (tester) async {
    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 1,
    );
    final defender = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 2,
      row: 1,
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [attacker.copyWithHitPoints(10), defender.copyWithHitPoints(9)],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final message = GameEventNotificationMessage.from(
              AppLocalizations.of(context),
              GameEventNotification(
                id: 1,
                event: CombatResolvedEvent(
                  attackerUnitId: 'warrior_1',
                  defenderUnitId: 'enemy_1',
                  outcome: CombatOutcome(
                    attackerUnitId: 'warrior_1',
                    defenderUnitId: 'enemy_1',
                    attackerHpAfter: 10,
                    defenderHpAfter: 9,
                    attackerKilled: false,
                    defenderKilled: false,
                    steps: [
                      const ModifierAppliedStep(
                        TerrainModifier(
                          label: 'terrain.forest.defense',
                          target: CombatStatTarget.defense,
                          delta: 1,
                        ),
                      ),
                      const ModifierAppliedStep(
                        TechnologyModifier(
                          label: 'tech.strategy.armyAttack',
                          target: CombatStatTarget.attack,
                          delta: 2,
                        ),
                      ),
                      const ModifierAppliedStep(
                        VeterancyModifier(
                          label: 'veterancy.elite.attack',
                          target: CombatStatTarget.attack,
                          delta: 1,
                        ),
                      ),
                      const ModifierAppliedStep(
                        CounterModifier(
                          label: 'counter.spearmanVsMounted.attack',
                          target: CombatStatTarget.attack,
                          delta: 2,
                        ),
                      ),
                      AttackStep(damage: 1),
                    ],
                  ),
                ),
                state: state,
                playerId: 'player_1',
              ),
              null,
            );

            expect(message.details, contains('Terrain forest defense +1'));
            expect(message.details, contains('Technology Strategy attack +2'));
            expect(message.details, contains('Rank Elite attack +1'));
            expect(
              message.details,
              contains('spearmen against mounted units attack +2'),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('domination threshold formatter marks opponent pressure', (
    tester,
  ) async {
    const state = GameState(activePlayerId: 'player_1');
    final save = GameSave(
      id: 'save',
      name: 'Game',
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      turn: 12,
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      savedAt: DateTime.utc(2026, 5, 3),
      camera: CameraState.zero,
      players: const [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
        Player(id: 'player_2', name: 'Bob', colorValue: 0xFFC45050),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final message = GameEventNotificationMessage.from(
              AppLocalizations.of(context),
              const GameEventNotification(
                id: 1,
                event: DominationThresholdReachedEvent(
                  playerId: 'player_2',
                  controlPercent: 55,
                  requiredControlPercent: 45,
                  holdTurns: 1,
                  requiredHoldTurns: 4,
                ),
                state: state,
                playerId: 'player_1',
              ),
              save,
            );

            expect(message.title, 'Rival above threshold');
            expect(message.body, 'Bob: 55% / 45%');
            expect(message.details, [
              'Held 1/4 turns',
              'Interrupt within 3 turns',
            ]);
            expect(
              message.thumbnail,
              isA<IconEventNotificationThumbnail>().having(
                (thumbnail) => thumbnail.kind,
                'kind',
                EventNotificationIconThumbnailKind.warning,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('combat formatter names defeated units from previous state', (
    tester,
  ) async {
    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 1,
    );
    final defender = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 2,
      row: 1,
    );
    final previousState = GameState(
      activePlayerId: 'player_1',
      units: [attacker, defender],
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [attacker.copyWithHitPoints(9)],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final combat = GameEventNotificationMessage.from(
              AppLocalizations.of(context),
              GameEventNotification(
                id: 1,
                event: CombatResolvedEvent(
                  attackerUnitId: 'warrior_1',
                  defenderUnitId: 'enemy_1',
                  outcome: CombatOutcome(
                    attackerUnitId: 'warrior_1',
                    defenderUnitId: 'enemy_1',
                    attackerHpAfter: 9,
                    defenderHpAfter: 0,
                    attackerKilled: false,
                    defenderKilled: true,
                    steps: [AttackStep(damage: 5)],
                  ),
                ),
                state: state,
                previousState: previousState,
                playerId: 'player_1',
              ),
              null,
            );
            final killed = GameEventNotificationMessage.from(
              AppLocalizations.of(context),
              GameEventNotification(
                id: 2,
                event: const UnitKilledEvent(
                  unitId: 'enemy_1',
                  ownerPlayerId: 'player_2',
                  attackerUnitId: 'warrior_1',
                ),
                state: state,
                previousState: previousState,
                playerId: 'player_2',
              ),
              null,
            );

            expect(
              combat.body,
              'Warrior (player_1) attacked Warrior Enemy (player_2) - HP 9:0',
            );
            expect(combat.details, [
              'Warrior Enemy: -5 HP -> defeated',
              'Warrior: no retaliation',
              'Attack: -5 HP',
              'Defender defeated',
            ]);
            expect(killed.body, 'Enemy');
            expect(killed.thumbnail, isA<UnitEventNotificationThumbnail>());
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
