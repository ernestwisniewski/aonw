import 'dart:async';

import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/game_wonder_display_names.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/wonder_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_recommendations_view.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_board.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_details_layers.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_gamepad_navigation.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_header.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/unit/unit_details_panel.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:aonw/game/presentation/widgets/technology/technology_tree_canvas.dart'
    show
        technologyTreeConnectorPointsForTesting,
        technologyTreeSelectedPathEdgesForTesting,
        technologyTreeSelectedPathTargetForTesting;

part 'technology_tree_mode_bar.dart';
part 'technology_tree_panel_details.dart';
part 'technology_tree_panel_gamepad_selection.dart';
part 'technology_tree_panel_view.dart';

enum TechnologyTreeViewMode { recommendations, tree }

final technologyTreeViewModeProvider =
    NotifierProvider<TechnologyTreeViewModeController, TechnologyTreeViewMode>(
      TechnologyTreeViewModeController.new,
    );

class TechnologyTreeViewModeController
    extends Notifier<TechnologyTreeViewMode> {
  @override
  TechnologyTreeViewMode build() => TechnologyTreeViewMode.recommendations;

  void showRecommendations() {
    if (state == TechnologyTreeViewMode.recommendations) return;
    state = TechnologyTreeViewMode.recommendations;
  }

  void showTree() {
    if (state == TechnologyTreeViewMode.tree) return;
    state = TechnologyTreeViewMode.tree;
  }
}

class TechnologyTreeDialog extends StatelessWidget {
  final TechnologyPanelViewModel viewModel;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final ValueChanged<TechnologyId> onResearch;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  const TechnologyTreeDialog({
    required this.viewModel,
    this.cityRuleset = CityRulesets.standard,
    this.technologyRuleset = TechnologyRulesets.standard,
    required this.onResearch,
    this.gamepadInputListenable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return TechnologyTreePanel(
      viewModel: viewModel,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      maxHeight: size.height * 0.84,
      onResearch: onResearch,
      gamepadInputListenable: gamepadInputListenable,
      onClose: () => Navigator.of(context).maybePop(),
    );
  }
}

class TechnologyTreePanel extends ConsumerStatefulWidget {
  final TechnologyPanelViewModel viewModel;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final double maxHeight;
  final ValueChanged<TechnologyId> onResearch;
  final VoidCallback onClose;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  const TechnologyTreePanel({
    required this.viewModel,
    this.cityRuleset = CityRulesets.standard,
    this.technologyRuleset = TechnologyRulesets.standard,
    required this.maxHeight,
    required this.onResearch,
    required this.onClose,
    this.gamepadInputListenable,
    super.key,
  });

  @override
  ConsumerState<TechnologyTreePanel> createState() =>
      _TechnologyTreePanelState();
}

class _TechnologyTreePanelState extends ConsumerState<TechnologyTreePanel>
    with SingleTickerProviderStateMixin {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  late final AnimationController _pathAnimationController;
  TechnologyId? _selectedTechnologyId;
  TechnologyId? _detailsTechnologyId;
  CityBuildingType? _detailsBuildingType;
  GameUnitType? _detailsUnitType;
  WonderType? _detailsWonderType;
  bool _gamepadSelectionVisible = false;

  void _setDetailsState(void Function() update) {
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    unawaited(_pathAnimationController.repeat());
  }

  @override
  void dispose() {
    _pathAnimationController.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(context);

    return GamepadPanelInputListener(
      input: widget.gamepadInputListenable,
      onNavigate: presentation.hasDetailsLayer
          ? null
          : (direction) => _moveSelection(
              presentation.gamepadCards,
              direction,
              showTree: presentation.showTree,
              compact: presentation.compact,
            ),
      onConfirm: presentation.hasDetailsLayer
          ? null
          : () => _confirmSelected(presentation.gamepadCards),
      onDetails: presentation.hasDetailsLayer
          ? null
          : () => _showSelectedDetails(presentation.gamepadCards),
      onMode: presentation.hasDetailsLayer
          ? null
          : () => _toggleTechnologyView(
              presentation.showTree,
              presentation.gamepadCards,
            ),
      onCancel: _handleGamepadCancel,
      onInputActive: _showGamepadSelection,
      child: _TechnologyTreePanelSurface(
        presentation: presentation,
        viewModel: widget.viewModel,
        cityRuleset: widget.cityRuleset,
        technologyRuleset: widget.technologyRuleset,
        maxHeight: widget.maxHeight,
        pathAnimation: _pathAnimationController,
        verticalController: _verticalController,
        horizontalController: _horizontalController,
        onClose: widget.onClose,
        onShowTree: _showFullTree,
        onShowRecommendations: _showRecommendations,
        onTechnologySelected: _onTechnologyNodeTapped,
        onTechnologyDetails: _showTechnologyDetails,
        onBuildingDetails: _showBuildingDetails,
        onUnitDetails: _showUnitDetails,
        onWonderDetails: _showWonderDetails,
        onResearch: _researchTechnology,
        onCloseDetails: _closeDetailsLayer,
        onCloseTechnologyDetails: _closeTechnologyDetails,
      ),
    );
  }

  _TechnologyTreePanelPresentation _presentationFor(BuildContext context) {
    final cards = widget.viewModel.technologies;
    final showTree =
        ref.watch(technologyTreeViewModeProvider) ==
        TechnologyTreeViewMode.tree;
    final gamepadCards = TechnologyTreeGamepadNavigation.cardsFor(
      viewModel: widget.viewModel,
      showTree: showTree,
    );
    final selectedTechnologyId =
        TechnologyTreeGamepadNavigation.selectedTechnologyIdFor(
          gamepadCards,
          _selectedTechnologyId,
        );
    return _TechnologyTreePanelPresentation(
      l10n: AppLocalizations.of(context),
      compact: MediaQuery.sizeOf(context).width < 620,
      cards: cards,
      showTree: showTree,
      detailsCard: _technologyCardFor(cards, _detailsTechnologyId),
      detailsBuildingType: _detailsBuildingType,
      detailsUnitType: _detailsUnitType,
      detailsWonderType: _detailsWonderType,
      gamepadCards: gamepadCards,
      visibleSelectedTechnologyId: _visibleSelectedTechnologyId(
        selectedTechnologyId,
      ),
    );
  }

  void _researchTechnology(TechnologyId technologyId) {
    setState(() {
      _selectedTechnologyId = null;
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
    widget.onResearch(technologyId);
  }

  void _onTechnologyNodeTapped(TechnologyCardViewModel card) {
    if (card.canSelect) {
      _researchTechnology(card.id);
      return;
    }
    setState(() {
      _selectedTechnologyId = card.state == TechnologyCardState.locked
          ? card.id
          : null;
    });
  }

  void _showFullTree() {
    ref.read(technologyTreeViewModeProvider.notifier).showTree();
    setState(() {
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
  }

  void _showRecommendations() {
    ref.read(technologyTreeViewModeProvider.notifier).showRecommendations();
    setState(() {
      _selectedTechnologyId = null;
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
  }
}
