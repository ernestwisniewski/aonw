import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('civilization profile weights match the tuning snapshot', () {
    const registry = CivilizationProfileRegistry();

    final actual = {
      for (final country in PlayerCountry.values)
        country.name: _summarize(registry.profileFor(country)),
    };

    expect(actual, const {
      'poland': 'persona=balanced; A1.00 X1.00 E1.00 S1.00; b1.00 d1.00 f1.00',
      'ukraine':
          'persona=expansive; A1.00 X1.12 E1.05 S1.05; b1.00 d1.12 f1.15',
      'germany':
          'persona=aggressive; A1.10 X1.00 E1.15 S1.00; b1.25 d0.95 f1.10',
      'france':
          'persona=scientific; A0.95 X1.12 E1.00 S1.10; b0.95 d1.08 f1.00',
      'unitedKingdom':
          'persona=economic; A1.00 X1.00 E1.15 S1.10; b1.00 d1.15 f1.00',
      'italy': 'persona=economic; A0.95 X0.95 E1.15 S1.00; b0.95 d0.95 f1.00',
      'spain': 'persona=expansive; A1.10 X1.15 E1.00 S1.00; b1.15 d1.25 f1.15',
      'netherlands':
          'persona=economic; A0.90 X1.00 E1.20 S1.05; b0.90 d1.00 f0.95',
      'sweden':
          'persona=scientific; A1.00 X1.00 E1.10 S1.15; b1.00 d1.00 f1.00',
      'russia': 'persona=expansive; A1.00 X1.20 E1.05 S1.10; b1.05 d1.25 f1.20',
      'unitedStates':
          'persona=expansive; A1.10 X1.15 E1.10 S1.00; b1.10 d1.20 f1.10',
      'canada': 'persona=economic; A0.85 X1.10 E1.10 S1.00; b0.85 d1.15 f1.00',
      'china': 'persona=balanced; A1.05 X1.05 E1.15 S1.10; b1.05 d1.05 f1.05',
      'korea': 'persona=scientific; A0.95 X0.95 E1.00 S1.20; b0.95 d0.95 f1.00',
      'japan': 'persona=aggressive; A1.15 X0.95 E1.00 S1.10; b1.20 d0.90 f0.95',
      'portugal':
          'persona=economic; A0.90 X1.15 E1.20 S1.05; b0.90 d1.20 f1.10',
    });
  });
}

String _summarize(CivilizationProfile profile) {
  return 'persona=${profile.defaultPersona.name}; '
      'A${profile.civBias.aggression.toStringAsFixed(2)} '
      'X${profile.civBias.expansion.toStringAsFixed(2)} '
      'E${profile.civBias.economy.toStringAsFixed(2)} '
      'S${profile.civBias.science.toStringAsFixed(2)}; '
      'b${profile.belligerence.toStringAsFixed(2)} '
      'd${profile.expansionDistance.toStringAsFixed(2)} '
      'f${profile.frontierTolerance.toStringAsFixed(2)}';
}
