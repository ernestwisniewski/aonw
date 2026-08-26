//! Fail-closed coverage for persisted state requiring unsupported turn processors.

use std::collections::BTreeMap;

use aonw_content::RulesetDefinition;
use aonw_domain::{
    EconomyState, GameMode, GameState, InitialResourceDistribution, MatchIdentity, MatchLifecycle,
    MatchRules, ObjectiveState, PlayerTurnState, StateRevision, TurnLifecycle, UnitOccupancyPolicy,
};
use aonw_engine::{
    CommandRejectionCode, EngineContext, GameEngine, PlayerCommand, ProcessorRequirement,
    TurnCommand, TurnProcessor,
};

use super::{map, participant, player, unit};

#[test]
fn every_persisted_disabled_phase_requirement_fails_closed() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let player = player("player-2");
    for processor in [TurnProcessor::Economy, TurnProcessor::Objectives] {
        let state = state_requiring(processor);
        assert_eq!(
            processor.requirement(&state, &map, std::slice::from_ref(&player)),
            ProcessorRequirement::RequiredButUnsupported,
            "{processor:?} must be detected before mutation"
        );
        let before = GameEngine::state_digest(&state);
        let transition = GameEngine::apply_player_owned(
            state,
            EngineContext::canonical(&player, &map, rules),
            PlayerCommand::SubmitTurn(TurnCommand::new(7, &player)),
        )
        .expect("disabled processor rejection");
        assert_eq!(
            transition.rejection().expect("rejection").code(),
            CommandRejectionCode::TurnProcessorUnsupported,
            "{processor:?} must reject the whole turn"
        );
        assert_eq!(GameEngine::state_digest(transition.state()), before);
        assert!(transition.events().is_empty());
    }
}

fn state_requiring(processor: TurnProcessor) -> GameState {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Finished),
            (p2.clone(), PlayerTurnState::Active),
        ]),
        [p1.clone(), p2.clone()],
        [p1],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    let mut builder = GameState::builder(
        StateRevision::new(7),
        7,
        map().bounds(),
        UnitOccupancyPolicy::Exclusive,
        [unit("unit-2", &p2)],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity.clone(), lifecycle));

    builder = match processor {
        TurnProcessor::Economy => builder.with_economy(
            EconomyState::try_new(
                &identity,
                map().bounds(),
                BTreeMap::new(),
                BTreeMap::from([(p2, 1)]),
                BTreeMap::new(),
                BTreeMap::new(),
                InitialResourceDistribution::default(),
            )
            .expect("economy"),
        ),
        TurnProcessor::Objectives => builder.with_objectives(
            ObjectiveState::try_new(&identity, BTreeMap::from([(p2, 1)]), BTreeMap::new(), [])
                .expect("objectives"),
        ),
        _ => panic!("test requires a disabled persisted phase"),
    };
    builder.try_build().expect("state")
}
