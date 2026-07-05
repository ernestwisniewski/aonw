import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_recommendations_view.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_board.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_details_layers.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_gamepad_navigation.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_header.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/game/presentation/widgets/unit/unit_details_panel.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:aonw/game/presentation/widgets/technology/technology_tree_canvas.dart'
    show
        technologyTreeConnectorPointsForTesting,
        technologyTreeSelectedPathEdgesForTesting,
        technologyTreeSelectedPathTargetForTesting;

part 'technology_tree_panel_details.dart';

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
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 620;
    final cards = widget.viewModel.technologies;
    final showTree =
        ref.watch(technologyTreeViewModeProvider) ==
        TechnologyTreeViewMode.tree;
    final detailsCard = _technologyCardFor(cards, _detailsTechnologyId);
    final hasDetailsLayer =
        detailsCard != null ||
        _detailsBuildingType != null ||
        _detailsUnitType != null;
    final gamepadCards = TechnologyTreeGamepadNavigation.cardsFor(
      viewModel: widget.viewModel,
      showTree: showTree,
    );
    final selectedTechnologyId =
        TechnologyTreeGamepadNavigation.selectedTechnologyIdFor(
          gamepadCards,
          _selectedTechnologyId,
        );

    return GamepadPanelInputListener(
      input: widget.gamepadInputListenable,
      onNavigate: hasDetailsLayer
          ? null
          : (direction) => _moveSelection(
              gamepadCards,
              direction,
              showTree: showTree,
              compact: compact,
            ),
      onConfirm: hasDetailsLayer ? null : () => _confirmSelected(gamepadCards),
      onDetails: hasDetailsLayer
          ? null
          : () => _showSelectedDetails(gamepadCards),
      onMode: hasDetailsLayer
          ? null
          : () => _toggleTechnologyView(showTree, gamepadCards),
      onCancel: _handleGamepadCancel,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 980, maxHeight: widget.maxHeight),
        child: GameModalScaffold(
          surfaceKey: const Key('technologyTreePanel.surface'),
          size: GameModalSize.wide,
          showCornerDiamonds: false,
          contentPadding: EdgeInsets.zero,
          centerInAvailableSpace: false,
          scrollable: false,
          content: Column(
            children: [
              TechnologyTreeHeader(
                sciencePerTurn: widget.viewModel.sciencePerTurn,
                l10n: l10n,
                compact: compact,
                onClose: widget.onClose,
              ),
              if (widget.viewModel.activeTechnology != null)
                TechnologyActiveResearchBanner(
                  card: widget.viewModel.activeTechnology!,
                  l10n: l10n,
                  compact: compact,
                ),
              _TechnologyTreeModeBar(
                mode: showTree
                    ? TechnologyTreeViewMode.tree
                    : TechnologyTreeViewMode.recommendations,
                compact: compact,
                technologyCount: cards.length,
                onShowTree: _showFullTree,
                onShowRecommendations: _showRecommendations,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: showTree
                          ? TechnologyTreeBoard(
                              cards: cards,
                              selectedTechnologyId: selectedTechnologyId,
                              hasDetailsLayer: hasDetailsLayer,
                              compact: compact,
                              pathAnimation: _pathAnimationController,
                              verticalController: _verticalController,
                              horizontalController: _horizontalController,
                              l10n: l10n,
                              onTechnologySelected: _onTechnologyNodeTapped,
                              onTechnologyDetails: _showTechnologyDetails,
                              onBuildingDetails: _showBuildingDetails,
                              onUnitDetails: _showUnitDetails,
                              onResearch: _researchTechnology,
                            )
                          : TechnologyRecommendationsView(
                              viewModel: widget.viewModel,
                              l10n: l10n,
                              compact: compact,
                              selectedTechnologyId: selectedTechnologyId,
                              onResearch: _researchTechnology,
                              onTechnologyDetails: _showTechnologyDetails,
                            ),
                    ),
                    if (_detailsBuildingType != null)
                      Positioned.fill(
                        child: TechnologyInlineCityBuildingDetailsLayer(
                          buildingType: _detailsBuildingType!,
                          l10n: l10n,
                          cityRuleset: widget.cityRuleset,
                          technologyRuleset: widget.technologyRuleset,
                          compact: compact,
                          onClose: _closeDetailsLayer,
                        ),
                      ),
                    if (_detailsUnitType != null)
                      Positioned.fill(
                        child: TechnologyInlineUnitDetailsLayer(
                          unitType: _detailsUnitType!,
                          l10n: l10n,
                          cityRuleset: widget.cityRuleset,
                          technologyRuleset: widget.technologyRuleset,
                          compact: compact,
                          onClose: _closeDetailsLayer,
                        ),
                      ),
                    if (detailsCard != null)
                      Positioned.fill(
                        child: TechnologyInlineTechnologyDetailsLayer(
                          card: detailsCard,
                          l10n: l10n,
                          cityRuleset: widget.cityRuleset,
                          technologyRuleset: widget.technologyRuleset,
                          compact: compact,
                          onClose: _closeTechnologyDetails,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveSelection(
    List<TechnologyCardViewModel> cards,
    GamepadMapDirection direction, {
    required bool showTree,
    required bool compact,
  }) {
    final nextCard = TechnologyTreeGamepadNavigation.nextCard(
      cards: cards,
      selectedTechnologyId: _selectedTechnologyId,
      direction: direction,
    );
    if (nextCard == null) return;
    _setSelectedTechnology(nextCard, showTree: showTree, compact: compact);
  }

  void _setSelectedTechnology(
    TechnologyCardViewModel card, {
    required bool showTree,
    required bool compact,
  }) {
    setState(() {
      _selectedTechnologyId = card.id;
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
    });
    if (showTree) {
      TechnologyTreeGamepadNavigation.revealTreeCard(
        isMounted: () => mounted,
        cards: widget.viewModel.technologies,
        card: card,
        compact: compact,
        verticalController: _verticalController,
        horizontalController: _horizontalController,
      );
    }
  }

  void _confirmSelected(List<TechnologyCardViewModel> cards) {
    final selected = TechnologyTreeGamepadNavigation.selectedCard(
      cards,
      _selectedTechnologyId,
    );
    if (selected == null) return;
    if (selected.canSelect) {
      _researchTechnology(selected.id);
      return;
    }
    if (selected.state == TechnologyCardState.locked) {
      setState(() => _selectedTechnologyId = selected.id);
    }
  }

  void _showSelectedDetails(List<TechnologyCardViewModel> cards) {
    final selected = TechnologyTreeGamepadNavigation.selectedCard(
      cards,
      _selectedTechnologyId,
    );
    if (selected == null) return;
    _showTechnologyDetails(selected);
  }

  void _toggleTechnologyView(
    bool showTree,
    List<TechnologyCardViewModel> cards,
  ) {
    if (showTree) {
      _showRecommendations();
      return;
    }
    final selected = TechnologyTreeGamepadNavigation.selectedCard(
      cards,
      _selectedTechnologyId,
    );
    ref.read(technologyTreeViewModeProvider.notifier).showTree();
    setState(() {
      if (selected != null) _selectedTechnologyId = selected.id;
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
    });
  }

  void _handleGamepadCancel() {
    if (_closeAnyDetails()) return;
    widget.onClose();
  }

  bool _closeAnyDetails() {
    if (_detailsTechnologyId == null &&
        _detailsBuildingType == null &&
        _detailsUnitType == null) {
      return false;
    }
    setState(() {
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
    });
    return true;
  }

  void _researchTechnology(TechnologyId technologyId) {
    setState(() {
      _selectedTechnologyId = null;
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
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
    });
  }

  void _showRecommendations() {
    ref.read(technologyTreeViewModeProvider.notifier).showRecommendations();
    setState(() {
      _selectedTechnologyId = null;
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
    });
  }
}

class _TechnologyTreeModeBar extends StatelessWidget {
  const _TechnologyTreeModeBar({
    required this.mode,
    required this.compact,
    required this.technologyCount,
    required this.onShowTree,
    required this.onShowRecommendations,
  });

  final TechnologyTreeViewMode mode;
  final bool compact;
  final int technologyCount;
  final VoidCallback onShowTree;
  final VoidCallback onShowRecommendations;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showTree = mode == TechnologyTreeViewMode.tree;
    final title = showTree
        ? l10n.technologyFullTreeTitle
        : l10n.technologyRecommendationsTitle;
    final actionLabel = showTree
        ? l10n.technologyRecommendationsBackAction
        : technologyCount > 0
        ? l10n.technologyShowTreeCountAction(technologyCount)
        : l10n.technologyShowTreeAction;
    final actionIcon = showTree ? GameIcons.back : GameIcons.layers;
    final action = showTree ? onShowRecommendations : onShowTree;
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 8, 12, 8)
          : const EdgeInsets.fromLTRB(16, 9, 16, 9),
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 126,
        border: BorderEmphasis.subtle,
      ),
      child: Row(
        children: [
          GameIcon(
            showTree ? GameIcons.layers : GameIcons.science,
            size: GameIconSize.small,
            color: GameUiTheme.scienceAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              key: showTree
                  ? const Key('technologyTreeModeBar.title')
                  : const Key('technologyRecommendations.title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: action,
            style: TextButton.styleFrom(
              foregroundColor: GameUiTheme.scienceAccent,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: GameIcon(
              actionIcon,
              size: GameIconSize.tiny,
              color: GameUiTheme.scienceAccent,
            ),
            label: Text(
              actionLabel,
              style: GameUiTheme.actionLabel.copyWith(
                color: GameUiTheme.scienceAccent,
                fontSize: compact ? 10 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
