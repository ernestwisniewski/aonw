import 'package:aonw_core/util/collection_equality.dart';

enum TechBranch { military, economy, science, expansion }

class TechBranchPreferences {
  final Map<TechBranch, double> weights;

  const TechBranchPreferences({this.weights = const {}});

  static const identity = TechBranchPreferences();

  double weightFor(TechBranch branch) => weights[branch] ?? 1.0;

  @override
  bool operator ==(Object other) {
    return other is TechBranchPreferences && mapEquals(other.weights, weights);
  }

  @override
  int get hashCode {
    return Object.hashAll(
      TechBranch.values.map((branch) => Object.hash(branch, weightFor(branch))),
    );
  }
}
