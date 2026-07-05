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
}
