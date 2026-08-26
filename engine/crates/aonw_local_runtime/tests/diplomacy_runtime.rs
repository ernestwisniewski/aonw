//! Current-only diplomacy proposal protocol, replay, and disclosure coverage.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::DiplomaticProposalKindDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandOutcomeDto, ClientEventDto,
    ClientFeatureDto, ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto, ClientResponseDto,
};
use aonw_domain::{
    Diplomacy, DiplomaticMessage, DiplomaticMessageCategory, DiplomaticMessageTopic,
    DiplomaticProposal, DiplomaticProposalKind, EconomyState, GameMode, GameState, HexCoord,
    MatchIdentity, MatchLifecycle, MatchRules, Participant, PlayerCountry, PlayerId, PlayerKind,
    PlayerPair, PlayerTurnState, StateRevision, TurnLifecycle,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

#[test]
fn proposal_commands_are_current_private_and_replayable() {
    let ruleset = RulesetDefinition::standard().clone();
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");

    let mut sender = open_runtime(&map, &ruleset, state(None), p1.clone());
    let capabilities = dispatch_body(&mut sender, ClientRequestBodyDto::Capabilities);
    let ClientResponseBodyDto::Capabilities { features } = capabilities else {
        panic!("capabilities")
    };
    assert!(features.contains(&ClientFeatureDto::Diplomacy));
    let sent = dispatch(
        &mut sender,
        ClientCommandDto::SendDiplomaticProposal {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
            kind: DiplomaticProposalKindDto::Friendship,
            proposal_id: Some("friendship-1".to_owned()),
            gold_payment: 99,
        },
    );
    assert_eq!(sent.outcome, ClientCommandOutcomeDto::Accepted);
    assert_eq!(sent.stamp.revision, 12);
    assert!(matches!(
        sent.events.as_slice(),
        [ClientEventDto::DiplomaticProposalSent {
            proposal_id,
            from_player_id,
            to_player_id,
            kind: DiplomaticProposalKindDto::Friendship,
            expires_on_turn: 12,
        }] if proposal_id == "friendship-1"
            && from_player_id == p1.as_str()
            && to_player_id == p2.as_str()
    ));
    verify_one_entry(&sender, map.clone(), ruleset.clone());

    let proposal = DiplomaticProposal::try_new(
        "friendship-1".to_owned(),
        p1.clone(),
        p2.clone(),
        DiplomaticProposalKind::Friendship,
        7,
        12,
        0,
    )
    .expect("proposal");
    let mut recipient = open_runtime(&map, &ruleset, state(Some(proposal)), p2.clone());
    let responded = dispatch(
        &mut recipient,
        ClientCommandDto::RespondDiplomaticProposal {
            expected_revision: 11,
            proposal_id: "friendship-1".to_owned(),
            accepted: false,
        },
    );
    assert_eq!(responded.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        responded.events.as_slice(),
        [
            ClientEventDto::DiplomaticProposalResponded {
                proposal_id,
                accepted: false,
                ..
            },
            ClientEventDto::DiplomaticScoreChanged { delta: -6, .. }
        ] if proposal_id == "friendship-1"
    ));
    verify_one_entry(&recipient, map, ruleset);
}

#[test]
fn message_commands_are_current_private_and_replayable() {
    let ruleset = RulesetDefinition::standard().clone();
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let mut sender = open_runtime(&map, &ruleset, state(None), p1.clone());
    let sent = dispatch(
        &mut sender,
        ClientCommandDto::SendDiplomaticMessage {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
            topic: aonw_contracts::DiplomaticMessageTopicDto::WithdrawScouts,
            message_id: Some("withdraw-1".to_owned()),
        },
    );
    assert_eq!(sent.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        sent.events.as_slice(),
        [ClientEventDto::DiplomaticMessageSent {
            message_id,
            category: aonw_contracts::DiplomaticMessageCategoryDto::Request,
            ..
        }] if message_id == "withdraw-1"
    ));
    verify_one_entry(&sender, map.clone(), ruleset.clone());

    let message = DiplomaticMessage::try_new(
        "withdraw-1".to_owned(),
        p1,
        p2.clone(),
        DiplomaticMessageTopic::WithdrawScouts,
        DiplomaticMessageCategory::Request,
        7,
        12,
        None,
        None,
        0,
        None,
        None,
        false,
    )
    .expect("message");
    let mut recipient = open_runtime(&map, &ruleset, state_with_message(message), p2);
    let responded = dispatch(
        &mut recipient,
        ClientCommandDto::RespondDiplomaticMessage {
            expected_revision: 11,
            message_id: "withdraw-1".to_owned(),
            response: aonw_contracts::DiplomaticMessageResponseDto::Conciliatory,
        },
    );
    assert_eq!(responded.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        responded.events.as_slice(),
        [
            ClientEventDto::DiplomaticMessageResponded {
                message_id,
                response: aonw_contracts::DiplomaticMessageResponseDto::Conciliatory,
                relation_delta: 12,
                promise_due_turn: Some(10),
                ..
            },
            ClientEventDto::DiplomaticScoreChanged { delta: 12, .. }
        ] if message_id == "withdraw-1"
    ));
    verify_one_entry(&recipient, map, ruleset);
}

