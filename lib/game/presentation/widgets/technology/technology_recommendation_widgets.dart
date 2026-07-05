part of 'technology_recommendations_view.dart';

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          GameText.uppercase(title),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.toolbarLabel.copyWith(
            color: GameUiTheme.scienceAccent,
            fontSize: 9,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final GameIconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: color,
        backgroundAlpha: 24,
        borderColor: color,
        borderAlpha: 130,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIcon(icon, size: GameIconSize.tiny, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRecommendationsMessage extends StatelessWidget {
  const _NoRecommendationsMessage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 120,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(7),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          l10n.technologyNoRecommendations,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
