//! Transaction and privacy contract for the first remote multiplayer command.

use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    FogOfWar, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules,
    MovementUnits, Participant, PlayerCountry, PlayerFog, PlayerId, PlayerKind, PlayerTurnState,
    StateRevision, TurnLifecycle, Unit, UnitId, UnitKind,
};
use aonw_engine::{CommandRejectionCode, DomainEvent, GameEngine};
use aonw_server_runtime::{ServerHostError, SubmitTurnRequest, apply_submit_turn};

#[test]
fn final_submit_returns_exact_offsets_and_every_recipient_projection() {
    let fixture = fixture([player("player-1")]);
    let expected_map_hash = fixture.map.content_hash().expect("map hash");
    let expected_ruleset_hash = fixture.ruleset.content_hash().expect("ruleset hash");
    let outcome = apply_submit_turn(fixture.request("player-2", 7, 40)).expect("submit turn");

    assert_eq!(outcome.rejection, None);
    assert_eq!(outcome.initial_event_offset, 40);
    assert_eq!(outcome.final_event_offset, 43);
    assert_eq!(outcome.state.revision(), StateRevision::new(8));
    assert_eq!(outcome.state.turn(), 8);
    assert_eq!(
        outcome.stamp.state_digest,
        GameEngine::state_digest(&outcome.state)
    );
    assert_eq!(outcome.stamp.map_hash, expected_map_hash);
    assert_eq!(outcome.stamp.ruleset_hash, expected_ruleset_hash);
    assert!(matches!(
        outcome.events.as_ref(),
        [
            DomainEvent::AllPlayersSubmitted(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    assert_eq!(outcome.recipients.len(), 2);
    for recipient in &outcome.recipients {
        assert_eq!(
            recipient.snapshot.recipient_player_id(),
            &recipient.recipient_player_id
        );
        assert_eq!(recipient.snapshot.stamp(), &outcome.stamp);
        assert_eq!(recipient.patch.from_revision, 7);
        assert_eq!(recipient.patch.to_revision, 8);
        assert_eq!(recipient.events.as_ref(), outcome.events.as_ref());

        let own_unit = recipient
            .snapshot
            .units()
            .iter()
            .find(|unit| unit.owner_player_id() == &recipient.recipient_player_id)
            .expect("own unit");
        assert!(own_unit.owned_details().is_some());
        assert!(
            recipient
                .snapshot
                .units()
                .iter()
                .filter(|unit| unit.owner_player_id() != &recipient.recipient_player_id)
                .all(|unit| unit.owned_details().is_none())
        );
    }
}

#[test]
fn stale_submit_is_an_exact_unchanged_outcome() {
    let fixture = fixture([]);
    let before_state = fixture.state.clone();
    let before_digest = GameEngine::state_digest(&before_state);
    let outcome = apply_submit_turn(fixture.request("player-1", 6, 19)).expect("rejection");

    assert_eq!(outcome.rejection, Some(CommandRejectionCode::StaleRevision));
    assert_eq!(outcome.state, before_state);
    assert_eq!(outcome.stamp.state_digest, before_digest);
    assert_eq!(outcome.initial_event_offset, 19);
    assert_eq!(outcome.final_event_offset, 19);
    assert!(outcome.events.is_empty());
    assert!(outcome.evidence.is_none());
    assert!(outcome.recipients.iter().all(|recipient| {
        recipient.events.is_empty()
            && recipient.patch.from_revision == 7
            && recipient.patch.to_revision == 7
            && recipient.snapshot.stamp().state_digest == before_digest
    }));
}

#[test]
fn authenticated_actor_and_event_capacity_fail_before_transition() {
    let world = fixture([]);
    assert_eq!(
        apply_submit_turn(world.request("foreign-player", 7, 0)),
        Err(ServerHostError::UnknownAuthenticatedActor(player(
            "foreign-player"
        )))
    );

    let world = fixture([]);
    assert_eq!(
        apply_submit_turn(world.request("player-1", 7, u64::MAX)),
        Err(ServerHostError::EventOffsetOverflow)
    );
}

#[test]
fn immutable_content_mismatch_fails_closed() {
    let mut world = fixture([]);
    world.map = map(1);
    assert_eq!(
        apply_submit_turn(world.request("player-1", 7, 0)),
        Err(ServerHostError::MapBoundsMismatch)
    );

    let world = fixture([]);
    let mut request = world.request("player-1", 7, 0);
    request.state = GameState::builder(
        request.state.revision(),
        request.state.turn(),
        request.state.bounds(),
        aonw_domain::UnitOccupancyPolicy::Exclusive,
        request.state.units().iter().cloned(),
    )
    .with_match_lifecycle(request.state.match_lifecycle().clone())
    .with_fog_of_war(request.state.fog_of_war().clone())
    .try_build()
    .expect("exclusive state");
    assert_eq!(
        apply_submit_turn(request),
        Err(ServerHostError::OccupancyPolicyMismatch)
    );
}

struct Fixture {
    state: GameState,
    map: MapDefinition,
    ruleset: RulesetDefinition,
}

impl Fixture {
    fn request(
        &self,
        actor: &str,
        expected_revision: u64,
        initial_event_offset: u64,
    ) -> SubmitTurnRequest {
        SubmitTurnRequest {
            state: self.state.clone(),
            map: self.map.clone(),
            ruleset: self.ruleset.clone(),
            authenticated_actor: player(actor),
            expected_revision,
            initial_event_offset,
        }
    }
}

fn fixture(submitted: impl IntoIterator<Item = PlayerId>) -> Fixture {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let map = map(2);
    let ruleset = RulesetDefinition::standard().clone();
    let participants = [
        participant(p1.clone(), "One"),
        participant(p2.clone(), "Two"),
    ];
    let identity =
        MatchIdentity::try_new(MatchRules::default(), participants, GameMode::Multiplayer)
            .expect("identity");
    let submitted = submitted.into_iter().collect::<BTreeSet<_>>();
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (
                p1.clone(),
                if submitted.contains(&p1) {
                    PlayerTurnState::Finished
                } else {
                    PlayerTurnState::Active
                },
            ),
            (
                p2.clone(),
                if submitted.contains(&p2) {
                    PlayerTurnState::Finished
                } else {
                    PlayerTurnState::Active
                },
            ),
        ]),
        [p1.clone(), p2.clone()],
        submitted,
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let units = [unit("unit-1", &p1, 0), unit("unit-2", &p2, 1)];
    let fog = FogOfWar::try_new([
        PlayerFog::new(p1, [], [HexCoord::new(0, 0)]),
        PlayerFog::new(p2, [], [HexCoord::new(1, 0)]),
    ])
    .expect("fog");
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map.bounds(),
        ruleset.occupancy_policy(),
        units,
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_fog_of_war(fog)
    .try_build()
    .expect("state");
    Fixture {
        state,
        map,
        ruleset,
    }
}

fn participant(id: PlayerId, name: &str) -> Participant {
    Participant::try_new(
        id,
        name,
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn unit(id: &str, owner: &PlayerId, col: i32) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        UnitKind::Commander,
        id,
        HexCoord::new(col, 0),
        MovementUnits::ZERO,
    )
    .build()
    .expect("unit")
}

fn map(cols: u16) -> MapDefinition {
    MapDefinition::try_new(
        "server-host-test",
        GridLayout::OddQFlatTop,
        cols,
        1,
        (0..cols)
            .map(|col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(i32::from(col), 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}
