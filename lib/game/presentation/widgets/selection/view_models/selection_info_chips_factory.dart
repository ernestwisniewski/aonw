import 'package:aonw/game/presentation/widgets/selection/view_models/selection_improvement_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_chip_id.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_chip_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

abstract final class SelectionInfoChipsFactory {
  static List<SelectionInfoChipViewModel> chipsFor(
    SelectionViewModel model, {
    required AppLocalizations l10n,
  }) {
    if (_isCitySelection(model)) return const [];
    if (_isUnitSelection(model)) return _unitChipsFor(model, l10n);
    if (_isImprovementSelection(model)) {
      return _improvementChipsFor(model, l10n);
    }
    if (!_isTileSelection(model)) return const [];

    final terrain = _itemByLabel(model, SelectionInfoItemSemanticId.terrain);
    final resources = _itemByLabel(
      model,
      SelectionInfoItemSemanticId.resources,
    );
    final improvements = model.improvements;

    return [
      SelectionInfoChipViewModel(
        id: SelectionInfoChipId.description,
        icon: GameIcons.info,
        label: l10n.commonDescription,
      ),
      SelectionInfoChipViewModel(
        id: SelectionInfoChipId.terrain,
        icon: GameIcons.terrain,
        label: l10n.commonTerrain,
        badge: _extraCountBadge(
          _partsFrom(terrain?.value, noneLabel: l10n.commonNoneLower).length,
        ),
      ),
      if (resources != null)
        SelectionInfoChipViewModel(
          id: SelectionInfoChipId.resources,
          icon: GameIcons.resources,
          label: l10n.commonResources,
          badge:
              '${_partsFrom(resources.value, noneLabel: l10n.commonNoneLower).length}',
          tone: SelectionInfoChipTone.accent,
        ),
      SelectionInfoChipViewModel(
        id: SelectionInfoChipId.improvements,
        icon: GameIcons.improvement,
        label: l10n.commonImprovements,
        badge: improvements.isEmpty ? null : '${improvements.length}',
        tone: _improvementTone(improvements),
      ),
    ];
  }

  static List<SelectionInfoChipViewModel> _unitChipsFor(
    SelectionViewModel model,
    AppLocalizations l10n,
  ) {
    final terrain = _itemByLabel(model, SelectionInfoItemSemanticId.terrain);

    return [
      SelectionInfoChipViewModel(
        id: SelectionInfoChipId.description,
        icon: GameIcons.info,
        label: l10n.commonDescription,
      ),
      SelectionInfoChipViewModel(
        id: SelectionInfoChipId.terrain,
        icon: GameIcons.terrain,
        label: l10n.commonTerrain,
        badge: _extraCountBadge(
          _partsFrom(terrain?.value, noneLabel: l10n.commonNoneLower).length,
        ),
      ),
    ];
  }

  static List<SelectionInfoChipViewModel> _improvementChipsFor(
    SelectionViewModel model,
    AppLocalizations l10n,
  ) {
    return [
      SelectionInfoChipViewModel(
        id: SelectionInfoChipId.description,
        icon: GameIcons.info,
        label: l10n.commonDescription,
      ),
      SelectionInfoChipViewModel(
        id: SelectionInfoChipId.improvements,
        icon: GameIcons.improvement,
        label: l10n.commonImprovements,
        badge: model.improvements.isEmpty
            ? null
            : '${model.improvements.length}',
        tone: _improvementTone(model.improvements),
      ),
    ];
  }

  static bool supportsChip(SelectionViewModel model, String chipId) {
    if (_isCitySelection(model)) {
      return chipId == SelectionInfoChipId.description ||
          chipId == SelectionInfoChipId.buildings;
    }
    if (chipId == SelectionInfoChipId.army) {
      return model.supportsArmyDetail;
    }
    if (_isUnitSelection(model)) {
      return chipId == SelectionInfoChipId.description ||
          chipId == SelectionInfoChipId.terrain;
    }
    if (_isImprovementSelection(model)) {
      return chipId == SelectionInfoChipId.description ||
          chipId == SelectionInfoChipId.improvements;
    }
    if (_isTileSelection(model)) {
      if (chipId == SelectionInfoChipId.resources) {
        return _itemByLabel(model, SelectionInfoItemSemanticId.resources) !=
            null;
      }
      return chipId == SelectionInfoChipId.description ||
          chipId == SelectionInfoChipId.terrain ||
          chipId == SelectionInfoChipId.improvements;
    }
    return false;
  }

  static bool _isTileSelection(SelectionViewModel model) {
    return model.selectionKey.startsWith('tile:');
  }

  static bool _isCitySelection(SelectionViewModel model) {
    return model.selectionKey.startsWith('city:');
  }

  static bool _isUnitSelection(SelectionViewModel model) {
    return model.selectionKey.startsWith('unit:');
  }

  static bool _isImprovementSelection(SelectionViewModel model) {
    return model.selectionKey.startsWith('improvement:');
  }

  static SelectionInfoItem? _itemByLabel(
    SelectionViewModel model,
    String label,
  ) {
    for (final item in model.items) {
      if (item.label == label || item.semanticId == label) {
        return item;
      }
    }
    return null;
  }

  static String? _extraCountBadge(int count) {
    if (count <= 1) return null;
    return '+${count - 1}';
  }

  static List<String> _partsFrom(String? value, {required String noneLabel}) {
    if (value == null || value.isEmpty) return const [];
    final normalized = value.toLowerCase();
    if (normalized == noneLabel.toLowerCase()) return const [];
    return [
      for (final part in value.split(' + '))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static SelectionInfoChipTone _improvementTone(
    List<SelectionImprovementItem> improvements,
  ) {
    if (improvements.any(
      (item) => item.state == SelectionImprovementState.built,
    )) {
      return SelectionInfoChipTone.accent;
    }
    if (improvements.any(
      (item) => item.state == SelectionImprovementState.available,
    )) {
      return SelectionInfoChipTone.accent;
    }
    if (improvements.any(
      (item) => item.state == SelectionImprovementState.needsTechnology,
    )) {
      return SelectionInfoChipTone.warning;
    }
    return SelectionInfoChipTone.neutral;
  }
}
