import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/selection_detail_content_router.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class SelectionDetailSheet extends StatelessWidget {
  static const double _headerExtent = 36;
  static const double _headerBodyGap = 10;
  static const double _standardDetailMaxWidth = 680;
  static const double _richDetailMaxWidth = 760;
  static const double _workerActionMaxWidth = 720;
  static const double _defaultFillHeightFactor = 0.45;
  static const double _buildingsFillHeightFactor = 0.62;

  final SelectionDetailViewModel model;
  final bool compact;
  final bool fillWidth;
  final bool sidePanel;
  final bool bottomSheet;
  final bool peek;
  final double sidePanelWidth;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final VoidCallback onClose;
  final ValueChanged<TroopType>? onDetachTroop;
  final void Function(String unitId, FieldImprovementType type)?
  onSelectWorkerImprovement;
  final ValueChanged<String>? onConfirmWorkerImprovement;
  final ValueChanged<String>? onCancelWorkerActionSelection;

  const SelectionDetailSheet({
    required this.model,
    required this.compact,
    this.fillWidth = false,
    this.sidePanel = false,
    this.bottomSheet = false,
    this.peek = false,
    this.sidePanelWidth = 360,
    this.cityRuleset = CityRulesets.standard,
    this.technologyRuleset = TechnologyRulesets.standard,
    required this.onClose,
    this.onDetachTroop,
    this.onSelectWorkerImprovement,
    this.onConfirmWorkerImprovement,
    this.onCancelWorkerActionSelection,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * _resolveMaxHeightFactor();
    final maxWidth = _resolveMaxWidth(size.width);

    final sheet = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: SizedBox(
        width: fillWidth || sidePanel ? maxWidth : null,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 200) onClose();
          },
          child: DecoratedBox(
            key: const Key('selectionInfo.detailSheet.surface'),
            decoration: SurfaceElevation.raised.decoration(
              background: GameUiTheme.bg,
              backgroundAlpha: 236,
              border: BorderEmphasis.strong,
              shape: SurfaceShape.card,
              includeShadow: false,
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA000000),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxBodyHeight = constraints.maxHeight.isFinite
                      ? (constraints.maxHeight - _headerExtent - _headerBodyGap)
                            .clamp(0.0, double.infinity)
                            .toDouble()
                      : double.infinity;
                  final detail = KeyedSubtree(
                    key: Key('selectionInfo.detail.${model.chipId}'),
                    child: SelectionDetailContentRouter(
                      model: model,
                      compact: compact,
                      cityRuleset: cityRuleset,
                      technologyRuleset: technologyRuleset,
                      onDetachTroop: onDetachTroop,
                      onSelectWorkerImprovement: onSelectWorkerImprovement,
                      onConfirmWorkerImprovement: onConfirmWorkerImprovement,
                      onCancelWorkerActionSelection:
                          onCancelWorkerActionSelection,
                    ),
                  );
                  final content = model is WorkerActionSelectionDetail
                      ? detail
                      : SingleChildScrollView(child: detail);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SelectionDetailHeader(
                        title: model.title,
                        onClose: onClose,
                      ),
                      const SizedBox(height: _headerBodyGap),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxBodyHeight),
                        child: content,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    if (bottomSheet) {
      return Align(alignment: Alignment.bottomCenter, child: sheet);
    }

    return Align(
      alignment: sidePanel ? Alignment.centerRight : Alignment.center,
      child: sheet,
    );
  }

  double _resolveMaxWidth(double screenWidth) {
    if (sidePanel) {
      return screenWidth.clamp(0.0, sidePanelWidth).toDouble();
    }
    final availableWidth = screenWidth * 0.92;
    final readableCap = switch (model) {
      SelectionDescriptionDetail() => _richDetailMaxWidth,
      SelectionResourcesDetail() => _richDetailMaxWidth,
      WorkerActionSelectionDetail() => _workerActionMaxWidth,
      SelectionTerrainDetail() ||
      SelectionImprovementsDetail() ||
      SelectionBuildingsDetail() ||
      SelectionArmyDetail() => _standardDetailMaxWidth,
    };
    return math.min(availableWidth, readableCap);
  }

  double _resolveMaxHeightFactor() {
    if (peek) return 0.35;
    if (model is WorkerActionSelectionDetail) return 0.58;
    if (!fillWidth) return 0.55;
    return switch (model) {
      SelectionBuildingsDetail() => _buildingsFillHeightFactor,
      _ => _defaultFillHeightFactor,
    };
  }
}

class _SelectionDetailHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _SelectionDetailHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: SelectionDetailSheet._headerExtent,
      child: Row(
        children: [
          Expanded(
            child: GameUiEpicHeader(
              label: title,
              alignment: Alignment.centerLeft,
              compact: false,
              textKey: const Key('selectionInfo.detail.title'),
            ),
          ),
          IconButton(
            key: const Key('selectionInfo.detail.close'),
            tooltip: l10n.closeAction,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            onPressed: onClose,
            icon: const GameIcon(
              GameIcons.close,
              size: GameIconSize.regular,
              color: GameUiTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
