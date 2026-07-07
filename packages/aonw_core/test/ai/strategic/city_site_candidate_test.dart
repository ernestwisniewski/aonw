import 'package:aonw_core/ai/strategic/city_site_candidate.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:test/test.dart';

void main() {
  test('accepts lazy territory iterables and freezes hex lists', () {
    final candidate = CitySiteCandidate(
      center: const CityHex(col: 1, row: 1),
      controlledHexes: _lazyHexes(),
      projectedTerritory: _lazyProjectedHexes(),
      score: 8,
      baseScore: 6,
      futureYieldScore: 3,
      overlapPenalty: 1,
      nearestFounderDistance: 4,
    );
    final sameCandidate = CitySiteCandidate(
      center: const CityHex(col: 1, row: 1),
      controlledHexes: const [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
      projectedTerritory: const [
        CityHex(col: 1, row: 1),
        CityHex(col: 1, row: 0),
        CityHex(col: 0, row: 1),
      ],
      score: 8,
      baseScore: 6,
      futureYieldScore: 3,
      overlapPenalty: 1,
      nearestFounderDistance: 4,
    );

    expect(candidate, sameCandidate);
    expect(candidate.hashCode, sameCandidate.hashCode);
    expect(
      () => candidate.controlledHexes.add(const CityHex(col: 2, row: 2)),
      throwsUnsupportedError,
    );
    expect(
      () => candidate.projectedTerritory.add(const CityHex(col: 2, row: 2)),
      throwsUnsupportedError,
    );
  });
}

Iterable<CityHex> _lazyHexes() sync* {
  yield const CityHex(col: 1, row: 0);
  yield const CityHex(col: 0, row: 1);
}

Iterable<CityHex> _lazyProjectedHexes() sync* {
  yield const CityHex(col: 1, row: 1);
  yield* _lazyHexes();
}
