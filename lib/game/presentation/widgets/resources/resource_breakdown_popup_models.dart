part of 'resource_breakdown_popup.dart';

class GoldCitySource {
  final GameCity city;
  final int amount;

  const GoldCitySource({required this.city, required this.amount});
}

class GoldProjectSource {
  final GameCity city;
  final int amount;

  const GoldProjectSource({required this.city, required this.amount});
}

class GoldBreakdown {
  final int treasury;
  final List<GoldCitySource> citySources;
  final List<GoldProjectSource> projectSources;
  final UnitUpkeepBreakdown upkeep;

  const GoldBreakdown({
    required this.treasury,
    required this.citySources,
    required this.projectSources,
    required this.upkeep,
  });

  int get cityIncome {
    var total = 0;
    for (final source in citySources) {
      total += source.amount;
    }
    return total;
  }

  int get projectIncome {
    var total = 0;
    for (final source in projectSources) {
      total += source.amount;
    }
    return total;
  }

  int get grossIncome => cityIncome + projectIncome;

  int get unitUpkeep => upkeep.total;

  int get netPerTurn => grossIncome - unitUpkeep;
}

class _BreakdownSectionModel {
  final String title;
  final List<_BreakdownRowModel> rows;

  const _BreakdownSectionModel({required this.title, required this.rows});
}

class _BreakdownRowModel {
  final String label;
  final String value;
  final bool positive;
  final bool negative;

  const _BreakdownRowModel({
    required this.label,
    required this.value,
    this.positive = false,
    this.negative = false,
  });
}
