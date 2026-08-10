part of 'technology_tree_dialog.dart';

extension _TechnologyTreePanelGamepadSelection on _TechnologyTreePanelState {
  void _showGamepadSelection() {
    if (_gamepadSelectionVisible) return;
    _setDetailsState(() => _gamepadSelectionVisible = true);
  }

  TechnologyId? _visibleSelectedTechnologyId(TechnologyId? gamepadSelectedId) {
    if (_gamepadSelectionVisible) return gamepadSelectedId;
    return _selectedTechnologyId;
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
      useTreeGeometry: showTree,
    );
    if (nextCard == null) return;
    _setSelectedTechnology(nextCard, showTree: showTree, compact: compact);
  }

  void _setSelectedTechnology(
    TechnologyCardViewModel card, {
    required bool showTree,
    required bool compact,
  }) {
    _setDetailsState(() {
      _selectedTechnologyId = card.id;
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
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
      _setDetailsState(() => _selectedTechnologyId = selected.id);
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
    _setDetailsState(() {
      if (selected != null) _selectedTechnologyId = selected.id;
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
  }

  void _handleGamepadCancel() {
    if (_closeAnyDetails()) return;
    widget.onClose();
  }

  bool _closeAnyDetails() {
    if (_detailsTechnologyId == null &&
        _detailsBuildingType == null &&
        _detailsUnitType == null &&
        _detailsWonderType == null) {
      return false;
    }
    _setDetailsState(() {
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
    return true;
  }
}
