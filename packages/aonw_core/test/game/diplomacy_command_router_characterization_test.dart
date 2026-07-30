import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'support/diplomacy_characterization_fixture.dart';
part 'support/diplomacy_actor_guard_characterization.dart';
part 'support/diplomacy_proposal_characterization.dart';
part 'support/diplomacy_proposal_edge_characterization.dart';
part 'support/diplomacy_proposal_response_characterization.dart';
part 'support/diplomacy_response_boundary_characterization.dart';
part 'support/diplomacy_war_and_gift_characterization.dart';
part 'support/diplomacy_message_characterization.dart';
part 'support/diplomacy_message_response_characterization.dart';

void main() {
  group('DiplomacyCommandResolver characterization', () {
    _registerActorGuardCharacterizationTests();
    _registerProposalCharacterizationTests();
    _registerProposalEdgeCharacterizationTests();
    _registerProposalResponseCharacterizationTests();
    _registerResponseBoundaryCharacterizationTests();
    _registerWarAndGiftCharacterizationTests();
    _registerMessageCharacterizationTests();
    _registerMessageResponseCharacterizationTests();
  });
}
