import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TechnologyUnlockQuery', () {
    const ruleset = TechnologyRulesets.standard;

    ResearchState researchWith(Set<TechnologyId> unlocked) {
      return ResearchState(
        players: {
          'player_1': PlayerResearchState(unlockedTechnologyIds: unlocked),
        },
      );
    }

    test('treats base buildings as unlocked without research', () {
      expect(
        TechnologyUnlockQuery.hasBuildingUnlocked(
          playerId: 'player_1',
          buildingType: CityBuildingType.granary,
          research: ResearchState.empty,
          ruleset: ruleset,
        ),
        isTrue,
      );
    });

    test('locks technology buildings until their technology is discovered', () {
      expect(
        TechnologyUnlockQuery.hasBuildingUnlocked(
          playerId: 'player_1',
          buildingType: CityBuildingType.workshop,
          research: ResearchState.empty,
          ruleset: ruleset,
        ),
        isFalse,
      );
    });

    test('unlocks buildings from discovered technology unlocks', () {
      expect(
        TechnologyUnlockQuery.hasBuildingUnlocked(
          playerId: 'player_1',
          buildingType: CityBuildingType.workshop,
          research: researchWith({TechnologyId.craftsmanship}),
          ruleset: ruleset,
        ),
        isTrue,
      );
    });

    test('finds the technology that unlocks a building', () {
      final technology = TechnologyUnlockQuery.unlockingTechnologyForBuilding(
        buildingType: CityBuildingType.waterMill,
        ruleset: ruleset,
      );

      expect(technology?.id, TechnologyId.waterEngineering);
    });

    test('maps every city building to its required technology', () {
      const expectedTechnologyByBuilding = {
        CityBuildingType.granary: null,
        CityBuildingType.workshop: TechnologyId.craftsmanship,
        CityBuildingType.storehouse: TechnologyId.storage,
        CityBuildingType.waterMill: TechnologyId.waterEngineering,
        CityBuildingType.housing: TechnologyId.construction,
        CityBuildingType.merchantHall: TechnologyId.trade,
        CityBuildingType.stonemason: TechnologyId.stoneworking,
        CityBuildingType.barracks: TechnologyId.militaryOrganization,
        CityBuildingType.marketplace: TechnologyId.advancedTrade,
        CityBuildingType.port: TechnologyId.navigation,
        CityBuildingType.aqueduct: TechnologyId.irrigation,
        CityBuildingType.forge: TechnologyId.metallurgy,
        CityBuildingType.stable: TechnologyId.horsebackRiding,
        CityBuildingType.bank: TechnologyId.banking,
        CityBuildingType.buildersGuild: TechnologyId.engineering,
        CityBuildingType.factory: TechnologyId.machinery,
        CityBuildingType.lighthouse: TechnologyId.shipbuilding,
        CityBuildingType.trainingGrounds: TechnologyId.tactics,
        CityBuildingType.townHall: TechnologyId.administration,
        CityBuildingType.monument: TechnologyId.administration,
        CityBuildingType.archive: TechnologyId.writing,
        CityBuildingType.academy: TechnologyId.education,
        CityBuildingType.university: TechnologyId.education,
        CityBuildingType.observatory: TechnologyId.scientificMethod,
        CityBuildingType.laboratory: TechnologyId.scientificMethod,
        CityBuildingType.reactor: TechnologyId.nuclearPhysics,
        CityBuildingType.courthouse: TechnologyId.civilService,
        CityBuildingType.court: TechnologyId.law,
        CityBuildingType.governorsOffice: TechnologyId.bureaucracy,
        CityBuildingType.surveyorsOffice: TechnologyId.mathematics,
        CityBuildingType.planningOffice: TechnologyId.urbanPlanning,
        CityBuildingType.apothecary: TechnologyId.medicine,
        CityBuildingType.publicBaths: TechnologyId.medicine,
        CityBuildingType.hospital: TechnologyId.medicine,
        CityBuildingType.ministries: TechnologyId.bureaucracy,
        CityBuildingType.walls: TechnologyId.fortifications,
        CityBuildingType.armory: TechnologyId.militaryOrganization,
        CityBuildingType.siegeWorkshop: TechnologyId.siegecraft,
        CityBuildingType.citadel: TechnologyId.nationalism,
        CityBuildingType.warCollege: TechnologyId.strategy,
        CityBuildingType.conscriptionOffice: TechnologyId.nationalism,
        CityBuildingType.borderFort: TechnologyId.nationalism,
        CityBuildingType.airfield: TechnologyId.flight,
        CityBuildingType.artisansGuild: TechnologyId.guilds,
        CityBuildingType.masterWorkshop: TechnologyId.guilds,
        CityBuildingType.steelworks: TechnologyId.steel,
        CityBuildingType.railDepot: TechnologyId.steamPower,
        CityBuildingType.powerPlant: TechnologyId.electricity,
        CityBuildingType.assemblyPlant: TechnologyId.massProduction,
        CityBuildingType.refinery: TechnologyId.combustion,
        CityBuildingType.mapRoom: TechnologyId.cartography,
        CityBuildingType.shipyard: TechnologyId.navalDoctrine,
        CityBuildingType.dryDock: TechnologyId.navalDoctrine,
        CityBuildingType.navalAcademy: TechnologyId.navalDoctrine,
        CityBuildingType.harborCustoms: TechnologyId.navalDoctrine,
        CityBuildingType.museum: TechnologyId.bureaucracy,
        CityBuildingType.parliament: TechnologyId.bureaucracy,
        CityBuildingType.broadcastTower: TechnologyId.radio,
        CityBuildingType.worldFairGrounds: TechnologyId.massProduction,
      };

      for (final buildingType in CityBuildingType.values) {
        final technology = TechnologyUnlockQuery.unlockingTechnologyForBuilding(
          buildingType: buildingType,
          ruleset: ruleset,
        );

        expect(
          technology?.id,
          expectedTechnologyByBuilding[buildingType],
          reason: '${buildingType.name} should have the expected tech gate',
        );
      }
    });

    test('treats base units as unlocked without research', () {
      expect(
        TechnologyUnlockQuery.hasUnitUnlocked(
          playerId: 'player_1',
          unitType: GameUnitType.warrior,
          research: ResearchState.empty,
          ruleset: ruleset,
        ),
        isTrue,
      );
    });

    test('locks technology units until their technology is discovered', () {
      expect(
        TechnologyUnlockQuery.hasUnitUnlocked(
          playerId: 'player_1',
          unitType: GameUnitType.archer,
          research: ResearchState.empty,
          ruleset: ruleset,
        ),
        isFalse,
      );
    });

    test('locks general until strategy is discovered', () {
      expect(
        TechnologyUnlockQuery.hasUnitUnlocked(
          playerId: 'player_1',
          unitType: GameUnitType.commander,
          research: ResearchState.empty,
          ruleset: ruleset,
        ),
        isFalse,
      );
      expect(
        TechnologyUnlockQuery.hasUnitUnlocked(
          playerId: 'player_1',
          unitType: GameUnitType.commander,
          research: researchWith({TechnologyId.strategy}),
          ruleset: ruleset,
        ),
        isTrue,
      );
    });

    test('locks merchant until trade is discovered', () {
      expect(
        TechnologyUnlockQuery.hasUnitUnlocked(
          playerId: 'player_1',
          unitType: GameUnitType.merchant,
          research: ResearchState.empty,
          ruleset: ruleset,
        ),
        isFalse,
      );
      expect(
        TechnologyUnlockQuery.hasUnitUnlocked(
          playerId: 'player_1',
          unitType: GameUnitType.merchant,
          research: researchWith({TechnologyId.trade}),
          ruleset: ruleset,
        ),
        isTrue,
      );
    });

    test('unlocks units from discovered technology unlocks', () {
      expect(
        TechnologyUnlockQuery.hasUnitUnlocked(
          playerId: 'player_1',
          unitType: GameUnitType.archer,
          research: researchWith({TechnologyId.hunting}),
          ruleset: ruleset,
        ),
        isTrue,
      );
    });

    test('finds the technology that unlocks a unit', () {
      final technology = TechnologyUnlockQuery.unlockingTechnologyForUnit(
        unitType: GameUnitType.archer,
        ruleset: ruleset,
      );

      expect(technology?.id, TechnologyId.hunting);
    });

    test('finds the technology that unlocks a general', () {
      final technology = TechnologyUnlockQuery.unlockingTechnologyForUnit(
        unitType: GameUnitType.commander,
        ruleset: ruleset,
      );

      expect(technology?.id, TechnologyId.strategy);
    });

    test('finds the technology that unlocks a merchant', () {
      final technology = TechnologyUnlockQuery.unlockingTechnologyForUnit(
        unitType: GameUnitType.merchant,
        ruleset: ruleset,
      );

      expect(technology?.id, TechnologyId.trade);
    });

    test('locks field improvements until their technology is discovered', () {
      expect(
        TechnologyUnlockQuery.hasFieldImprovementUnlocked(
          playerId: 'player_1',
          improvementType: FieldImprovementType.mine,
          research: ResearchState.empty,
          ruleset: ruleset,
        ),
        isFalse,
      );
    });

    test('unlocks field improvements from discovered technology unlocks', () {
      expect(
        TechnologyUnlockQuery.hasFieldImprovementUnlocked(
          playerId: 'player_1',
          improvementType: FieldImprovementType.mine,
          research: researchWith({TechnologyId.mining}),
          ruleset: ruleset,
        ),
        isTrue,
      );
    });

    test('finds the technology that unlocks a field improvement', () {
      final technology =
          TechnologyUnlockQuery.unlockingTechnologyForFieldImprovement(
            improvementType: FieldImprovementType.quarry,
            ruleset: ruleset,
          );

      expect(technology?.id, TechnologyId.stoneworking);
    });
  });
}
