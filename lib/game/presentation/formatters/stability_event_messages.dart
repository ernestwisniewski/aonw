import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/formatters/stability_band_presentation.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/stability.dart';

/// Builds the player-facing notification for a stability band change.
GameEventNotificationMessage stabilityBandChangedMessage({
  required AppLocalizations l10n,
  required String playerName,
  required StabilityBand newBand,
  required int net,
}) {
  return GameEventNotificationMessage(
    title: l10n.eventStabilityBandChangedTitle,
    body: l10n.eventStabilityBandChangedBody(
      playerName,
      StabilityBandPresentation.label(l10n, newBand),
      net,
    ),
    thumbnail: IconEventNotificationThumbnail(
      newBand == StabilityBand.strained || newBand == StabilityBand.unrest
          ? EventNotificationIconThumbnailKind.warning
          : EventNotificationIconThumbnailKind.success,
    ),
  );
}
