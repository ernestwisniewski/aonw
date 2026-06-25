import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

typedef MctsSimulatedCommandApplication = ({
  List<GameUnit> nextOwnUnits,
  List<GameUnit> nextVisibleEnemyUnits,
  List<GameCity> nextOwnCities,
  List<GameCity> nextRememberedEnemyCities,
  PlayerResearchState nextOwnResearch,
});
