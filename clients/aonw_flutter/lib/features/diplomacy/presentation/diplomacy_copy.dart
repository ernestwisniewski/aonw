import 'package:flutter/widgets.dart';

import '../application/diplomacy_state.dart';

final class DiplomacyCopy {
  const DiplomacyCopy._(this.polish);

  factory DiplomacyCopy.of(BuildContext context) =>
      DiplomacyCopy._(Localizations.localeOf(context).languageCode == 'pl');

  final bool polish;

  String get title => polish ? 'Dyplomacja' : 'Diplomacy';
  String get open => polish ? 'Otwórz dyplomację' : 'Open diplomacy';
  String get close => polish ? 'Zamknij dyplomację' : 'Close diplomacy';
  String get noContacts => polish ? 'Brak kontaktów' : 'No contacts';
  String get compose => polish ? 'Nowa akcja' : 'New action';
  String get target => polish ? 'Kontrahent' : 'Counterpart';
  String get action => polish ? 'Akcja' : 'Action';
  String get send => polish ? 'Wyślij' : 'Send';
  String get invalid =>
      polish ? 'Sprawdź warunki formularza.' : 'Review the form terms.';
  String get pending =>
      polish ? 'Wysyłanie akcji dyplomatycznej' : 'Sending diplomacy action';
  String get relations => polish ? 'Relacje' : 'Relations';
  String get proposals => polish ? 'Propozycje' : 'Proposals';
  String get messages => polish ? 'Wiadomości prywatne' : 'Private messages';
  String get agreements => polish ? 'Umowy zasobowe' : 'Resource agreements';
  String get accept => polish ? 'Akceptuj' : 'Accept';
  String get reject => polish ? 'Odrzuć' : 'Reject';
  String get amount => polish ? 'Kwota' : 'Amount';
  String get goldPerTurn => polish ? 'Złoto na turę' : 'Gold per turn';
  String get duration => polish ? 'Liczba tur' : 'Turns';
  String get resource => polish ? 'Zasób' : 'Resource';
  String get offered => polish ? 'Oferowany zasób' : 'Offered resource';
  String get requested => polish ? 'Żądany zasób' : 'Requested resource';
  String get topic => polish ? 'Temat' : 'Topic';

  String name(Enum value) => value.name
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)!.toLowerCase()}',
      )
      .replaceFirstMapped(
        RegExp(r'^.'),
        (match) => match.group(0)!.toUpperCase(),
      );

  String failure(DiplomacyFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    if (!polish) {
      return _englishFailures[key] ?? _englishFailures['requestFailed']!;
    }
    return _polishFailures[key] ?? _polishFailures['requestFailed']!;
  }
}

const _englishFailures = <String, String>{
  'requestFailed': 'The diplomacy request could not be completed.',
  'responseIncompatible': 'The diplomacy response is incompatible.',
  'sessionUnavailable': 'The local game session is unavailable.',
  'staleRevision': 'Diplomacy changed. Review the current state and try again.',
  'matchFinished': 'The match has already finished.',
  'diplomacyPlayerNotControlled': 'This player cannot issue diplomacy actions.',
  'diplomacyTargetNotDiscovered': 'This counterpart is not available.',
  'diplomacyProposalNotAllowed': 'This proposal is not allowed.',
  'diplomacyDuplicateProposal': 'This proposal already exists.',
  'diplomacyProposalNotFound': 'This proposal no longer exists.',
  'diplomacyProposalPaymentUnavailable': 'The proposal payment is unavailable.',
  'diplomacyMessageCooldown': 'A similar message was sent too recently.',
  'diplomacyDuplicateMessage': 'This message already exists.',
  'diplomacyMessageNotFound': 'This message no longer exists.',
  'diplomacyMessageUnavailable': 'This message cannot be used now.',
  'diplomacyTruceActive': 'A truce is active.',
  'diplomacyWarAlreadyActive': 'War is already active.',
  'diplomacyInvalidGoldAmount': 'The gold amount is invalid.',
  'diplomacyGoldGiftBlockedByRelation': 'This relation blocks gold gifts.',
  'diplomacyGoldUnavailable': 'The required gold is unavailable.',
  'diplomacyGoldGiftUnavailable': 'This gold gift is unavailable.',
  'invalidResourceTradeTarget': 'The resource trade target is invalid.',
  'invalidResourceTradeResource': 'The selected resource is invalid.',
  'invalidResourceTradeTerms': 'The resource trade terms are invalid.',
  'resourceTradeBlockedByWar': 'War blocks this resource trade.',
  'resourceTradeGoldUnavailable': 'Trade gold is unavailable.',
  'resourceTradeAlreadyActive': 'This resource trade is already active.',
  'invalidResourceTradeAgreementId': 'The agreement identity is invalid.',
  'resourceTradeAgreementIdConflict': 'The agreement identity conflicts.',
  'resourceTradeExportUnavailable': 'The resource export is unavailable.',
  'resourceTradeOfferUnavailable': 'The offered resource is unavailable.',
  'resourceTradeRequestUnavailable': 'The requested resource is unavailable.',
  'stateRevisionOverflow': 'The game state cannot advance further.',
};

