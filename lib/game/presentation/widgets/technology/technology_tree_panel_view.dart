part of 'technology_tree_dialog.dart';

class _TechnologyTreePanelPresentation {
  const _TechnologyTreePanelPresentation({
    required this.l10n,
    required this.compact,
    required this.cards,
    required this.showTree,
    required this.detailsCard,
    required this.detailsBuildingType,
    required this.detailsUnitType,
    required this.detailsWonderType,
    required this.gamepadCards,
    required this.visibleSelectedTechnologyId,
  });

  final AppLocalizations l10n;
  final bool compact;
  final List<TechnologyCardViewModel> cards;
  final bool showTree;
  final TechnologyCardViewModel? detailsCard;
  final CityBuildingType? detailsBuildingType;
  final GameUnitType? detailsUnitType;
  final WonderType? detailsWonderType;
  final List<TechnologyCardViewModel> gamepadCards;
  final TechnologyId? visibleSelectedTechnologyId;

  bool get hasDetailsLayer =>
      detailsCard != null ||
      detailsBuildingType != null ||
      detailsUnitType != null ||
      detailsWonderType != null;
}

class _TechnologyTreePanelSurface extends StatelessWidget {
  const _TechnologyTreePanelSurface({
    required this.presentation,
    required this.viewModel,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.maxHeight,
    required this.pathAnimation,
    required this.verticalController,
    required this.horizontalController,
    required this.onClose,
    required this.onShowTree,
    required this.onShowRecommendations,
    required this.onTechnologySelected,
    required this.onTechnologyDetails,
    required this.onBuildingDetails,
    required this.onUnitDetails,
    required this.onWonderDetails,
    required this.onResearch,
    required this.onCloseDetails,
    required this.onCloseTechnologyDetails,
  });

  final _TechnologyTreePanelPresentation presentation;
  final TechnologyPanelViewModel viewModel;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final double maxHeight;
  final Animation<double> pathAnimation;
  final ScrollController verticalController;
  final ScrollController horizontalController;
  final VoidCallback onClose;
  final VoidCallback onShowTree;
  final VoidCallback onShowRecommendations;
  final ValueChanged<TechnologyCardViewModel> onTechnologySelected;
  final ValueChanged<TechnologyCardViewModel> onTechnologyDetails;
  final ValueChanged<CityBuildingType> onBuildingDetails;
  final ValueChanged<GameUnitType> onUnitDetails;
  final ValueChanged<WonderType> onWonderDetails;
  final ValueChanged<TechnologyId> onResearch;
  final VoidCallback onCloseDetails;
  final VoidCallback onCloseTechnologyDetails;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 980, maxHeight: maxHeight),
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
              sciencePerTurn: viewModel.sciencePerTurn,
              l10n: presentation.l10n,
              compact: presentation.compact,
              onClose: onClose,
            ),
            if (viewModel.activeTechnology case final activeTechnology?)
              TechnologyActiveResearchBanner(
                card: activeTechnology,
                l10n: presentation.l10n,
                compact: presentation.compact,
              ),
            _TechnologyTreeModeBar(
              mode: presentation.showTree
                  ? TechnologyTreeViewMode.tree
                  : TechnologyTreeViewMode.recommendations,
              compact: presentation.compact,
              technologyCount: presentation.cards.length,
              onShowTree: onShowTree,
              onShowRecommendations: onShowRecommendations,
            ),
            Expanded(child: _layers()),
          ],
        ),
      ),
    );
  }

  Widget _layers() {
    return _TechnologyTreePanelLayers(
      presentation: presentation,
      viewModel: viewModel,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      pathAnimation: pathAnimation,
      verticalController: verticalController,
      horizontalController: horizontalController,
      onTechnologySelected: onTechnologySelected,
      onTechnologyDetails: onTechnologyDetails,
      onBuildingDetails: onBuildingDetails,
      onUnitDetails: onUnitDetails,
      onWonderDetails: onWonderDetails,
      onResearch: onResearch,
      onCloseDetails: onCloseDetails,
      onCloseTechnologyDetails: onCloseTechnologyDetails,
    );
  }
}

class _TechnologyTreePanelLayers extends StatelessWidget {
  const _TechnologyTreePanelLayers({
    required this.presentation,
    required this.viewModel,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.pathAnimation,
    required this.verticalController,
    required this.horizontalController,
    required this.onTechnologySelected,
    required this.onTechnologyDetails,
    required this.onBuildingDetails,
    required this.onUnitDetails,
    required this.onWonderDetails,
    required this.onResearch,
    required this.onCloseDetails,
    required this.onCloseTechnologyDetails,
  });

  final _TechnologyTreePanelPresentation presentation;
  final TechnologyPanelViewModel viewModel;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final Animation<double> pathAnimation;
  final ScrollController verticalController;
  final ScrollController horizontalController;
  final ValueChanged<TechnologyCardViewModel> onTechnologySelected;
  final ValueChanged<TechnologyCardViewModel> onTechnologyDetails;
  final ValueChanged<CityBuildingType> onBuildingDetails;
  final ValueChanged<GameUnitType> onUnitDetails;
  final ValueChanged<WonderType> onWonderDetails;
  final ValueChanged<TechnologyId> onResearch;
  final VoidCallback onCloseDetails;
  final VoidCallback onCloseTechnologyDetails;

  @override
  Widget build(BuildContext context) {
    final details = _detailsLayer();
    return Stack(
      children: [
        Positioned.fill(child: _primaryView()),
        if (details != null) Positioned.fill(child: details),
      ],
    );
  }

  Widget _primaryView() {
    if (!presentation.showTree) {
      return TechnologyRecommendationsView(
        viewModel: viewModel,
        l10n: presentation.l10n,
        compact: presentation.compact,
        selectedTechnologyId: presentation.visibleSelectedTechnologyId,
        onResearch: onResearch,
        onTechnologyDetails: onTechnologyDetails,
      );
    }
    return TechnologyTreeBoard(
      cards: presentation.cards,
      selectedTechnologyId: presentation.visibleSelectedTechnologyId,
      hasDetailsLayer: presentation.hasDetailsLayer,
      compact: presentation.compact,
      pathAnimation: pathAnimation,
      verticalController: verticalController,
      horizontalController: horizontalController,
      l10n: presentation.l10n,
      onTechnologySelected: onTechnologySelected,
      onTechnologyDetails: onTechnologyDetails,
      onBuildingDetails: onBuildingDetails,
      onUnitDetails: onUnitDetails,
      onWonderDetails: onWonderDetails,
      onResearch: onResearch,
    );
  }

  Widget? _detailsLayer() {
    if (presentation.detailsBuildingType case final type?) {
      return TechnologyInlineCityBuildingDetailsLayer(
        buildingType: type,
        l10n: presentation.l10n,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        compact: presentation.compact,
        onClose: onCloseDetails,
      );
    }
    if (presentation.detailsUnitType case final type?) {
      return TechnologyInlineUnitDetailsLayer(
        unitType: type,
        l10n: presentation.l10n,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        compact: presentation.compact,
        onClose: onCloseDetails,
      );
    }
    if (presentation.detailsWonderType case final type?) {
      return TechnologyInlineWonderDetailsLayer(
        wonderType: type,
        l10n: presentation.l10n,
        technologyRuleset: technologyRuleset,
        compact: presentation.compact,
        onClose: onCloseDetails,
      );
    }
    if (presentation.detailsCard case final card?) {
      return TechnologyInlineTechnologyDetailsLayer(
        card: card,
        l10n: presentation.l10n,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        compact: presentation.compact,
        onClose: onCloseTechnologyDetails,
      );
    }
    return null;
  }
}
