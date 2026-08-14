use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{
    GameStateDto, PendingInteractionDto, TransportConditionDto, UnitOccupancyPolicyDto,
    WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto,
};

use super::fixture::{complete_state_contract, coordinate};
use crate::state_digest::{StateDigest, digest_state};

#[test]
fn digest_changes_with_every_canonical_state_section() {
    let source = complete_state_contract();
    let baseline = contract_digest(&source);

    macro_rules! changes_state_digest {
        ($label:literal, $candidate:ident, $change:block) => {{
            let mut $candidate = source.clone();
            $change
            assert_ne!(
                baseline,
                contract_digest(&$candidate),
                "state digest ignored {}",
                $label
            );
        }};
    }

    changes_state_digest!("revision", candidate, {
        candidate.revision += 1;
    });
    changes_state_digest!("turn", candidate, {
        candidate.turn += 1;
    });
    changes_state_digest!("bounds", candidate, {
        candidate.cols += 1;
    });
    changes_state_digest!("occupancy policy", candidate, {
        candidate.occupancy_policy = UnitOccupancyPolicyDto::Exclusive;
    });
    changes_state_digest!("city", candidate, {
        candidate.cities[0].controlled_hexes.push(coordinate(1, 0));
    });
    changes_state_digest!("artifact type", candidate, {
        candidate.artifacts[0].artifact_type = WorldArtifactTypeDto::ProphetMask;
    });
    changes_state_digest!("artifact location", candidate, {
        candidate.artifacts.push(WorldArtifactDto {
            id: "artifact-3".to_owned(),
            artifact_type: WorldArtifactTypeDto::QueensMirror,
            location: WorldArtifactLocationDto::Map {
                coordinate: coordinate(3, 3),
            },
        });
    });
    changes_state_digest!("interaction draft", candidate, {
        candidate
            .interaction
            .city_founding_draft
            .as_mut()
            .expect("draft")
            .center = coordinate(3, 2);
    });
    changes_state_digest!("pending interaction", candidate, {
        candidate.interaction.pending = Some(PendingInteractionDto::AttackTargeting {
            owner_player_id: "player-1".to_owned(),
            unit_id: "unit-1".to_owned(),
            defender: Some(coordinate(3, 3)),
        });
    });
    changes_state_digest!("fog", candidate, {
        candidate.fog_of_war[0].visible_hexes.push(coordinate(0, 0));
    });
    changes_state_digest!("diplomacy", candidate, {
        candidate.diplomatic_contacts.clear();
    });
    changes_state_digest!("transport condition", candidate, {
        candidate.transport_network[0].condition = TransportConditionDto::Pillaged;
    });
    changes_state_digest!("transport builder", candidate, {
        candidate.transport_network[0].built_by_city_id = None;
    });
}

fn contract_digest(contract: &GameStateDto) -> StateDigest {
    digest_state(&decode_game_state(contract.clone()).expect("valid complete state"))
}
