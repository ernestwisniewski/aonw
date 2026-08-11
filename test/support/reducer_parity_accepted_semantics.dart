import 'package:aonw_core/domain.dart';

part 'reducer_parity_accepted_artifact_semantics.dart';
part 'reducer_parity_accepted_combat_semantics.dart';
part 'reducer_parity_accepted_economy_semantics.dart';
part 'reducer_parity_accepted_unit_action_semantics.dart';
part 'reducer_parity_accepted_unit_semantics.dart';

String artifactAcceptanceMode(DomainCommand command) => switch (command) {
  StartArtifactExcavationCommand() => 'excavation',
  StoreArtifactInCityCommand() => 'store',
  TradeArtifactCommand() => 'trade',
  _ => 'unexpected',
};

String resourceTradeAcceptanceMode(DomainCommand command) => switch (command) {
  OpenResourceTradeCommand() => 'gold',
  OpenResourceExchangeCommand() => 'exchange',
  _ => 'unexpected',
};
