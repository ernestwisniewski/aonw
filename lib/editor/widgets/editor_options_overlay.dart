import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/widgets/map_view_mode_toggle.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_options_panel.dart';
import 'package:flutter/material.dart';

/// Top-right ⚙ button + dropdown options panel for the map editor.
///
/// Uses Flutter's Overlay so the dismiss barrier covers the full screen,
/// preventing clicks from reaching the game world underneath.
class EditorOptionsOverlay extends StatefulWidget {
  final MapViewMode viewMode;
  final bool allowGraphicMode;
  final ValueChanged<MapViewMode> onViewModeChanged;
  final VoidCallback onSave;
  final bool showTerrain;
  final bool showResources;
  final bool showHeightBadge;
  final bool showCitySites;
  final bool showCityGrowth;
  final bool showDiceRollTest;
  final VoidCallback onToggleTerrain;
  final VoidCallback onToggleResources;
  final VoidCallback onToggleHeightBadge;
  final VoidCallback onToggleCitySites;
  final VoidCallback onToggleCityGrowth;
  final VoidCallback? onToggleDiceRollTest;

  const EditorOptionsOverlay({
    required this.viewMode,
    required this.allowGraphicMode,
    required this.onViewModeChanged,
    required this.onSave,
    required this.showTerrain,
    required this.showResources,
    required this.showHeightBadge,
    required this.showCitySites,
    required this.showCityGrowth,
    this.showDiceRollTest = false,
    required this.onToggleTerrain,
    required this.onToggleResources,
    required this.onToggleHeightBadge,
    required this.onToggleCitySites,
    required this.onToggleCityGrowth,
    this.onToggleDiceRollTest,
    super.key,
  });

  @override
  State<EditorOptionsOverlay> createState() => _EditorOptionsOverlayState();
}

class _EditorOptionsOverlayState extends State<EditorOptionsOverlay> {
  final _buttonKey = GlobalKey();
  OverlayEntry? _barrier;
  OverlayEntry? _panel;
  bool _panelRebuildScheduled = false;

  bool get _open => _panel != null;

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _open_();
    }
  }

  void _open_() {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _barrier = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          child: const ColoredBox(color: Colors.transparent),
        ),
      ),
    );

    _panel = OverlayEntry(
      builder: (_) => Positioned(
        top: offset.dy + size.height + 4,
        right: MediaQuery.of(context).size.width - offset.dx - size.width,
        child: _OptionsPanel(
          viewMode: widget.viewMode,
          allowGraphicMode: widget.allowGraphicMode,
          onViewModeChanged: (mode) {
            widget.onViewModeChanged(mode);
            _panel?.markNeedsBuild();
          },
          onSave: widget.onSave,
          onClose: _close,
          showTerrain: widget.showTerrain,
          showResources: widget.showResources,
          showHeightBadge: widget.showHeightBadge,
          showCitySites: widget.showCitySites,
          showCityGrowth: widget.showCityGrowth,
          showDiceRollTest: widget.showDiceRollTest,
          onToggleTerrain: () {
            widget.onToggleTerrain();
            _panel?.markNeedsBuild();
          },
          onToggleResources: () {
            widget.onToggleResources();
            _panel?.markNeedsBuild();
          },
          onToggleHeightBadge: () {
            widget.onToggleHeightBadge();
            _panel?.markNeedsBuild();
          },
          onToggleCitySites: () {
            widget.onToggleCitySites();
            _panel?.markNeedsBuild();
          },
          onToggleCityGrowth: () {
            widget.onToggleCityGrowth();
            _panel?.markNeedsBuild();
          },
          onToggleDiceRollTest: widget.onToggleDiceRollTest == null
              ? null
              : () {
                  widget.onToggleDiceRollTest!();
                  _panel?.markNeedsBuild();
                },
        ),
      ),
    );

    Overlay.of(context).insert(_barrier!);
    Overlay.of(context).insert(_panel!);
    setState(() {});
  }

  void _close() {
    _barrier?.remove();
    _panel?.remove();
    _barrier = null;
    _panel = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _barrier?.remove();
    _panel?.remove();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditorOptionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedulePanelRebuild();
  }

  void _schedulePanelRebuild() {
    if (!_open || _panelRebuildScheduled) return;
    _panelRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _panelRebuildScheduled = false;
      if (_open) _panel?.markNeedsBuild();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameUiOptionsButton(
      key: _buttonKey,
      open: _open,
      onPressed: _toggle,
    );
  }
}

class _OptionsPanel extends StatefulWidget {
  final MapViewMode viewMode;
  final bool allowGraphicMode;
  final ValueChanged<MapViewMode> onViewModeChanged;
  final VoidCallback onSave;
  final VoidCallback onClose;
  final bool showTerrain;
  final bool showResources;
  final bool showHeightBadge;
  final bool showCitySites;
  final bool showCityGrowth;
  final bool showDiceRollTest;
  final VoidCallback onToggleTerrain;
  final VoidCallback onToggleResources;
  final VoidCallback onToggleHeightBadge;
  final VoidCallback onToggleCitySites;
  final VoidCallback onToggleCityGrowth;
  final VoidCallback? onToggleDiceRollTest;

  const _OptionsPanel({
    required this.viewMode,
    required this.allowGraphicMode,
    required this.onViewModeChanged,
    required this.onSave,
    required this.onClose,
    required this.showTerrain,
    required this.showResources,
    required this.showHeightBadge,
    required this.showCitySites,
    required this.showCityGrowth,
    required this.showDiceRollTest,
    required this.onToggleTerrain,
    required this.onToggleResources,
    required this.onToggleHeightBadge,
    required this.onToggleCitySites,
    required this.onToggleCityGrowth,
    this.onToggleDiceRollTest,
  });

  @override
  State<_OptionsPanel> createState() => _OptionsPanelState();
}

class _OptionsPanelState extends State<_OptionsPanel> {
  bool _saving = false;

  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      widget.onSave();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameUiOptionsPanel(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: MapViewModeToggle(
            value: widget.viewMode,
            allowGraphicMode: widget.allowGraphicMode,
            onChanged: widget.onViewModeChanged,
          ),
        ),
        const SizedBox(height: 8),
        GameUiVisibilityRow(
          label: 'TERRAIN',
          value: widget.showTerrain,
          onToggle: widget.onToggleTerrain,
        ),
        const SizedBox(height: 4),
        GameUiVisibilityRow(
          label: 'RESOURCES',
          value: widget.showResources,
          onToggle: widget.onToggleResources,
        ),
        const SizedBox(height: 4),
        GameUiVisibilityRow(
          label: 'HEIGHT',
          value: widget.showHeightBadge,
          onToggle: widget.onToggleHeightBadge,
        ),
        const SizedBox(height: 4),
        GameUiVisibilityRow(
          label: 'CITY SITES',
          value: widget.showCitySites,
          onToggle: widget.onToggleCitySites,
        ),
        const SizedBox(height: 4),
        GameUiVisibilityRow(
          label: 'CITY GROWTH',
          value: widget.showCityGrowth,
          onToggle: widget.onToggleCityGrowth,
        ),
        if (widget.onToggleDiceRollTest case final toggle?) ...[
          const SizedBox(height: 4),
          GameUiVisibilityRow(
            label: 'DICE TEST',
            value: widget.showDiceRollTest,
            onToggle: toggle,
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _saving ? null : _handleSave,
            style: GameUiTheme.outlinedButtonStyle(
              foreground: GameUiTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(_saving ? '...' : 'SAVE'),
          ),
        ),
      ],
    );
  }
}
