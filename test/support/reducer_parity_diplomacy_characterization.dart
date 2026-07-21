import 'package:aonw_core/domain.dart';

import 'reducer_parity_fixture.dart';

part 'reducer_parity_diplomacy_characterization_fixture.dart';
part 'reducer_parity_diplomacy_message_cases.dart';
part 'reducer_parity_diplomacy_oracle.dart';
part 'reducer_parity_diplomacy_proposal_cases.dart';
part 'reducer_parity_diplomacy_war_gift_cases.dart';

abstract final class DiplomacyReducerParityCharacterization {
  static List<ReducerParityFixture> extend(List<ReducerParityFixture> corpus) {
    final template = corpus.singleWhere(
      (fixture) => fixture.id == 'resource-trade-gold-accepted',
    );
    final baseState = _diplomacyParityBaseState(template.state);
    final characterization = [
      ..._proposalParityCases(template, baseState),
      ..._warAndGiftParityCases(template, baseState),
      ..._messageParityCases(template, baseState),
    ];
    _requireExactDiplomacyCharacterization(characterization);
    final ids = <String>{for (final fixture in corpus) fixture.id};
    for (final fixture in characterization) {
      if (!ids.add(fixture.id)) {
        throw StateError('Duplicate diplomacy parity id: ${fixture.id}.');
      }
    }
    return List.unmodifiable([...corpus, ...characterization]);
  }

  static void validateForTest(List<ReducerParityFixture> fixtures) {
    _requireExactDiplomacyCharacterization(fixtures);
  }
}

typedef _DiplomacyRequirement = ({String mode, bool accepted, String? reason});

