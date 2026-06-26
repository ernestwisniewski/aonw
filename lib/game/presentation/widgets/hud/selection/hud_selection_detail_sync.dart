import 'package:aonw/game/presentation/widgets/selection/view_models.dart';

class HudSelectionDetailSync {
  final bool closeUnsupportedDetail;

  const HudSelectionDetailSync({required this.closeUnsupportedDetail});

  factory HudSelectionDetailSync.fromSelection({
    required SelectionViewModel? selection,
    required String? openChipId,
  }) {
    final closeUnsupportedDetail =
        openChipId != null &&
        (selection == null ||
            !SelectionInfoChipsFactory.supportsChip(selection, openChipId));

    return HudSelectionDetailSync(
      closeUnsupportedDetail: closeUnsupportedDetail,
    );
  }
}