const _polishFailures = <String, String>{
  'requestFailed': 'Nie udało się wykonać akcji dyplomatycznej.',
  'responseIncompatible': 'Odpowiedź dyplomacji jest niezgodna z klientem.',
  'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
  'staleRevision': 'Stan dyplomacji się zmienił. Sprawdź go ponownie.',
  'matchFinished': 'Rozgrywka już się zakończyła.',
  'diplomacyPlayerNotControlled': 'Ten gracz nie może prowadzić dyplomacji.',
  'diplomacyTargetNotDiscovered': 'Ten kontrahent jest niedostępny.',
  'diplomacyProposalNotAllowed': 'Ta propozycja jest niedozwolona.',
  'diplomacyDuplicateProposal': 'Taka propozycja już istnieje.',
  'diplomacyProposalNotFound': 'Ta propozycja już nie istnieje.',
  'diplomacyProposalPaymentUnavailable':
      'Płatność propozycji jest niedostępna.',
  'diplomacyMessageCooldown': 'Podobną wiadomość wysłano zbyt niedawno.',
  'diplomacyDuplicateMessage': 'Taka wiadomość już istnieje.',
  'diplomacyMessageNotFound': 'Ta wiadomość już nie istnieje.',
  'diplomacyMessageUnavailable': 'Tej wiadomości nie można teraz użyć.',
  'diplomacyTruceActive': 'Obowiązuje rozejm.',
  'diplomacyWarAlreadyActive': 'Wojna już trwa.',
  'diplomacyInvalidGoldAmount': 'Kwota złota jest nieprawidłowa.',
  'diplomacyGoldGiftBlockedByRelation': 'Ta relacja blokuje dar złota.',
  'diplomacyGoldUnavailable': 'Wymagane złoto jest niedostępne.',
  'diplomacyGoldGiftUnavailable': 'Ten dar złota jest niedostępny.',
  'invalidResourceTradeTarget': 'Cel handlu zasobami jest nieprawidłowy.',
  'invalidResourceTradeResource': 'Wybrany zasób jest nieprawidłowy.',
  'invalidResourceTradeTerms': 'Warunki handlu zasobami są nieprawidłowe.',
  'resourceTradeBlockedByWar': 'Wojna blokuje ten handel zasobami.',
  'resourceTradeGoldUnavailable': 'Złoto dla handlu jest niedostępne.',
  'resourceTradeAlreadyActive': 'Taki handel zasobami już trwa.',
  'invalidResourceTradeAgreementId': 'Identyfikator umowy jest nieprawidłowy.',
  'resourceTradeAgreementIdConflict': 'Identyfikator umowy jest zajęty.',
  'resourceTradeExportUnavailable': 'Eksport zasobu jest niedostępny.',
  'resourceTradeOfferUnavailable': 'Oferowany zasób jest niedostępny.',
  'resourceTradeRequestUnavailable': 'Żądany zasób jest niedostępny.',
  'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
};
