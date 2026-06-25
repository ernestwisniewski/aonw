import 'package:aonw/game/presentation/widgets/selection/view_models/selection_yield_item.dart';
import 'package:flutter/material.dart';

enum SelectionResourceImprovementStatusKind {
  availableForWorker,
  requiresTechnology,
  outsideCityBorders,
  tileAlreadyImproved,
  cityCenter,
  selectWorkerOrCity,
  noLegalImprovementForTile,
  custom,
}

class SelectionResourceValueCard {
  final String title;
  final String categoryLabel;
  final String currentSummary;
  final List<SelectionYieldItem> currentYield;
  final String improvementTitle;
  final String improvementStatus;
  final SelectionResourceImprovementStatusKind improvementStatusKind;
  final String? requiredTechnologyName;
  final List<SelectionYieldItem> improvementYield;
  final List<String> futureLines;
  final String expansionReason;
  final Color accentColor;

  const SelectionResourceValueCard({
    required this.title,
    required this.categoryLabel,
    required this.currentSummary,
    required this.currentYield,
    required this.improvementTitle,
    required this.improvementStatus,
    this.improvementStatusKind = SelectionResourceImprovementStatusKind.custom,
    this.requiredTechnologyName,
    required this.improvementYield,
    required this.futureLines,
    required this.expansionReason,
    required this.accentColor,
  });
}
