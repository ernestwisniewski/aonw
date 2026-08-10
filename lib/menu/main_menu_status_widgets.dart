part of 'main_menu_screen.dart';

final _feedbackUrl = Uri.parse('https://www.reddit.com/r/aonw/');

class _BottomLink {
  const _BottomLink(this.icon, this.label, this.onPressed);

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

Future<void> _openFeedbackUrl() async {
  await launchUrl(_feedbackUrl, mode: LaunchMode.externalApplication);
}

class _VersionTag extends ConsumerWidget {
  const _VersionTag();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseInfo = ref.watch(appReleaseInfoProvider);
    final label = releaseInfo.maybeWhen(
      data: (info) => info.displayLabel,
      orElse: () => AppReleaseChannel.stable.label,
    );
    return Text(
      label,
      style: GameUiTheme.bodySmall.copyWith(
        color: GameUiTheme.goldLight.withAlpha(120),
        fontSize: 11,
      ),
    );
  }
}

class _RightInfoColumn extends StatelessWidget {
  const _RightInfoColumn();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 700) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [_WhatsNewPanel(), SizedBox(height: 10), _BottomLinks()],
      ),
    );
  }
}

class _UpdateNoticeBlock extends StatelessWidget {
  const _UpdateNoticeBlock({required this.notice});

  final MainMenuUpdateNotice notice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const color = GameUiTheme.goldLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.system_update_alt_rounded, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameText.sectionLabel(notice.title(l10n)),
                style: GameUiTheme.sectionHeader.copyWith(color: color),
              ),
              const SizedBox(height: 5),
              Text(
                notice.body(l10n),
                style: GameUiTheme.body.copyWith(
                  color: GameUiTheme.goldLight,
                  fontSize: 11.5,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

MainMenuUpdateNotice? _updateNoticeFor(WidgetRef ref) {
  final notice = ref.watch(mainMenuUpdateNoticeProvider);
  return notice is AsyncData<MainMenuUpdateNotice?> ? notice.value : null;
}
