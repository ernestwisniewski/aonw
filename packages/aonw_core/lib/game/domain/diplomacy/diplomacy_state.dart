import 'package:aonw_core/game/domain/diplomacy/diplomacy_pair.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_primitives.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_message.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_proposal.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_relation.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_score_entry.dart';
import 'package:aonw_core/util/collection_equality.dart';

export 'diplomacy_primitives.dart';
export 'diplomatic_gold_gift_rules.dart';
export 'diplomatic_message.dart';
export 'diplomatic_proposal.dart';
export 'diplomatic_relation.dart';
export 'diplomatic_score_entry.dart';

part 'proposal_acceptance_policy.dart';
part 'diplomatic_proposal_forecast.dart';
part 'diplomatic_score_adjustment.dart';
part 'diplomacy_contact_pairs.dart';
part 'diplomacy_state_mutations.dart';
part 'diplomacy_state_queries.dart';
part 'diplomacy_state_model.dart';
part 'diplomacy_state_immutability.dart';
part 'diplomacy_state_serialization_helpers.dart';
part 'diplomacy_json_helpers.dart';
