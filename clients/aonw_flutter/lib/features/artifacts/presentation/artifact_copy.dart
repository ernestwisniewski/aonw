import 'package:flutter/widgets.dart';

import '../../map/read_model/player_map_view.dart';
import '../application/artifact_state.dart';
import '../read_model/artifact_view.dart';

enum ArtifactText {
  title,
  executing,
  startExcavation,
  storeInCity,
  trade,
  targetPlayer,
  offeredGold,
  onMap,
  carried,
  stored,
  excavation,
  turnsRemaining,
}

final class ArtifactCopy {
  const ArtifactCopy._(this._texts, this._failures, this._artifactNames);

  factory ArtifactCopy.of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'pl'
      ? const ArtifactCopy._(_polishText, _polishFailures, _polishArtifactNames)
      : const ArtifactCopy._(
          _englishText,
          _englishFailures,
          _englishArtifactNames,
        );

  final Map<ArtifactText, String> _texts;
  final Map<String, String> _failures;
  final Map<WorldArtifactKindView, String> _artifactNames;

  String text(ArtifactText key) => _texts[key]!;

  String artifactName(WorldArtifactKindView kind) => _artifactNames[kind]!;

  String location(ArtifactLocationView location, PlayerMapView player) =>
      switch (location) {
        MapArtifactLocationView(:final coordinate) =>
          '${text(ArtifactText.onMap)} '
              '${coordinate.col}, ${coordinate.row}',
        CarriedArtifactLocationView(:final unitId) =>
          '${text(ArtifactText.carried)} '
              '${player.controlledUnitById(unitId)?.name ?? unitId}',
        StoredArtifactLocationView(:final cityId) =>
          '${text(ArtifactText.stored)} '
              '${player.cityById(cityId)?.name ?? cityId}',
        ExcavationArtifactLocationView(
          :final coordinate,
          :final remainingTurns,
        ) =>
          '${text(ArtifactText.excavation)} '
              '${coordinate.col}, ${coordinate.row} · '
              '$remainingTurns ${text(ArtifactText.turnsRemaining)}',
      };

  String failure(ArtifactFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    return _failures[key] ?? _failures['requestFailed']!;
  }
}

const _englishText = <ArtifactText, String>{
  ArtifactText.title: 'World artifacts',
  ArtifactText.executing: 'Applying artifact action',
  ArtifactText.startExcavation: 'Start excavation',
  ArtifactText.storeInCity: 'Store in city',
  ArtifactText.trade: 'Trade artifact',
  ArtifactText.targetPlayer: 'Target player',
  ArtifactText.offeredGold: 'Offered gold',
  ArtifactText.onMap: 'On map at',
  ArtifactText.carried: 'Carried by',
  ArtifactText.stored: 'Stored in',
  ArtifactText.excavation: 'Excavation at',
  ArtifactText.turnsRemaining: 'turns remaining',
};

const _polishText = <ArtifactText, String>{
  ArtifactText.title: 'Artefakty świata',
  ArtifactText.executing: 'Wykonywanie akcji artefaktu',
  ArtifactText.startExcavation: 'Rozpocznij wykopaliska',
  ArtifactText.storeInCity: 'Umieść w mieście',
  ArtifactText.trade: 'Wymień artefakt',
  ArtifactText.targetPlayer: 'Gracz docelowy',
  ArtifactText.offeredGold: 'Oferowane złoto',
  ArtifactText.onMap: 'Na mapie',
  ArtifactText.carried: 'Niesiony przez',
  ArtifactText.stored: 'Przechowywany w',
  ArtifactText.excavation: 'Wykopaliska',
  ArtifactText.turnsRemaining: 'tur pozostało',
};

const _englishArtifactNames = <WorldArtifactKindView, String>{
  WorldArtifactKindView.ancientImperialCrown: 'Ancient Imperial Crown',
  WorldArtifactKindView.astronomersTablets: "Astronomer's Tablets",
  WorldArtifactKindView.prophetMask: "Prophet's Mask",
  WorldArtifactKindView.heroSword: "Hero's Sword",
  WorldArtifactKindView.merchantsSeal: "Merchant's Seal",
  WorldArtifactKindView.firstPeoplesChronicle: "First People's Chronicle",
  WorldArtifactKindView.templeReliquary: 'Temple Reliquary',
  WorldArtifactKindView.queensMirror: "Queen's Mirror",
};

