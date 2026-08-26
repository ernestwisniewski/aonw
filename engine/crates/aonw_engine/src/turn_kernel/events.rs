use aonw_domain::PlayerId;

use crate::{AllPlayersSubmittedEvent, DomainEvent, PlayerTimedOutEvent, TurnEndedEvent};

pub(super) fn sequential_phase_events(
    settlement: Vec<DomainEvent>,
    movement: Vec<DomainEvent>,
    research: Vec<DomainEvent>,
    player_id: &PlayerId,
) -> Box<[DomainEvent]> {
    let mut events = Vec::with_capacity(settlement.len() + movement.len() + research.len() + 1);
    events.extend(settlement);
    events.extend(movement);
    events.extend(research);
    events.push(DomainEvent::TurnEnded(TurnEndedEvent::new(
        player_id.clone(),
    )));
    events.into_boxed_slice()
}

pub(super) fn simultaneous_phase_events(
    current_turn: u32,
    scope: &[PlayerId],
    skipped: &[PlayerId],
    combat: Box<[DomainEvent]>,
    settlement: Vec<DomainEvent>,
    movement: Vec<DomainEvent>,
    research: Vec<DomainEvent>,
) -> Box<[DomainEvent]> {
    let mut events = Vec::with_capacity(
        skipped.len()
            + 1
            + combat.len()
            + settlement.len()
            + movement.len()
            + research.len()
            + scope.len(),
    );
    events.extend(
        skipped.iter().cloned().map(|player| {
            DomainEvent::PlayerTimedOut(PlayerTimedOutEvent::new(current_turn, player))
        }),
    );
    events.push(DomainEvent::AllPlayersSubmitted(
        AllPlayersSubmittedEvent::new(current_turn, scope.to_vec()),
    ));
    events.extend(combat);
    events.extend(settlement);
    events.extend(movement);
    events.extend(research);
    events.extend(
        scope
            .iter()
            .cloned()
            .map(TurnEndedEvent::new)
            .map(DomainEvent::TurnEnded),
    );
    events.into_boxed_slice()
}
