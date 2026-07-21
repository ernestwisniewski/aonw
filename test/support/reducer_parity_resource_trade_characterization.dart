import 'package:aonw_core/domain.dart';

import 'reducer_parity_fixture.dart';

part 'reducer_parity_resource_trade_characterization_fixture.dart';
part 'reducer_parity_resource_trade_exchange_cases.dart';
part 'reducer_parity_resource_trade_gold_cases.dart';

abstract final class ResourceTradeReducerParityCharacterization {
  static List<ReducerParityFixture> extend(List<ReducerParityFixture> corpus) {
    final template = corpus.singleWhere(
      (fixture) => fixture.id == 'resource-trade-gold-accepted',
    );
    final baseState = _tradeParityBaseState(template.state);
    final characterization = [
      ..._goldTradeParityCases(template, baseState),
      ..._resourceExchangeParityCases(template, baseState),
    ];
    _requireExactResourceTradeCharacterization(characterization);
    final ids = <String>{for (final fixture in corpus) fixture.id};
    for (final fixture in characterization) {
      if (!ids.add(fixture.id)) {
        throw StateError('Duplicate resource trade parity id: ${fixture.id}.');
      }
    }
    return List.unmodifiable([...corpus, ...characterization]);
  }
}

const _requiredResourceTradeCharacterization =
    <String, ({String mode, bool accepted, String? reason})>{
      'resource-trade-characterization-gold-wrong-actor-rejected': (
        mode: 'gold',
        accepted: false,
        reason: 'resource_trade_player_not_controlled',
      ),
      'resource-trade-characterization-gold-self-target-rejected': (
        mode: 'gold',
        accepted: false,
        reason: 'invalid_resource_trade_target',
      ),
      'resource-trade-characterization-gold-invalid-terms-rejected': (
        mode: 'gold',
        accepted: false,
        reason: 'invalid_resource_trade_terms',
      ),
      'resource-trade-characterization-gold-war-rejected': (
        mode: 'gold',
        accepted: false,
        reason: 'resource_trade_blocked_by_war',
      ),
      'resource-trade-characterization-gold-unavailable-rejected': (
        mode: 'gold',
        accepted: false,
        reason: 'resource_trade_gold_unavailable',
      ),
      'resource-trade-characterization-gold-duplicate-rejected': (
        mode: 'gold',
        accepted: false,
        reason: 'resource_trade_already_active',
      ),
      'resource-trade-characterization-gold-export-rejected': (
        mode: 'gold',
        accepted: false,
        reason: 'resource_trade_export_unavailable',
      ),
      'resource-trade-characterization-gold-generated-id-accepted': (
        mode: 'gold',
        accepted: true,
        reason: null,
      ),
      'resource-trade-characterization-exchange-wrong-actor-rejected': (
        mode: 'exchange',
        accepted: false,
        reason: 'resource_trade_player_not_controlled',
      ),
      'resource-trade-characterization-exchange-self-target-rejected': (
        mode: 'exchange',
        accepted: false,
        reason: 'invalid_resource_trade_target',
      ),
      'resource-trade-characterization-exchange-invalid-terms-rejected': (
        mode: 'exchange',
        accepted: false,
        reason: 'invalid_resource_trade_terms',
      ),
      'resource-trade-characterization-exchange-war-rejected': (
        mode: 'exchange',
        accepted: false,
        reason: 'resource_trade_blocked_by_war',
      ),
      'resource-trade-characterization-exchange-requested-duplicate-rejected': (
        mode: 'exchange',
        accepted: false,
        reason: 'resource_trade_already_active',
      ),
      'resource-trade-characterization-exchange-offered-duplicate-rejected': (
        mode: 'exchange',
        accepted: false,
        reason: 'resource_trade_already_active',
      ),
      'resource-trade-characterization-exchange-offer-rejected': (
        mode: 'exchange',
        accepted: false,
        reason: 'resource_trade_offer_unavailable',
      ),
      'resource-trade-characterization-exchange-request-rejected': (
        mode: 'exchange',
        accepted: false,
        reason: 'resource_trade_request_unavailable',
      ),
      'resource-trade-characterization-exchange-generated-id-accepted': (
        mode: 'exchange',
        accepted: true,
        reason: null,
      ),
    };

void _requireExactResourceTradeCharacterization(
  List<ReducerParityFixture> fixtures,
) {
  final actualIds = {for (final fixture in fixtures) fixture.id};
  final requiredIds = _requiredResourceTradeCharacterization.keys.toSet();
  if (actualIds.length != fixtures.length ||
      !actualIds.containsAll(requiredIds) ||
      !requiredIds.containsAll(actualIds)) {
    throw StateError('Resource trade parity characterization is incomplete.');
  }
  for (final fixture in fixtures) {
    final required = _requiredResourceTradeCharacterization[fixture.id]!;
    final (mode, agreementId) = switch (fixture.command) {
      OpenResourceTradeCommand(:final agreementId) => ('gold', agreementId),
      OpenResourceExchangeCommand(:final agreementId) => (
        'exchange',
        agreementId,
      ),
      _ => ('unexpected', null),
    };
    if (mode != required.mode ||
        fixture.expectedAccepted != required.accepted ||
        fixture.expectedReason != required.reason ||
        fixture.expectedEvents.isNotEmpty ||
        (required.accepted && agreementId != null)) {
      throw StateError(
        'Resource trade parity characterization drifted: ${fixture.id}.',
      );
    }
  }
}
