import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class MapSelectionTile extends StatelessWidget {
  final MapSelection map;
  final String actionLabel;
  final VoidCallback onTap;

  const MapSelectionTile({
    required this.map,
    required this.onTap,
    this.actionLabel = 'OPEN',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GameUiTheme.card,
      borderRadius: GameUiTheme.borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: GameUiTheme.borderRadius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            final content = [
              _MapBadge(source: map.source),
              const SizedBox(width: 12, height: 12),
              Expanded(child: _MapText(map: map)),
              if (!compact) ...[
                const SizedBox(width: 12),
                _MapAction(label: actionLabel),
              ],
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: content),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _MapAction(label: actionLabel),
                        ),
                      ],
                    )
                  : Row(children: content),
            );
          },
        ),
      ),
    );
  }
}

class _MapText extends StatelessWidget {
  final MapSelection map;

  const _MapText({required this.map});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          map.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.cardTitle,
        ),
        const SizedBox(height: 4),
        Text(
          map.sourceLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.cardMeta,
        ),
      ],
    );
  }
}

class _MapBadge extends StatelessWidget {
  final MapSource source;

  const _MapBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final official = source == MapSource.asset;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.gold.withAlpha(official ? 22 : 34),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.gold.withAlpha(120)),
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(
          official ? Icons.public_outlined : Icons.edit_location_alt_outlined,
          size: 19,
          color: GameUiTheme.goldLight,
        ),
      ),
    );
  }
}

class _MapAction extends StatelessWidget {
  final String label;

  const _MapAction({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.surface.withAlpha(210),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.gold.withAlpha(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GameUiTheme.actionLabel.copyWith(
                color: GameUiTheme.goldLight,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: GameUiTheme.goldLight,
            ),
          ],
        ),
      ),
    );
  }
}
