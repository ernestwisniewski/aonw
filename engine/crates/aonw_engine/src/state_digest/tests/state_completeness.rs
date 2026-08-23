use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{
    GameModeDto, GameStateDto, PaceProfileDto, PendingInteractionDto, PlayerCountryDto,
    PlayerTurnStateDto, RuleValueDto, TransportConditionDto, UnitOccupancyPolicyDto,
    WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto,
};

use super::fixture::{complete_state_contract, coordinate};
use crate::state_digest::{StateDigest, digest_state};

#[test]
fn digest_changes_with_every_canonical_state_section() {
    let source = complete_state_contract();
    assert_digest_change(&source, "revision", |candidate| {
        candidate.revision += 1;
    });
    assert_digest_change(&source, "turn", |candidate| {
        candidate.turn += 1;
    });
    assert_digest_change(&source, "bounds", |candidate| {
        candidate.cols += 1;
    });
    assert_digest_change(&source, "occupancy policy", |candidate| {
        candidate.occupancy_policy = UnitOccupancyPolicyDto::Exclusive;
    });
    assert_digest_change(&source, "city", |candidate| {
        candidate.cities[0].controlled_hexes.push(coordinate(1, 0));
    });
    assert_digest_change(&source, "artifact type", |candidate| {
        candidate.artifacts[0].artifact_type = WorldArtifactTypeDto::ProphetMask;
    });
    assert_digest_change(&source, "artifact location", |candidate| {
        candidate.artifacts.push(WorldArtifactDto {
            id: "artifact-3".to_owned(),
            artifact_type: WorldArtifactTypeDto::QueensMirror,
            location: WorldArtifactLocationDto::Map {
                coordinate: coordinate(3, 3),
            },
        });
    });
    assert_digest_change(&source, "interaction draft", |candidate| {
        candidate
            .interaction
            .city_founding_draft
            .as_mut()
            .expect("draft")
            .center = coordinate(3, 2);
    });
    assert_digest_change(&source, "pending interaction", |candidate| {
        candidate.interaction.pending = Some(PendingInteractionDto::AttackTargeting {
            owner_player_id: "player-1".to_owned(),
            unit_id: "unit-1".to_owned(),
            defender: Some(coordinate(3, 3)),
        });
    });
    assert_digest_change(&source, "fog", |candidate| {
        candidate.fog_of_war[0].visible_hexes.push(coordinate(0, 0));
    });
    assert_digest_change(&source, "diplomacy", |candidate| {
        candidate.diplomatic_contacts.clear();
    });
    assert_digest_change(&source, "transport condition", |candidate| {
        candidate.transport_network[0].condition = TransportConditionDto::Pillaged;
    });
    assert_digest_change(&source, "transport builder", |candidate| {
        candidate.transport_network[0].built_by_city_id = None;
    });
}

#[test]
fn digest_changes_with_match_identity_and_turn_lifecycle() {
    let source = complete_state_contract();
    assert_digest_change(&source, "game length", |candidate| {
        candidate
            .match_identity
            .match_rules
            .game_length
            .pace_profile = PaceProfileDto::Long120;
    });
    assert_digest_change(&source, "victory rules", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .domination_hold_turns += 1;
    });
    assert_digest_change(&source, "balance rules", |candidate| {
        candidate.match_identity.match_rules.balance.insert(
            "combat".to_owned(),
            RuleValueDto::String("strict".to_owned()),
        );
    });
    assert_digest_change(&source, "game mode", |candidate| {
        candidate.match_identity.game_mode = GameModeDto::HotSeat;
    });
    assert_digest_change(&source, "participant order", |candidate| {
        candidate.match_identity.participants.reverse();
    });
    assert_digest_change(&source, "participant country", |candidate| {
        candidate.match_identity.participants[0].country = PlayerCountryDto::France;
    });
    assert_digest_change(&source, "participant AI identity", |candidate| {
        candidate.match_identity.participants[1]
            .ai
            .as_mut()
            .expect("AI participant")
            .seed += 1;
    });
    assert_digest_change(&source, "player turn state", |candidate| {
        candidate
            .turn_lifecycle
            .turn_states_by_player_id
            .insert("player-1".to_owned(), PlayerTurnStateDto::Finished);
    });
    assert_digest_change(&source, "submitted players", |candidate| {
        candidate.turn_lifecycle.submitted_player_ids.clear();
    });
    assert_digest_change(&source, "timeout streak", |candidate| {
        *candidate
            .turn_lifecycle
            .timeout_streaks_by_player_id
            .get_mut("player-2")
            .expect("timeout streak") += 1;
    });
    assert_digest_change(&source, "AFK players", |candidate| {
        candidate.turn_lifecycle.afk_player_ids.clear();
    });
    assert_digest_change(&source, "kicked players", |candidate| {
        candidate
            .turn_lifecycle
            .kicked_player_ids
            .push("player-1".to_owned());
    });
    assert_digest_change(&source, "turn start", |candidate| {
        candidate.turn_lifecycle.turn_started_at = Some("2026-08-23T12:34:57.123456Z".to_owned());
    });
}

#[test]
fn presentation_name_and_color_do_not_change_rule_state_digest() {
    let source = complete_state_contract();
    let baseline = contract_digest(&source);
    let mut presentation = source;
    presentation.match_identity.participants[0].name = "New display name".to_owned();
    presentation.match_identity.participants[0].color_value = 0xff00_ff00;

    assert_eq!(baseline, contract_digest(&presentation));
}

fn contract_digest(contract: &GameStateDto) -> StateDigest {
    digest_state(&decode_game_state(contract.clone()).expect("valid complete state"))
}

fn assert_digest_change(
    source: &GameStateDto,
    label: &str,
    change: impl FnOnce(&mut GameStateDto),
) {
    let baseline = contract_digest(source);
    let mut candidate = source.clone();
    change(&mut candidate);
    assert_ne!(
        baseline,
        contract_digest(&candidate),
        "state digest ignored {label}"
    );
}
