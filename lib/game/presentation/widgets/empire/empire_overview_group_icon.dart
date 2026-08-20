part of 'empire_overview_entity_groups.dart';

class _EmpireGroupIcon extends StatelessWidget {
  const _EmpireGroupIcon({required this.icon, this.leading});

  final GameIconData icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.gold,
        backgroundAlpha: 28,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(5),
        includeShadow: false,
      ),
      child: Center(
        child:
            leading ??
            GameIcon(icon, size: GameIconSize.regular, color: GameUiTheme.gold),
      ),
    );
  }
}
