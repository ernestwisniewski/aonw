import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/widgets/hud/notifications/game_event_notification_thumbnail.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class GameEventNotificationCard extends StatelessWidget {
  final GameEventNotificationMessage message;
  final bool dismissing;
  final Duration fadeDuration;
  final bool showDetails;
  final int? maxDetailCount;
  final VoidCallback? onTap;

  const GameEventNotificationCard({
    required this.message,
    required this.dismissing,
    required this.fadeDuration,
    this.showDetails = true,
    this.maxDetailCount,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final visibleDetails = !showDetails
        ? const <String>[]
        : maxDetailCount == null
        ? message.details
        : message.details.take(maxDetailCount!).toList(growable: false);

    return AnimatedSlide(
      offset: dismissing ? const Offset(0, -0.08) : Offset.zero,
      duration: fadeDuration,
      curve: GameMotion.exit,
      child: AnimatedOpacity(
        opacity: dismissing ? 0 : 1,
        duration: fadeDuration,
        curve: GameMotion.exit,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: GameUiTheme.cardBorderRadius,
            child: InkWell(
              onTap: onTap,
              borderRadius: GameUiTheme.cardBorderRadius,
              child: Container(
                width: double.infinity,
                decoration: SurfaceElevation.raised.decoration(
                  accent: GameUiTheme.gold,
                  border: BorderEmphasis.regular,
                  borderRadius: GameUiTheme.cardBorderRadius,
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.thumbnail != null) ...[
                      GameEventNotificationThumbnailView(
                        thumbnail: message.thumbnail!,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GameUiTheme.sectionHeader.copyWith(
                              color: GameUiTheme.goldLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GameUiTheme.bodySmall.copyWith(
                              color: GameUiTheme.textPrimary,
                            ),
                          ),
                          if (visibleDetails.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final maxWidth = constraints.maxWidth;
                                return Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final detail in visibleDetails)
                                      _NotificationDetailPill(
                                        detail,
                                        maxWidth: maxWidth,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailPill extends StatelessWidget {
  final String text;
  final double maxWidth;

  const _NotificationDetailPill(this.text, {required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: SurfaceElevation.flat.decoration(
          background: GameUiTheme.chipSurface,
          accent: GameUiTheme.gold,
          border: BorderEmphasis.subtle,
          borderRadius: GameUiTheme.pillBorderRadius,
          includeShadow: false,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.chipLabel.copyWith(
              color: GameUiTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
