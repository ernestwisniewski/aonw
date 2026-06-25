part of 'lobby_screen.dart';

class _LobbyPlayerRow extends StatelessWidget {
  static const double _compactBreakpoint = 620;
  static const double _countryControlWidth = 176;
  static const double _kindControlWidth = 132;

  final int index;
  final TextEditingController nameController;
  final String nameHint;
  final Widget countryControl;
  final Widget kindControl;
  final bool showKindControl;
  final bool canRemove;
  final ValueChanged<String> onNameChanged;
  final VoidCallback? onRemove;

  const _LobbyPlayerRow({
    required this.index,
    required this.nameController,
    required this.nameHint,
    required this.countryControl,
    required this.kindControl,
    required this.showKindControl,
    required this.canRemove,
    required this.onNameChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < _compactBreakpoint;
          final identityRow = _LobbyPlayerIdentityRow(
            index: index,
            nameController: nameController,
            nameHint: nameHint,
            showRemoveButton: canRemove && compact,
            onNameChanged: onNameChanged,
            onRemove: onRemove,
          );

          return compact
              ? _buildCompactLayout(identityRow)
              : _buildWideLayout(identityRow);
        },
      ),
    );
  }

  Widget _buildCompactLayout(Widget identityRow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        identityRow,
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: countryControl),
            if (showKindControl) ...[
              const SizedBox(width: 8),
              SizedBox(width: _kindControlWidth, child: kindControl),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildWideLayout(Widget identityRow) {
    return Row(
      children: [
        Expanded(child: identityRow),
        const SizedBox(width: 8),
        SizedBox(width: _countryControlWidth, child: countryControl),
        if (showKindControl) ...[
          const SizedBox(width: 8),
          SizedBox(width: _kindControlWidth, child: kindControl),
        ],
        if (canRemove) ...[
          const SizedBox(width: 8),
          _LobbyRemovePlayerButton(onPressed: onRemove),
        ],
      ],
    );
  }
}

class _LobbyPlayerIdentityRow extends StatelessWidget {
  final int index;
  final TextEditingController nameController;
  final String nameHint;
  final bool showRemoveButton;
  final ValueChanged<String> onNameChanged;
  final VoidCallback? onRemove;

  const _LobbyPlayerIdentityRow({
    required this.index,
    required this.nameController,
    required this.nameHint,
    required this.showRemoveButton,
    required this.onNameChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LobbyPlayerNumberBadge(index: index),
        const SizedBox(width: 12),
        Expanded(
          child: _LobbyTextField(
            controller: nameController,
            hintText: nameHint,
            onChanged: onNameChanged,
          ),
        ),
        if (showRemoveButton) _LobbyRemovePlayerButton(onPressed: onRemove),
      ],
    );
  }
}

class _LobbyPlayerNumberBadge extends StatelessWidget {
  final int index;

  const _LobbyPlayerNumberBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    final color = Color(Player.palette[index % Player.palette.length]);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LobbyRemovePlayerButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _LobbyRemovePlayerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.close, size: 16),
      color: GameUiTheme.textSecondary,
      visualDensity: VisualDensity.compact,
      tooltip: AppLocalizations.of(context).removePlayerTooltip,
    );
  }
}
