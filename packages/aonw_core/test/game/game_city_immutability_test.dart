import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:test/test.dart';

void main() {
  test('snapshot owns all city collections', () {
    final controlled = <CityHex>[const CityHex(col: 1, row: 0)];
    final worked = <CityHex>[const CityHex(col: 0, row: 1)];
    final buildings = <CityBuildingType>{CityBuildingType.granary};
    final wonders = <WonderType>{WonderType.greatLibrary};
    final city = GameCity.snapshot(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: const CityHex(col: 0, row: 0),
      controlledHexes: controlled,
      workedHexes: worked,
      buildings: buildings,
      wonders: wonders,
    );
    final json = city.toJson();
    final hashCode = city.hashCode;

    controlled.clear();
    worked.clear();
    buildings.clear();
    wonders.clear();

    expect(city.controlledHexes, [const CityHex(col: 1, row: 0)]);
    expect(city.workedHexes, [const CityHex(col: 0, row: 1)]);
    expect(city.buildings, {CityBuildingType.granary});
    expect(city.wonders, {WonderType.greatLibrary});
    expect(city.toJson(), json);
    expect(city.hashCode, hashCode);
  });

  test('snapshot does not expose mutable city collections', () {
    final city = _city();

    expect(city.controlledHexes.clear, throwsUnsupportedError);
    expect(city.workedHexes.clear, throwsUnsupportedError);
    expect(city.buildings.clear, throwsUnsupportedError);
    expect(city.wonders.clear, throwsUnsupportedError);
  });

  test('scalar copyWith shares immutable collections', () {
    final city = _city();

    final renamed = city.copyWith(name: 'Renamed');

    expect(identical(renamed.controlledHexes, city.controlledHexes), isTrue);
    expect(identical(renamed.workedHexes, city.workedHexes), isTrue);
    expect(identical(renamed.buildings, city.buildings), isTrue);
    expect(identical(renamed.wonders, city.wonders), isTrue);
  });

  test('empty snapshots reuse canonical empty collections', () {
    final city = GameCity.snapshot(
      id: 'empty',
      ownerPlayerId: 'player_1',
      name: 'Empty',
      center: const CityHex(col: 0, row: 0),
    );
    final other = GameCity.snapshot(
      id: 'other',
      ownerPlayerId: 'player_1',
      name: 'Other',
      center: const CityHex(col: 1, row: 0),
    );

    expect(identical(city.controlledHexes, other.controlledHexes), isTrue);
    expect(identical(city.workedHexes, other.workedHexes), isTrue);
    expect(identical(city.buildings, other.buildings), isTrue);
    expect(identical(city.wonders, other.wonders), isTrue);
  });

  test('copyWith snapshots replacement collections', () {
    final replacement = <CityHex>[const CityHex(col: 2, row: 0)];

    final next = _city().copyWith(controlledHexes: replacement);
    replacement.clear();

    expect(next.controlledHexes, [const CityHex(col: 2, row: 0)]);
    expect(next.controlledHexes.clear, throwsUnsupportedError);
  });

  test('legacy city can be normalized once at the state boundary', () {
    final controlled = <CityHex>[const CityHex(col: 1, row: 0)];
    final legacy = GameCity(
      id: 'legacy',
      ownerPlayerId: 'player_1',
      name: 'Legacy',
      center: const CityHex(col: 0, row: 0),
      controlledHexes: controlled,
    );

    final snapshot = legacy.immutableSnapshot();
    final copied = legacy.copyWith(name: 'Copied');
    controlled.clear();

    expect(snapshot.controlledHexes, [const CityHex(col: 1, row: 0)]);
    expect(copied.controlledHexes, [const CityHex(col: 1, row: 0)]);
    expect(snapshot.controlledHexes.clear, throwsUnsupportedError);
    expect(identical(snapshot.immutableSnapshot(), snapshot), isTrue);
  });
}

GameCity _city() => GameCity.snapshot(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: const CityHex(col: 0, row: 0),
  controlledHexes: const [CityHex(col: 1, row: 0)],
  workedHexes: const [CityHex(col: 0, row: 1)],
  buildings: const {CityBuildingType.granary},
  wonders: const {WonderType.greatLibrary},
);