#[test]
fn war_and_gold_gift_are_current_atomic_and_replayable() {
    let ruleset = RulesetDefinition::standard().clone();
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");

    let mut gifting = open_runtime(&map, &ruleset, state(None), p1.clone());
    let gifted = dispatch(
        &mut gifting,
        ClientCommandDto::SendGoldGift {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
            amount: 10,
        },
    );
    assert_eq!(gifted.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        gifted.events.as_slice(),
        [ClientEventDto::DiplomaticScoreChanged {
            delta: 2,
            reason: aonw_contracts::DiplomaticScoreChangeReasonDto::GoldGift,
            source_id: Some(source),
            ..
        }] if source == "gold_gift.7.player-1.player-2"
    ));
    verify_one_entry(&gifting, map.clone(), ruleset.clone());

    let mut declaring = open_runtime(&map, &ruleset, state(None), p1);
    let war = dispatch(
        &mut declaring,
        ClientCommandDto::DeclareWar {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
        },
    );
    assert_eq!(war.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        war.events.as_slice(),
        [
            ClientEventDto::DiplomaticRelationChanged {
                new_status: aonw_contracts::DiplomaticRelationStatusDto::War,
                reason: aonw_contracts::DiplomaticRelationChangeReasonDto::DeclarationOfWar,
                ..
            },
            ClientEventDto::DiplomaticScoreChanged {
                delta: -25,
                reason: aonw_contracts::DiplomaticScoreChangeReasonDto::DeclarationOfWar,
                source_id: None,
                ..
            }
        ]
    ));
    verify_one_entry(&declaring, map, ruleset);
}

fn dispatch(
    runtime: &mut LocalRuntime,
    command: ClientCommandDto,
) -> aonw_contracts::client::ClientCommandResultDto {
    let response = dispatch_body(runtime, ClientRequestBodyDto::Dispatch { command });
    let ClientResponseBodyDto::Command { result } = response else {
        panic!("command response")
    };
    *result
}

fn dispatch_body(
    runtime: &mut LocalRuntime,
    request: ClientRequestBodyDto,
) -> ClientResponseBodyDto {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request,
    }
    .to_json()
    .expect("request JSON");
    let response = ClientResponseDto::from_json(&ClientProtocol::dispatch_json(runtime, &request))
        .expect("response JSON");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("protocol failure")
    };
    *response
}

fn verify_one_entry(runtime: &LocalRuntime, map: MapDefinition, ruleset: RulesetDefinition) {
    let replay = runtime.export_replay_json().expect("replay");
    assert!(replay.contains("Diplomatic") || replay.contains("diplomatic"));
    let verification = LocalRuntime::verify_replay_json(map, ruleset, &replay).expect("verify");
    assert_eq!(verification.entry_count, 1);
}

fn open_runtime(
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    state: GameState,
    actor: PlayerId,
) -> LocalRuntime {
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            ruleset.clone(),
            state,
            actor,
        ))
        .expect("open");
    runtime
}

fn state(proposal: Option<DiplomaticProposal>) -> GameState {
    state_with_records(proposal, None)
}

fn state_with_message(message: DiplomaticMessage) -> GameState {
    state_with_records(None, Some(message))
}

fn state_with_records(
    proposal: Option<DiplomaticProposal>,
    message: Option<DiplomaticMessage>,
) -> GameState {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(p1.clone(), 1), participant(p2.clone(), 2)],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Active),
            (p2.clone(), PlayerTurnState::Active),
        ]),
        [p1.clone(), p2.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let pair = PlayerPair::new(p1.clone(), p2.clone()).expect("pair");
    let diplomacy =
        Diplomacy::try_new(&identity, [pair], [], proposal, message, [], []).expect("diplomacy");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(p1, 20), (p2, 1)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        aonw_domain::InitialResourceDistribution::default(),
    )
    .expect("economy");
    GameState::builder(
        StateRevision::new(11),
        7,
        map.bounds(),
        RulesetDefinition::standard().occupancy_policy(),
        [],
    )
    .with_economy(economy)
    .with_diplomacy(diplomacy)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "diplomacy-runtime",
        GridLayout::OddQFlatTop,
        1,
        1,
        vec![
            TileDefinition::try_new_for_simulation(
                HexCoord::new(0, 0),
                vec![TerrainType::Plains],
                Vec::new(),
                0,
            )
            .expect("tile"),
        ],
        Vec::new(),
    )
    .expect("map")
}

fn participant(id: PlayerId, color: u32) -> Participant {
    Participant::try_new(
        id,
        "Player",
        0xff00_0000 + color,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn player(value: &str) -> PlayerId {
    PlayerId::new(value).expect("player id")
}
