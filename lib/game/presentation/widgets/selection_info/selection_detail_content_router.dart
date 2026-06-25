import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/army_detail_content.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/buildings_detail_content.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/description_detail_content.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/improvements_detail_content.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/resources_detail_content.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/terrain_detail_content.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/worker_action_selection_detail_content.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class SelectionDetailContentRouter extends StatelessWidget {
  final SelectionDetailViewModel model;
  final bool compact;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final ValueChanged<TroopType>? onDetachTroop;
  final void Function(String unitId, FieldImprovementType type)?
  onSelectWorkerImprovement;
  final ValueChanged<String>? onConfirmWorkerImprovement;
  final ValueChanged<String>? onCancelWorkerActionSelection;

  const SelectionDetailContentRouter({
    required this.model,
    required this.compact,
    this.cityRuleset = CityRulesets.standard,
    this.technologyRuleset = TechnologyRulesets.standard,
    this.onDetachTroop,
    this.onSelectWorkerImprovement,
    this.onConfirmWorkerImprovement,
    this.onCancelWorkerActionSelection,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return switch (model) {
      final SelectionDescriptionDetail detail => DescriptionDetailContent(
        model: detail,
        compact: compact,
      ),
      final SelectionTerrainDetail detail => TerrainDetailContent(
        model: detail,
        compact: compact,
      ),
      final SelectionResourcesDetail detail => ResourcesDetailContent(
        model: detail,
        compact: compact,
      ),
      final SelectionImprovementsDetail detail => ImprovementsDetailContent(
        model: detail,
        compact: compact,
      ),
      final SelectionBuildingsDetail detail => BuildingsDetailContent(
        model: detail,
        compact: compact,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
      ),
      final SelectionArmyDetail detail => ArmyDetailContent(
        model: detail,
        onDetachTroop: onDetachTroop,
      ),
      final WorkerActionSelectionDetail detail =>
        WorkerActionSelectionDetailContent(
          model: detail,
          compact: compact,
          onSelectImprovement: onSelectWorkerImprovement,
          onConfirmImprovement: onConfirmWorkerImprovement,
          onCancelWorkerActionSelection: onCancelWorkerActionSelection,
        ),
    };
  }
}
