part of '../world_map_combat_boundary_test.dart';

const _interactionTargets = [
  _Target(
    path:
        'lib/game/domain/reducer/game_state/'
        'game_state_reducer_taps.dart',
    owner: 'GameIntentTapResolver',
    boundaries: [
      _Boundary.method(
        '_cityFoundingDraftTileTap',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_selectInspectionTileDuringResearch',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_shouldSelectTappedOwnUnitAfterMoveMiss',
        parameter: 'tile',
        type: 'MapTileView',
      ),
      _Boundary.method(
        '_selectTappedOwnUnit',
        parameter: 'tile',
        type: 'MapTileView',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/presentation/widgets/hud/city/'
        'hud_city_founding_availability.dart',
    owner: 'HudCityFoundingAvailability',
    boundaries: [
      _Boundary.method(
        'canStart',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/presentation/widgets/hud/overlay/'
        'hud_overlay_frame.dart',
    owner: 'HudOverlayFrame',
    boundaries: [
      _Boundary.method(
        '_cityFoundingBlockedReason',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/presentation/engine/game_hover_intent_resolver.dart',
    owner: 'GameHoverIntentResolver',
    boundaries: [
      _Boundary.constructor('', parameter: 'mapView', type: 'MapTraversalView'),
      _Boundary.method('resolve', parameter: 'tile', type: 'MapTileView'),
      _Boundary.method(
        '_moveHoverIntentForTile',
        parameter: 'tile',
        type: 'MapTileView',
      ),
      _Boundary.method(
        '_moveTargetBlockedForTile',
        parameter: 'tile',
        type: 'MapTileView',
      ),
      _Boundary.method(
        '_canCarryArtifactIntoTargetCity',
        parameter: 'targetTile',
        type: 'MapTileView',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/interaction/selection_reducer.dart',
    owner: 'SelectionReducer',
    boundaries: [
      _Boundary.method(
        'selectTile',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'selectUnit',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'selectCity',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'handleTileTapped',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'handleCityTapped',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/unit/domain_unit_detachment_resolver.dart',
    owner: 'DomainUnitDetachmentResolver',
    boundaries: [
      _Boundary.method(
        'detachTroop',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'packages/aonw_core/lib/game/domain/unit/detach_troop_resolver.dart',
    owner: 'DetachTroopResolver',
    boundaries: [
      _Boundary.method(
        'detachTroop',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
];
