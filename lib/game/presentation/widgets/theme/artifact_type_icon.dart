import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw_core/game/domain/artifact.dart';

/// Canonical artifact glyphs shared by map markers, radial selection and
/// artifact popups. Coordinates preserve the original 24x24 marker artwork.
GameIconData gameIconForArtifactType(WorldArtifactType type) => switch (type) {
  WorldArtifactType.ancientImperialCrown => _artifactCrown,
  WorldArtifactType.astronomersTablets => _artifactStar,
  WorldArtifactType.prophetMask => _artifactMask,
  WorldArtifactType.heroSword => _artifactSword,
  WorldArtifactType.merchantsSeal => _artifactSeal,
  WorldArtifactType.firstPeoplesChronicle => _artifactBook,
  WorldArtifactType.templeReliquary => _artifactReliquary,
  WorldArtifactType.queensMirror => _artifactMirror,
};

const _artifactCrown = GameIconData(
  paths: ['M6 15.5L7.3 8.6L10.7 12.8L14 6.8L17.4 12.8L18 15.5L6 15.5'],
  strokeWidth: 1.55,
);

const _artifactStar = GameIconData(
  paths: [
    'M12 5.6L13.7 10.3L18.4 12L13.7 13.7L12 18.4L10.3 13.7L5.6 12L10.3 10.3Z',
  ],
  strokeWidth: 1.55,
);

const _artifactMask = GameIconData(
  paths: [
    'M18 12A6 4.9 0 1 1 6 12A6 4.9 0 1 1 18 12Z',
    'M8.4 11.3L10.6 11.3',
    'M13.4 11.3L15.6 11.3',
    'M9.2 15.3Q12 17.2 14.8 15.3',
  ],
  strokeWidth: 1.55,
);

const _artifactSword = GameIconData(
  paths: [
    'M12 18.3L12 6.3',
    'M9.2 9.2L12 5.6L14.8 9.2',
    'M7 14.1L17 14.1',
    'M9.9 18.3L14.1 18.3',
  ],
  strokeWidth: 1.55,
);

const _artifactSeal = GameIconData(
  paths: [
    'M18 12A6 6 0 1 1 6 12A6 6 0 1 1 18 12Z',
    'M8.4 12L15.6 12',
    'M12 8.4L12 15.6',
  ],
  strokeWidth: 1.55,
);

const _artifactBook = GameIconData(
  paths: [
    'M5.8 6.4L11.2 8.5L11.2 17.6L5.8 15.5ZM18.2 6.4L12.8 8.5L12.8 17.6L18.2 15.5Z',
  ],
  strokeWidth: 1.55,
);

const _artifactReliquary = GameIconData(
  paths: ['M12 5.7L12 18.3', 'M7 10.6L17 10.6', 'M8.5 17.6L15.5 17.6'],
  strokeWidth: 1.55,
);

const _artifactMirror = GameIconData(
  paths: [
    'M16.9 10.6A4.9 5.6 0 1 1 7.1 10.6A4.9 5.6 0 1 1 16.9 10.6Z',
    'M12 16.2L12 19',
    'M9.2 19L14.8 19',
  ],
  strokeWidth: 1.55,
);