const _requiredDiplomacyCharacterization = <String, _DiplomacyRequirement>{
  'diplomacy-characterization-proposal-send-wrong-actor-rejected': (
    mode: 'proposal-send',
    accepted: false,
    reason: 'diplomacy_player_not_controlled',
  ),
  'diplomacy-characterization-proposal-send-target-rejected': (
    mode: 'proposal-send',
    accepted: false,
    reason: 'diplomacy_target_not_discovered',
  ),
  'diplomacy-characterization-proposal-send-not-allowed-rejected': (
    mode: 'proposal-send',
    accepted: false,
    reason: 'diplomacy_proposal_not_allowed',
  ),
  'diplomacy-characterization-proposal-send-duplicate-rejected': (
    mode: 'proposal-send',
    accepted: false,
    reason: 'diplomacy_duplicate_proposal',
  ),
  'diplomacy-characterization-proposal-send-generated-id-accepted': (
    mode: 'proposal-send',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-proposal-send-paid-truce-accepted': (
    mode: 'proposal-send',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-proposal-response-wrong-actor-rejected': (
    mode: 'proposal-response',
    accepted: false,
    reason: 'diplomacy_player_not_controlled',
  ),
  'diplomacy-characterization-proposal-response-not-found-rejected': (
    mode: 'proposal-response',
    accepted: false,
    reason: 'diplomacy_proposal_not_found',
  ),
  'diplomacy-characterization-proposal-response-payment-rejected': (
    mode: 'proposal-response',
    accepted: false,
    reason: 'diplomacy_proposal_payment_unavailable',
  ),
  'diplomacy-characterization-proposal-response-declined-accepted': (
    mode: 'proposal-response',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-proposal-response-friendship-accepted': (
    mode: 'proposal-response',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-proposal-response-paid-truce-accepted': (
    mode: 'proposal-response',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-war-wrong-actor-rejected': (
    mode: 'war',
    accepted: false,
    reason: 'diplomacy_player_not_controlled',
  ),
  'diplomacy-characterization-war-target-rejected': (
    mode: 'war',
    accepted: false,
    reason: 'diplomacy_target_not_discovered',
  ),
  'diplomacy-characterization-war-active-truce-rejected': (
    mode: 'war',
    accepted: false,
    reason: 'diplomacy_truce_active',
  ),
  'diplomacy-characterization-war-already-active-rejected': (
    mode: 'war',
    accepted: false,
    reason: 'diplomacy_war_already_active',
  ),
  'diplomacy-characterization-war-expired-truce-accepted': (
    mode: 'war',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-war-selective-effects-accepted': (
    mode: 'war',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-gift-wrong-actor-rejected': (
    mode: 'gift',
    accepted: false,
    reason: 'diplomacy_player_not_controlled',
  ),
  'diplomacy-characterization-gift-target-rejected': (
    mode: 'gift',
    accepted: false,
    reason: 'diplomacy_target_not_discovered',
  ),
  'diplomacy-characterization-gift-negative-rejected': (
    mode: 'gift',
    accepted: false,
    reason: 'diplomacy_invalid_gold_amount',
  ),
  'diplomacy-characterization-gift-relation-rejected': (
    mode: 'gift',
    accepted: false,
    reason: 'diplomacy_gold_gift_blocked_by_relation',
  ),
  'diplomacy-characterization-gift-gold-rejected': (
    mode: 'gift',
    accepted: false,
    reason: 'diplomacy_gold_unavailable',
  ),
  'diplomacy-characterization-gift-below-minimum-rejected': (
    mode: 'gift',
    accepted: false,
    reason: 'diplomacy_gold_gift_unavailable',
  ),
  'diplomacy-characterization-gift-cooldown-rejected': (
    mode: 'gift',
    accepted: false,
    reason: 'diplomacy_gold_gift_unavailable',
  ),
  'diplomacy-characterization-gift-transfer-accepted': (
    mode: 'gift',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-message-send-wrong-actor-rejected': (
    mode: 'message-send',
    accepted: false,
    reason: 'diplomacy_player_not_controlled',
  ),
  'diplomacy-characterization-message-send-target-rejected': (
    mode: 'message-send',
    accepted: false,
    reason: 'diplomacy_target_not_discovered',
  ),
  'diplomacy-characterization-message-send-cooldown-rejected': (
    mode: 'message-send',
    accepted: false,
    reason: 'diplomacy_message_cooldown',
  ),
  'diplomacy-characterization-message-send-generated-id-accepted': (
    mode: 'message-send',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-message-response-wrong-actor-rejected': (
    mode: 'message-response',
    accepted: false,
    reason: 'diplomacy_player_not_controlled',
  ),
  'diplomacy-characterization-message-response-not-found-rejected': (
    mode: 'message-response',
    accepted: false,
    reason: 'diplomacy_message_not_found',
  ),
  'diplomacy-characterization-message-response-responded-rejected': (
    mode: 'message-response',
    accepted: false,
    reason: 'diplomacy_message_unavailable',
  ),
  'diplomacy-characterization-message-response-expired-rejected': (
    mode: 'message-response',
    accepted: false,
    reason: 'diplomacy_message_unavailable',
  ),
  'diplomacy-characterization-message-response-conciliatory-accepted': (
    mode: 'message-response',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-message-response-neutral-accepted': (
    mode: 'message-response',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-message-response-evasive-accepted': (
    mode: 'message-response',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-message-response-aggressive-accepted': (
    mode: 'message-response',
    accepted: true,
    reason: null,
  ),
  'diplomacy-characterization-message-response-common-enemy-accepted': (
    mode: 'message-response',
    accepted: true,
    reason: null,
  ),
};

void _requireExactDiplomacyCharacterization(
  List<ReducerParityFixture> fixtures,
) {
  final actualIds = {for (final fixture in fixtures) fixture.id};
  final requiredIds = _requiredDiplomacyCharacterization.keys.toSet();
  if (actualIds.length != fixtures.length ||
      !actualIds.containsAll(requiredIds) ||
      !requiredIds.containsAll(actualIds)) {
    throw StateError('Diplomacy parity characterization is incomplete.');
  }
  for (final fixture in fixtures) {
    final required = _requiredDiplomacyCharacterization[fixture.id]!;
    if (_diplomacyMode(fixture.command) != required.mode ||
        fixture.expectedAccepted != required.accepted ||
        fixture.expectedReason != required.reason ||
        (required.accepted && fixture.expectedEvents.isEmpty) ||
        (!required.accepted && fixture.expectedEvents.isNotEmpty)) {
      throw StateError(
        'Diplomacy parity characterization drifted: ${fixture.id}.',
      );
    }
  }
}

String _diplomacyMode(GameCommand command) => switch (command) {
  SendDiplomaticProposalCommand() => 'proposal-send',
  RespondDiplomaticProposalCommand() => 'proposal-response',
  DeclareWarCommand() => 'war',
  SendGoldGiftCommand() => 'gift',
  SendDiplomaticMessageCommand() => 'message-send',
  RespondDiplomaticMessageCommand() => 'message-response',
  _ => 'unexpected',
};
