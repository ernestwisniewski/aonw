import 'package:aonw/game/domain/city.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class GameDisplayNames {
  static final RegExp _defaultCityNamePattern = RegExp(r'^city_(\d+)$');
  static final RegExp _defaultPlayerNamePattern = RegExp(r'^player_(\d+)$');

  static String city(AppLocalizations l10n, GameCity city) {
    final match = _defaultCityNamePattern.firstMatch(city.name);
    if (match == null) return city.name;
    return l10n.defaultCityName(int.parse(match.group(1)!));
  }

  static String player(AppLocalizations l10n, Player player) {
    final match = _defaultPlayerNamePattern.firstMatch(player.name);
    if (match == null) return player.name;
    return l10n.defaultPlayerName(int.parse(match.group(1)!));
  }

  static String playerCountry(AppLocalizations l10n, PlayerCountry country) {
    return switch (country) {
      PlayerCountry.poland => l10n.countryPoland,
      PlayerCountry.ukraine => l10n.countryUkraine,
      PlayerCountry.germany => l10n.countryGermany,
      PlayerCountry.france => l10n.countryFrance,
      PlayerCountry.unitedKingdom => l10n.countryUnitedKingdom,
      PlayerCountry.italy => l10n.countryItaly,
      PlayerCountry.spain => l10n.countrySpain,
      PlayerCountry.netherlands => l10n.countryNetherlands,
      PlayerCountry.sweden => l10n.countrySweden,
      PlayerCountry.russia => l10n.countryRussia,
      PlayerCountry.unitedStates => l10n.countryUnitedStates,
      PlayerCountry.canada => l10n.countryCanada,
      PlayerCountry.china => l10n.countryChina,
      PlayerCountry.korea => l10n.countryKorea,
      PlayerCountry.japan => l10n.countryJapan,
      PlayerCountry.portugal => l10n.countryPortugal,
    };
  }

  static String diplomaticRelation(
    AppLocalizations l10n,
    DiplomaticRelationStatus status,
  ) {
    return switch (status) {
      DiplomaticRelationStatus.friendly => l10n.diplomacyRelationFriendly,
      DiplomaticRelationStatus.neutral => l10n.diplomacyRelationNeutral,
      DiplomaticRelationStatus.hostile => l10n.diplomacyRelationHostile,
      DiplomaticRelationStatus.truce => l10n.diplomacyRelationTruce,
      DiplomaticRelationStatus.war => l10n.diplomacyRelationWar,
    };
  }

  static String diplomaticRelationShort(
    AppLocalizations l10n,
    DiplomaticRelationStatus status,
  ) {
    return switch (status) {
      DiplomaticRelationStatus.friendly => l10n.diplomacyRelationFriendlyShort,
      DiplomaticRelationStatus.neutral => l10n.diplomacyRelationNeutralShort,
      DiplomaticRelationStatus.hostile => l10n.diplomacyRelationHostileShort,
      DiplomaticRelationStatus.truce => l10n.diplomacyRelationTruceShort,
      DiplomaticRelationStatus.war => l10n.diplomacyRelationWarShort,
    };
  }

  static List<PlayerCountry> sortedPlayerCountries(
    AppLocalizations l10n, {
    Iterable<PlayerCountry> countries = PlayerCountry.values,
  }) {
    return countries.toList()..sort((left, right) {
      final byName = playerCountry(
        l10n,
        left,
      ).toLowerCase().compareTo(playerCountry(l10n, right).toLowerCase());
      if (byName != 0) return byName;
      return left.name.compareTo(right.name);
    });
  }

  static String playerCountryLeader(
    AppLocalizations l10n,
    PlayerCountry country,
  ) {
    return switch (country) {
      PlayerCountry.poland => l10n.countryLeaderPoland,
      PlayerCountry.ukraine => l10n.countryLeaderUkraine,
      PlayerCountry.germany => l10n.countryLeaderGermany,
      PlayerCountry.france => l10n.countryLeaderFrance,
      PlayerCountry.unitedKingdom => l10n.countryLeaderUnitedKingdom,
      PlayerCountry.italy => l10n.countryLeaderItaly,
      PlayerCountry.spain => l10n.countryLeaderSpain,
      PlayerCountry.netherlands => l10n.countryLeaderNetherlands,
      PlayerCountry.sweden => l10n.countryLeaderSweden,
      PlayerCountry.russia => l10n.countryLeaderRussia,
      PlayerCountry.unitedStates => l10n.countryLeaderUnitedStates,
      PlayerCountry.canada => l10n.countryLeaderCanada,
      PlayerCountry.china => l10n.countryLeaderChina,
      PlayerCountry.korea => l10n.countryLeaderKorea,
      PlayerCountry.japan => l10n.countryLeaderJapan,
      PlayerCountry.portugal => l10n.countryLeaderPortugal,
    };
  }

  static String worldArtifact(AppLocalizations l10n, WorldArtifactType type) {
    return switch (type) {
      WorldArtifactType.ancientImperialCrown =>
        l10n.worldArtifactAncientImperialCrown,
      WorldArtifactType.astronomersTablets =>
        l10n.worldArtifactAstronomersTablets,
      WorldArtifactType.prophetMask => l10n.worldArtifactProphetMask,
      WorldArtifactType.heroSword => l10n.worldArtifactHeroSword,
      WorldArtifactType.merchantsSeal => l10n.worldArtifactMerchantsSeal,
      WorldArtifactType.firstPeoplesChronicle =>
        l10n.worldArtifactFirstPeoplesChronicle,
      WorldArtifactType.templeReliquary => l10n.worldArtifactTempleReliquary,
      WorldArtifactType.queensMirror => l10n.worldArtifactQueensMirror,
    };
  }

  static String worldArtifactShortBonus(
    AppLocalizations l10n,
    WorldArtifactType type,
  ) {
    return switch (type) {
      WorldArtifactType.ancientImperialCrown =>
        l10n.worldArtifactAncientImperialCrownShortBonus,
      WorldArtifactType.astronomersTablets =>
        l10n.worldArtifactAstronomersTabletsShortBonus,
      WorldArtifactType.prophetMask => l10n.worldArtifactProphetMaskShortBonus,
      WorldArtifactType.heroSword => l10n.worldArtifactHeroSwordShortBonus,
      WorldArtifactType.merchantsSeal =>
        l10n.worldArtifactMerchantsSealShortBonus,
      WorldArtifactType.firstPeoplesChronicle =>
        l10n.worldArtifactFirstPeoplesChronicleShortBonus,
      WorldArtifactType.templeReliquary =>
        l10n.worldArtifactTempleReliquaryShortBonus,
      WorldArtifactType.queensMirror =>
        l10n.worldArtifactQueensMirrorShortBonus,
    };
  }

  static String worldArtifactDescription(
    AppLocalizations l10n,
    WorldArtifactType type,
  ) {
    return switch (type) {
      WorldArtifactType.ancientImperialCrown =>
        l10n.worldArtifactAncientImperialCrownDescription,
      WorldArtifactType.astronomersTablets =>
        l10n.worldArtifactAstronomersTabletsDescription,
      WorldArtifactType.prophetMask => l10n.worldArtifactProphetMaskDescription,
      WorldArtifactType.heroSword => l10n.worldArtifactHeroSwordDescription,
      WorldArtifactType.merchantsSeal =>
        l10n.worldArtifactMerchantsSealDescription,
      WorldArtifactType.firstPeoplesChronicle =>
        l10n.worldArtifactFirstPeoplesChronicleDescription,
      WorldArtifactType.templeReliquary =>
        l10n.worldArtifactTempleReliquaryDescription,
      WorldArtifactType.queensMirror =>
        l10n.worldArtifactQueensMirrorDescription,
    };
  }

  static String worldArtifactLocation(
    AppLocalizations l10n,
    WorldArtifactLocation location,
  ) {
    return switch (location.kind) {
      WorldArtifactLocationKind.map => l10n.worldArtifactLocationMap,
      WorldArtifactLocationKind.excavation =>
        l10n.worldArtifactLocationExcavation,
      WorldArtifactLocationKind.carried => l10n.worldArtifactLocationCarried,
      WorldArtifactLocationKind.stored => l10n.worldArtifactLocationStored,
    };
  }

  static String mapObjective(AppLocalizations l10n, MapObjectiveType type) {
    return switch (type) {
      MapObjectiveType.ruins => l10n.mapObjectiveRuins,
      MapObjectiveType.strategicPass => l10n.mapObjectiveStrategicPass,
      MapObjectiveType.holySite => l10n.mapObjectiveHolySite,
      MapObjectiveType.legendaryResource => l10n.mapObjectiveLegendaryResource,
    };
  }

  static String mapObjectiveDescription(
    AppLocalizations l10n,
    MapObjectiveType type,
  ) {
    return switch (type) {
      MapObjectiveType.ruins => l10n.mapObjectiveRuinsDescription,
      MapObjectiveType.strategicPass =>
        l10n.mapObjectiveStrategicPassDescription,
      MapObjectiveType.holySite => l10n.mapObjectiveHolySiteDescription,
      MapObjectiveType.legendaryResource =>
        l10n.mapObjectiveLegendaryResourceDescription,
    };
  }

  static String cityBuilding(AppLocalizations l10n, CityBuildingType type) {
    return switch (type) {
      CityBuildingType.granary => l10n.cityBuildingGranary,
      CityBuildingType.waterMill => l10n.cityBuildingWaterMill,
      CityBuildingType.workshop => l10n.cityBuildingWorkshop,
      CityBuildingType.storehouse => l10n.cityBuildingStorehouse,
      CityBuildingType.housing => l10n.cityBuildingHousing,
      CityBuildingType.merchantHall => l10n.cityBuildingMerchantHall,
      CityBuildingType.stonemason => l10n.cityBuildingStonemason,
      CityBuildingType.barracks => l10n.cityBuildingBarracks,
      CityBuildingType.marketplace => l10n.cityBuildingMarketplace,
      CityBuildingType.port => l10n.cityBuildingPort,
      CityBuildingType.aqueduct => l10n.cityBuildingAqueduct,
      CityBuildingType.forge => l10n.cityBuildingForge,
      CityBuildingType.stable => l10n.cityBuildingStable,
      CityBuildingType.bank => l10n.cityBuildingBank,
      CityBuildingType.buildersGuild => l10n.cityBuildingBuildersGuild,
      CityBuildingType.factory => l10n.cityBuildingFactory,
      CityBuildingType.lighthouse => l10n.cityBuildingLighthouse,
      CityBuildingType.trainingGrounds => l10n.cityBuildingTrainingGrounds,
      CityBuildingType.townHall => l10n.cityBuildingTownHall,
      CityBuildingType.monument => l10n.cityBuildingMonument,
      CityBuildingType.archive => l10n.cityBuildingArchive,
      CityBuildingType.academy => l10n.cityBuildingAcademy,
      CityBuildingType.university => l10n.cityBuildingUniversity,
      CityBuildingType.observatory => l10n.cityBuildingObservatory,
      CityBuildingType.laboratory => l10n.cityBuildingLaboratory,
      CityBuildingType.reactor => l10n.cityBuildingReactor,
      CityBuildingType.courthouse => l10n.cityBuildingCourthouse,
      CityBuildingType.court => l10n.cityBuildingCourt,
      CityBuildingType.governorsOffice => l10n.cityBuildingGovernorsOffice,
      CityBuildingType.surveyorsOffice => l10n.cityBuildingSurveyorsOffice,
      CityBuildingType.planningOffice => l10n.cityBuildingPlanningOffice,
      CityBuildingType.apothecary => l10n.cityBuildingApothecary,
      CityBuildingType.publicBaths => l10n.cityBuildingPublicBaths,
      CityBuildingType.hospital => l10n.cityBuildingHospital,
      CityBuildingType.ministries => l10n.cityBuildingMinistries,
      CityBuildingType.walls => l10n.cityBuildingWalls,
      CityBuildingType.armory => l10n.cityBuildingArmory,
      CityBuildingType.siegeWorkshop => l10n.cityBuildingSiegeWorkshop,
      CityBuildingType.citadel => l10n.cityBuildingCitadel,
      CityBuildingType.warCollege => l10n.cityBuildingWarCollege,
      CityBuildingType.conscriptionOffice =>
        l10n.cityBuildingConscriptionOffice,
      CityBuildingType.borderFort => l10n.cityBuildingBorderFort,
      CityBuildingType.airfield => l10n.cityBuildingAirfield,
      CityBuildingType.artisansGuild => l10n.cityBuildingArtisansGuild,
      CityBuildingType.masterWorkshop => l10n.cityBuildingMasterWorkshop,
      CityBuildingType.steelworks => l10n.cityBuildingSteelworks,
      CityBuildingType.railDepot => l10n.cityBuildingRailDepot,
      CityBuildingType.powerPlant => l10n.cityBuildingPowerPlant,
      CityBuildingType.assemblyPlant => l10n.cityBuildingAssemblyPlant,
      CityBuildingType.refinery => l10n.cityBuildingRefinery,
      CityBuildingType.mapRoom => l10n.cityBuildingMapRoom,
      CityBuildingType.shipyard => l10n.cityBuildingShipyard,
      CityBuildingType.dryDock => l10n.cityBuildingDryDock,
      CityBuildingType.navalAcademy => l10n.cityBuildingNavalAcademy,
      CityBuildingType.harborCustoms => l10n.cityBuildingHarborCustoms,
      CityBuildingType.museum => l10n.cityBuildingMuseum,
      CityBuildingType.parliament => l10n.cityBuildingParliament,
      CityBuildingType.broadcastTower => l10n.cityBuildingBroadcastTower,
      CityBuildingType.worldFairGrounds => l10n.cityBuildingWorldFairGrounds,
    };
  }

  static String cityBuildingUnlock(
    AppLocalizations l10n,
    CityBuildingUnlockId type,
  ) {
    return cityBuilding(
      l10n,
      TechnologyUnlockQuery.buildingTypeForUnlock(type)!,
    );
  }

  static String cityBuildingDescription(
    AppLocalizations l10n,
    CityBuildingType type,
  ) {
    return switch (type) {
      CityBuildingType.granary => l10n.cityBuildingGranaryDescription,
      CityBuildingType.waterMill => l10n.cityBuildingWaterMillDescription,
      CityBuildingType.workshop => l10n.cityBuildingWorkshopDescription,
      CityBuildingType.storehouse => l10n.cityBuildingStorehouseDescription,
      CityBuildingType.housing => l10n.cityBuildingHousingDescription,
      CityBuildingType.merchantHall => l10n.cityBuildingMerchantHallDescription,
      CityBuildingType.stonemason => l10n.cityBuildingStonemasonDescription,
      CityBuildingType.barracks => l10n.cityBuildingBarracksDescription,
      CityBuildingType.marketplace => l10n.cityBuildingMarketplaceDescription,
      CityBuildingType.port => l10n.cityBuildingPortDescription,
      CityBuildingType.aqueduct => l10n.cityBuildingAqueductDescription,
      CityBuildingType.forge => l10n.cityBuildingForgeDescription,
      CityBuildingType.stable => l10n.cityBuildingStableDescription,
      CityBuildingType.bank => l10n.cityBuildingBankDescription,
      CityBuildingType.buildersGuild =>
        l10n.cityBuildingBuildersGuildDescription,
      CityBuildingType.factory => l10n.cityBuildingFactoryDescription,
      CityBuildingType.lighthouse => l10n.cityBuildingLighthouseDescription,
      CityBuildingType.trainingGrounds =>
        l10n.cityBuildingTrainingGroundsDescription,
      CityBuildingType.townHall => l10n.cityBuildingTownHallDescription,
      CityBuildingType.monument => l10n.cityBuildingMonumentDescription,
      CityBuildingType.archive => l10n.cityBuildingArchiveDescription,
      CityBuildingType.academy => l10n.cityBuildingAcademyDescription,
      CityBuildingType.university => l10n.cityBuildingUniversityDescription,
      CityBuildingType.observatory => l10n.cityBuildingObservatoryDescription,
      CityBuildingType.laboratory => l10n.cityBuildingLaboratoryDescription,
      CityBuildingType.reactor => l10n.cityBuildingReactorDescription,
      CityBuildingType.courthouse => l10n.cityBuildingCourthouseDescription,
      CityBuildingType.court => l10n.cityBuildingCourtDescription,
      CityBuildingType.governorsOffice =>
        l10n.cityBuildingGovernorsOfficeDescription,
      CityBuildingType.surveyorsOffice =>
        l10n.cityBuildingSurveyorsOfficeDescription,
      CityBuildingType.planningOffice =>
        l10n.cityBuildingPlanningOfficeDescription,
      CityBuildingType.apothecary => l10n.cityBuildingApothecaryDescription,
      CityBuildingType.publicBaths => l10n.cityBuildingPublicBathsDescription,
      CityBuildingType.hospital => l10n.cityBuildingHospitalDescription,
      CityBuildingType.ministries => l10n.cityBuildingMinistriesDescription,
      CityBuildingType.walls => l10n.cityBuildingWallsDescription,
      CityBuildingType.armory => l10n.cityBuildingArmoryDescription,
      CityBuildingType.siegeWorkshop =>
        l10n.cityBuildingSiegeWorkshopDescription,
      CityBuildingType.citadel => l10n.cityBuildingCitadelDescription,
      CityBuildingType.warCollege => l10n.cityBuildingWarCollegeDescription,
      CityBuildingType.conscriptionOffice =>
        l10n.cityBuildingConscriptionOfficeDescription,
      CityBuildingType.borderFort => l10n.cityBuildingBorderFortDescription,
      CityBuildingType.airfield => l10n.cityBuildingAirfieldDescription,
      CityBuildingType.artisansGuild =>
        l10n.cityBuildingArtisansGuildDescription,
      CityBuildingType.masterWorkshop =>
        l10n.cityBuildingMasterWorkshopDescription,
      CityBuildingType.steelworks => l10n.cityBuildingSteelworksDescription,
      CityBuildingType.railDepot => l10n.cityBuildingRailDepotDescription,
      CityBuildingType.powerPlant => l10n.cityBuildingPowerPlantDescription,
      CityBuildingType.assemblyPlant =>
        l10n.cityBuildingAssemblyPlantDescription,
      CityBuildingType.refinery => l10n.cityBuildingRefineryDescription,
      CityBuildingType.mapRoom => l10n.cityBuildingMapRoomDescription,
      CityBuildingType.shipyard => l10n.cityBuildingShipyardDescription,
      CityBuildingType.dryDock => l10n.cityBuildingDryDockDescription,
      CityBuildingType.navalAcademy => l10n.cityBuildingNavalAcademyDescription,
      CityBuildingType.harborCustoms =>
        l10n.cityBuildingHarborCustomsDescription,
      CityBuildingType.museum => l10n.cityBuildingMuseumDescription,
      CityBuildingType.parliament => l10n.cityBuildingParliamentDescription,
      CityBuildingType.broadcastTower =>
        l10n.cityBuildingBroadcastTowerDescription,
      CityBuildingType.worldFairGrounds =>
        l10n.cityBuildingWorldFairGroundsDescription,
    };
  }

  static String unitType(AppLocalizations l10n, GameUnitType type) {
    return switch (type) {
      GameUnitType.commander => l10n.unitCommander,
      GameUnitType.warrior => l10n.unitWarrior,
      GameUnitType.archer => l10n.unitArcher,
      GameUnitType.settler => l10n.unitSettler,
      GameUnitType.worker => l10n.unitWorker,
      GameUnitType.merchant => l10n.unitMerchant,
      GameUnitType.scout => l10n.unitScout,
      GameUnitType.spearman => l10n.unitSpearman,
      GameUnitType.cavalry => l10n.unitCavalry,
      GameUnitType.catapult => l10n.unitCatapult,
      GameUnitType.heavyInfantry => l10n.unitHeavyInfantry,
      GameUnitType.fieldCannon => l10n.unitFieldCannon,
      GameUnitType.rifleman => l10n.unitRifleman,
      GameUnitType.tank => l10n.unitTank,
      GameUnitType.scoutShip => l10n.unitScoutShip,
      GameUnitType.warship => l10n.unitWarship,
      GameUnitType.reconPlane => l10n.unitReconPlane,
    };
  }

  static String unit(AppLocalizations l10n, GameUnit unit) {
    final name = unit.name.trim();
    if (name.isEmpty || _isDefaultUnitName(name, unit.type)) {
      return unitType(l10n, unit.type);
    }
    return name;
  }

  static String unitWithType(AppLocalizations l10n, GameUnit unit) {
    final typeName = unitType(l10n, unit.type);
    final unitName = GameDisplayNames.unit(l10n, unit);
    return unitName == typeName ? typeName : '$typeName $unitName';
  }

  static String unitDescription(AppLocalizations l10n, GameUnitType type) {
    return switch (type) {
      GameUnitType.commander => l10n.unitCommanderDescription,
      GameUnitType.warrior => l10n.unitWarriorDescription,
      GameUnitType.archer => l10n.unitArcherDescription,
      GameUnitType.settler => l10n.unitSettlerDescription,
      GameUnitType.worker => l10n.unitWorkerDescription,
      GameUnitType.merchant => l10n.unitMerchantDescription,
      GameUnitType.scout => l10n.unitScoutDescription,
      GameUnitType.spearman => l10n.unitSpearmanDescription,
      GameUnitType.cavalry => l10n.unitCavalryDescription,
      GameUnitType.catapult => l10n.unitCatapultDescription,
      GameUnitType.heavyInfantry => l10n.unitHeavyInfantryDescription,
      GameUnitType.fieldCannon => l10n.unitFieldCannonDescription,
      GameUnitType.rifleman => l10n.unitRiflemanDescription,
      GameUnitType.tank => l10n.unitTankDescription,
      GameUnitType.scoutShip => l10n.unitScoutShipDescription,
      GameUnitType.warship => l10n.unitWarshipDescription,
      GameUnitType.reconPlane => l10n.unitReconPlaneDescription,
    };
  }

  static String unitVeterancyRank(
    AppLocalizations l10n,
    UnitVeterancyRank rank,
  ) {
    return switch (rank) {
      UnitVeterancyRank.recruit => l10n.unitRankRecruit,
      UnitVeterancyRank.seasoned => l10n.unitRankSeasoned,
      UnitVeterancyRank.veteran => l10n.unitRankVeteran,
      UnitVeterancyRank.elite => l10n.unitRankElite,
    };
  }

  static String cityProject(AppLocalizations l10n, CityProjectType type) {
    return switch (type) {
      CityProjectType.wealth => l10n.cityProjectWealth,
      CityProjectType.research => l10n.cityProjectResearch,
    };
  }

  static String troopType(AppLocalizations l10n, TroopType type) {
    return switch (type) {
      TroopType.warrior => l10n.troopWarrior,
      TroopType.archer => l10n.troopArcher,
      TroopType.settler => l10n.troopSettler,
    };
  }

  static String fieldImprovement(
    AppLocalizations l10n,
    FieldImprovementType type,
  ) {
    return switch (type) {
      FieldImprovementType.farm => l10n.fieldImprovementFarm,
      FieldImprovementType.riverFarm => l10n.fieldImprovementRiverFarm,
      FieldImprovementType.mine => l10n.fieldImprovementMine,
      FieldImprovementType.lumberMill => l10n.fieldImprovementLumberMill,
      FieldImprovementType.pasture => l10n.fieldImprovementPasture,
      FieldImprovementType.camp => l10n.fieldImprovementCamp,
      FieldImprovementType.quarry => l10n.fieldImprovementQuarry,
      FieldImprovementType.fishingBoats => l10n.fieldImprovementFishingBoats,
      FieldImprovementType.orchard => l10n.fieldImprovementOrchard,
      FieldImprovementType.plantation => l10n.fieldImprovementPlantation,
      FieldImprovementType.vineyard => l10n.fieldImprovementVineyard,
      FieldImprovementType.tradingPost => l10n.fieldImprovementTradingPost,
      FieldImprovementType.prospectorCamp =>
        l10n.fieldImprovementProspectorCamp,
      FieldImprovementType.horseRanch => l10n.fieldImprovementHorseRanch,
      FieldImprovementType.pearlDivers => l10n.fieldImprovementPearlDivers,
      FieldImprovementType.coalShaft => l10n.fieldImprovementCoalShaft,
      FieldImprovementType.oilWell => l10n.fieldImprovementOilWell,
      FieldImprovementType.bauxiteMine => l10n.fieldImprovementBauxiteMine,
      FieldImprovementType.uraniumMine => l10n.fieldImprovementUraniumMine,
    };
  }

  static String resource(AppLocalizations l10n, ResourceType resource) {
    return switch (resource) {
      ResourceType.wheat => l10n.resourceWheat,
      ResourceType.fish => l10n.resourceFish,
      ResourceType.deer => l10n.resourceDeer,
      ResourceType.sheep => l10n.resourceSheep,
      ResourceType.rice => l10n.resourceRice,
      ResourceType.cow => l10n.resourceCow,
      ResourceType.apple => l10n.resourceApple,
      ResourceType.banana => l10n.resourceBanana,
      ResourceType.citrus => l10n.resourceCitrus,
      ResourceType.gold => l10n.resourceGold,
      ResourceType.silver => l10n.resourceSilver,
      ResourceType.gems => l10n.resourceGems,
      ResourceType.silk => l10n.resourceSilk,
      ResourceType.spices => l10n.resourceSpices,
      ResourceType.cotton => l10n.resourceCotton,
      ResourceType.grapes => l10n.resourceGrapes,
      ResourceType.ivory => l10n.resourceIvory,
      ResourceType.pearls => l10n.resourcePearls,
      ResourceType.coffee => l10n.resourceCoffee,
      ResourceType.cocoa => l10n.resourceCocoa,
      ResourceType.tobacco => l10n.resourceTobacco,
      ResourceType.sugar => l10n.resourceSugar,
      ResourceType.iron => l10n.resourceIron,
      ResourceType.coal => l10n.resourceCoal,
      ResourceType.oil => l10n.resourceOil,
      ResourceType.aluminium => l10n.resourceAluminium,
      ResourceType.uranium => l10n.resourceUranium,
      ResourceType.horses => l10n.resourceHorses,
      ResourceType.marble => l10n.resourceMarble,
    };
  }

  static String technology(AppLocalizations l10n, TechnologyId id) {
    return switch (id) {
      TechnologyId.agriculture => l10n.technologyAgriculture,
      TechnologyId.woodworking => l10n.technologyWoodworking,
      TechnologyId.mining => l10n.technologyMining,
      TechnologyId.animalHusbandry => l10n.technologyAnimalHusbandry,
      TechnologyId.hunting => l10n.technologyHunting,
      TechnologyId.fishing => l10n.technologyFishing,
      TechnologyId.craftsmanship => l10n.technologyCraftsmanship,
      TechnologyId.trade => l10n.technologyTrade,
      TechnologyId.storage => l10n.technologyStorage,
      TechnologyId.waterEngineering => l10n.technologyWaterEngineering,
      TechnologyId.stoneworking => l10n.technologyStoneworking,
      TechnologyId.militaryOrganization => l10n.technologyMilitaryOrganization,
      TechnologyId.advancedTrade => l10n.technologyAdvancedTrade,
      TechnologyId.construction => l10n.technologyConstruction,
      TechnologyId.navigation => l10n.technologyNavigation,
      TechnologyId.irrigation => l10n.technologyIrrigation,
      TechnologyId.banking => l10n.technologyBanking,
      TechnologyId.engineering => l10n.technologyEngineering,
      TechnologyId.metallurgy => l10n.technologyMetallurgy,
      TechnologyId.horsebackRiding => l10n.technologyHorsebackRiding,
      TechnologyId.ironWorking => l10n.technologyIronWorking,
      TechnologyId.coalMining => l10n.technologyCoalMining,
      TechnologyId.machinery => l10n.technologyMachinery,
      TechnologyId.administration => l10n.technologyAdministration,
      TechnologyId.logistics => l10n.technologyLogistics,
      TechnologyId.shipbuilding => l10n.technologyShipbuilding,
      TechnologyId.tactics => l10n.technologyTactics,
      TechnologyId.economy => l10n.technologyEconomy,
      TechnologyId.urbanization => l10n.technologyUrbanization,
      TechnologyId.fortifications => l10n.technologyFortifications,
      TechnologyId.strategy => l10n.technologyStrategy,
      TechnologyId.specialization => l10n.technologySpecialization,
      TechnologyId.writing => l10n.technologyWriting,
      TechnologyId.mathematics => l10n.technologyMathematics,
      TechnologyId.medicine => l10n.technologyMedicine,
      TechnologyId.civilService => l10n.technologyCivilService,
      TechnologyId.siegecraft => l10n.technologySiegecraft,
      TechnologyId.cartography => l10n.technologyCartography,
      TechnologyId.guilds => l10n.technologyGuilds,
      TechnologyId.law => l10n.technologyLaw,
      TechnologyId.education => l10n.technologyEducation,
      TechnologyId.urbanPlanning => l10n.technologyUrbanPlanning,
      TechnologyId.navalDoctrine => l10n.technologyNavalDoctrine,
      TechnologyId.steel => l10n.technologySteel,
      TechnologyId.bureaucracy => l10n.technologyBureaucracy,
      TechnologyId.nationalism => l10n.technologyNationalism,
      TechnologyId.scientificMethod => l10n.technologyScientificMethod,
      TechnologyId.steamPower => l10n.technologySteamPower,
      TechnologyId.electricity => l10n.technologyElectricity,
      TechnologyId.combustion => l10n.technologyCombustion,
      TechnologyId.flight => l10n.technologyFlight,
      TechnologyId.massProduction => l10n.technologyMassProduction,
      TechnologyId.radio => l10n.technologyRadio,
      TechnologyId.nuclearPhysics => l10n.technologyNuclearPhysics,
    };
  }

  static String technologyDescription(AppLocalizations l10n, TechnologyId id) {
    return switch (id) {
      TechnologyId.agriculture => l10n.technologyAgricultureDescription,
      TechnologyId.woodworking => l10n.technologyWoodworkingDescription,
      TechnologyId.mining => l10n.technologyMiningDescription,
      TechnologyId.animalHusbandry => l10n.technologyAnimalHusbandryDescription,
      TechnologyId.hunting => l10n.technologyHuntingDescription,
      TechnologyId.fishing => l10n.technologyFishingDescription,
      TechnologyId.craftsmanship => l10n.technologyCraftsmanshipDescription,
      TechnologyId.trade => l10n.technologyTradeDescription,
      TechnologyId.storage => l10n.technologyStorageDescription,
      TechnologyId.waterEngineering =>
        l10n.technologyWaterEngineeringDescription,
      TechnologyId.stoneworking => l10n.technologyStoneworkingDescription,
      TechnologyId.militaryOrganization =>
        l10n.technologyMilitaryOrganizationDescription,
      TechnologyId.advancedTrade => l10n.technologyAdvancedTradeDescription,
      TechnologyId.construction => l10n.technologyConstructionDescription,
      TechnologyId.navigation => l10n.technologyNavigationDescription,
      TechnologyId.irrigation => l10n.technologyIrrigationDescription,
      TechnologyId.banking => l10n.technologyBankingDescription,
      TechnologyId.engineering => l10n.technologyEngineeringDescription,
      TechnologyId.metallurgy => l10n.technologyMetallurgyDescription,
      TechnologyId.horsebackRiding => l10n.technologyHorsebackRidingDescription,
      TechnologyId.ironWorking => l10n.technologyIronWorkingDescription,
      TechnologyId.coalMining => l10n.technologyCoalMiningDescription,
      TechnologyId.machinery => l10n.technologyMachineryDescription,
      TechnologyId.administration => l10n.technologyAdministrationDescription,
      TechnologyId.logistics => l10n.technologyLogisticsDescription,
      TechnologyId.shipbuilding => l10n.technologyShipbuildingDescription,
      TechnologyId.tactics => l10n.technologyTacticsDescription,
      TechnologyId.economy => l10n.technologyEconomyDescription,
      TechnologyId.urbanization => l10n.technologyUrbanizationDescription,
      TechnologyId.fortifications => l10n.technologyFortificationsDescription,
      TechnologyId.strategy => l10n.technologyStrategyDescription,
      TechnologyId.specialization => l10n.technologySpecializationDescription,
      TechnologyId.writing => l10n.technologyWritingDescription,
      TechnologyId.mathematics => l10n.technologyMathematicsDescription,
      TechnologyId.medicine => l10n.technologyMedicineDescription,
      TechnologyId.civilService => l10n.technologyCivilServiceDescription,
      TechnologyId.siegecraft => l10n.technologySiegecraftDescription,
      TechnologyId.cartography => l10n.technologyCartographyDescription,
      TechnologyId.guilds => l10n.technologyGuildsDescription,
      TechnologyId.law => l10n.technologyLawDescription,
      TechnologyId.education => l10n.technologyEducationDescription,
      TechnologyId.urbanPlanning => l10n.technologyUrbanPlanningDescription,
      TechnologyId.navalDoctrine => l10n.technologyNavalDoctrineDescription,
      TechnologyId.steel => l10n.technologySteelDescription,
      TechnologyId.bureaucracy => l10n.technologyBureaucracyDescription,
      TechnologyId.nationalism => l10n.technologyNationalismDescription,
      TechnologyId.scientificMethod =>
        l10n.technologyScientificMethodDescription,
      TechnologyId.steamPower => l10n.technologySteamPowerDescription,
      TechnologyId.electricity => l10n.technologyElectricityDescription,
      TechnologyId.combustion => l10n.technologyCombustionDescription,
      TechnologyId.flight => l10n.technologyFlightDescription,
      TechnologyId.massProduction => l10n.technologyMassProductionDescription,
      TechnologyId.radio => l10n.technologyRadioDescription,
      TechnologyId.nuclearPhysics => l10n.technologyNuclearPhysicsDescription,
    };
  }

  static String technologyEra(AppLocalizations l10n, TechnologyEra era) {
    return switch (era) {
      TechnologyEra.foundation => l10n.technologyEraFoundation,
      TechnologyEra.settlement => l10n.technologyEraSettlement,
      TechnologyEra.expansion => l10n.technologyEraExpansion,
      TechnologyEra.specialization => l10n.technologyEraSpecialization,
      TechnologyEra.industry => l10n.technologyEraIndustry,
      TechnologyEra.strategy => l10n.technologyEraStrategy,
    };
  }

  static String technologyUnlock(
    AppLocalizations l10n,
    TechnologyUnlock unlock,
  ) {
    return switch (unlock) {
      UnlockFieldImprovement(:final improvementType) => fieldImprovement(
        l10n,
        improvementType,
      ),
      UnlockCityBuilding(:final buildingId) => cityBuildingUnlock(
        l10n,
        buildingId,
      ),
      UnlockUnitType(:final unitType) => GameDisplayNames.unitType(
        l10n,
        unitType,
      ),
    };
  }

  static bool _isDefaultUnitName(String name, GameUnitType type) {
    return name == type.defaultNameToken;
  }
}