const _polishArtifactNames = <WorldArtifactKindView, String>{
  WorldArtifactKindView.ancientImperialCrown: 'Starożytna korona cesarska',
  WorldArtifactKindView.astronomersTablets: 'Tablice astronoma',
  WorldArtifactKindView.prophetMask: 'Maska proroka',
  WorldArtifactKindView.heroSword: 'Miecz bohatera',
  WorldArtifactKindView.merchantsSeal: 'Pieczęć kupca',
  WorldArtifactKindView.firstPeoplesChronicle: 'Kronika pierwszych ludów',
  WorldArtifactKindView.templeReliquary: 'Relikwiarz świątynny',
  WorldArtifactKindView.queensMirror: 'Lustro królowej',
};

const _englishFailures = <String, String>{
  'requestFailed': 'The artifact request could not be completed.',
  'responseIncompatible': 'The artifact response is incompatible.',
  'sessionUnavailable': 'The local game session is unavailable.',
  'staleRevision': 'The game state changed. Review the artifact and try again.',
  'matchFinished': 'The match has already finished.',
  'unitNotFound': 'The unit is no longer available.',
  'unitNotControlled': 'The unit is not controlled by this player.',
  'unitUnavailable': 'The unit is unavailable.',
  'unitAlreadyCarryingArtifact': 'The unit already carries an artifact.',
  'artifactNotFound': 'The artifact is no longer available.',
  'unitNotCarryingArtifact': 'The unit is not carrying an artifact.',
  'cityNotFound': 'The city is no longer available.',
  'cityNotControlled': 'The city is not controlled by this player.',
  'unitNotInCity': 'The unit is not in that city.',
  'cityArtifactSlotFull': 'The city artifact slot is full.',
  'artifactTradeActorUnavailable': 'This player cannot trade artifacts.',
  'artifactTradeTargetInvalid': 'The target player is invalid.',
  'artifactTradeGoldInvalid': 'The gold offer is invalid.',
  'artifactTradeBlockedByWar': 'Artifact trade is blocked by war.',
  'artifactTradeGoldUnavailable': 'The offered gold is unavailable.',
  'offeredArtifactUnavailable': 'The offered artifact is unavailable.',
  'targetArtifactSlotUnavailable': 'The target has no artifact slot.',
  'stateRevisionOverflow': 'The game state cannot advance further.',
};

const _polishFailures = <String, String>{
  'requestFailed': 'Nie udało się wykonać żądania artefaktu.',
  'responseIncompatible': 'Odpowiedź artefaktu jest niezgodna z klientem.',
  'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
  'staleRevision': 'Stan gry uległ zmianie. Sprawdź artefakt ponownie.',
  'matchFinished': 'Rozgrywka już się zakończyła.',
  'unitNotFound': 'Jednostka nie jest już dostępna.',
  'unitNotControlled': 'Jednostka nie należy do tego gracza.',
  'unitUnavailable': 'Jednostka jest niedostępna.',
  'unitAlreadyCarryingArtifact': 'Jednostka już niesie artefakt.',
  'artifactNotFound': 'Artefakt nie jest już dostępny.',
  'unitNotCarryingArtifact': 'Jednostka nie niesie artefaktu.',
  'cityNotFound': 'Miasto nie jest już dostępne.',
  'cityNotControlled': 'Miasto nie należy do tego gracza.',
  'unitNotInCity': 'Jednostka nie znajduje się w tym mieście.',
  'cityArtifactSlotFull': 'Miejsce na artefakt w mieście jest zajęte.',
  'artifactTradeActorUnavailable': 'Ten gracz nie może wymieniać artefaktów.',
  'artifactTradeTargetInvalid': 'Gracz docelowy jest nieprawidłowy.',
  'artifactTradeGoldInvalid': 'Oferta złota jest nieprawidłowa.',
  'artifactTradeBlockedByWar':
      'Wymiana artefaktów jest zablokowana przez wojnę.',
  'artifactTradeGoldUnavailable': 'Oferowane złoto jest niedostępne.',
  'offeredArtifactUnavailable': 'Oferowany artefakt jest niedostępny.',
  'targetArtifactSlotUnavailable': 'Gracz docelowy nie ma miejsca na artefakt.',
  'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
};
