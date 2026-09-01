import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';

final class AonwCityFoundingDraft {
  const AonwCityFoundingDraft({
    required this.founderUnitId,
    required this.center,
    required this.controlledHexes,
  });

  factory AonwCityFoundingDraft.fromJson(Object? source) {
    final value = readObject(source, 'city founding draft');
    requireKeys(value, const {
      'founderUnitId',
      'center',
      'controlledHexes',
    }, 'city founding draft');
    return AonwCityFoundingDraft(
      founderUnitId: readString(value['founderUnitId'], 'founder unit id'),
      center: AonwCoordinate.fromJson(value['center']),
      controlledHexes: _coordinates(
        value['controlledHexes'],
        'controlled hexes',
      ),
    );
  }

  final String founderUnitId;
  final AonwCoordinate center;
  final List<AonwCoordinate> controlledHexes;
}

final class AonwOwnedCityPlanning {
  const AonwOwnedCityPlanning({
    required this.population,
    required this.workedHexes,
    required this.preferredExpansionHex,
  });

  factory AonwOwnedCityPlanning.fromJson(Object? source) {
    final value = readObject(source, 'owned city planning');
    requireKeys(value, const {
      'population',
      'workedHexes',
      'preferredExpansionHex',
    }, 'owned city planning');
    return AonwOwnedCityPlanning(
      population: readInt(value['population'], 'city population'),
      workedHexes: _coordinates(value['workedHexes'], 'worked hexes'),
      preferredExpansionHex: value['preferredExpansionHex'] == null
          ? null
          : AonwCoordinate.fromJson(value['preferredExpansionHex']),
    );
  }

  final int population;
  final List<AonwCoordinate> workedHexes;
  final AonwCoordinate? preferredExpansionHex;
}

final class AonwPlayerCityView {
  const AonwPlayerCityView({
    required this.id,
    required this.ownerPlayerId,
    required this.name,
    required this.center,
    required this.visibleControlledHexes,
    required this.ownedPlanning,
  });

  factory AonwPlayerCityView.fromJson(Object? source) {
    final value = readObject(source, 'player city view');
    requireKeys(value, const {
      'id',
      'ownerPlayerId',
      'name',
      'center',
      'visibleControlledHexes',
      'ownedPlanning',
    }, 'player city view');
    return AonwPlayerCityView(
      id: readString(value['id'], 'city id'),
      ownerPlayerId: readString(value['ownerPlayerId'], 'city owner'),
      name: readString(value['name'], 'city name'),
      center: AonwCoordinate.fromJson(value['center']),
      visibleControlledHexes: _coordinates(
        value['visibleControlledHexes'],
        'visible controlled hexes',
      ),
      ownedPlanning: value['ownedPlanning'] == null
          ? null
          : AonwOwnedCityPlanning.fromJson(value['ownedPlanning']),
    );
  }

  final String id;
  final String ownerPlayerId;
  final String name;
  final AonwCoordinate center;
  final List<AonwCoordinate> visibleControlledHexes;
  final AonwOwnedCityPlanning? ownedPlanning;
}

List<AonwCoordinate> _coordinates(Object? value, String label) =>
    readList(value, label, (item, _) => AonwCoordinate.fromJson(item));
