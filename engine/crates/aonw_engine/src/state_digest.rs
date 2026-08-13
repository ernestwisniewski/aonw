use aonw_domain::{
    FieldImprovementKind, GameState, HexCoord, MovementUnits, TransportCondition, TroopKind, Unit,
    UnitActivity, UnitKind, UnitOccupancyPolicy, UnitPosture, WorkerJob,
};
use sha2::{Digest, Sha256};

/// SHA-256 identity of canonical simulation state.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct StateDigest([u8; 32]);

impl StateDigest {
    /// Returns digest bytes.
    #[must_use]
    pub const fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

impl core::fmt::Display for StateDigest {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        for byte in self.0 {
            write!(formatter, "{byte:02x}")?;
        }
        Ok(())
    }
}

pub(crate) fn digest_state(state: &GameState) -> StateDigest {
    let mut writer = DigestWriter(Sha256::new());
    writer.text("aonw-game-state-v2");
    writer.u64(state.revision().get());
    writer.u32(state.turn());
    writer.u16(state.bounds().cols());
    writer.u16(state.bounds().rows());
    writer.u8(match state.occupancy_policy() {
        UnitOccupancyPolicy::Exclusive => 0,
        UnitOccupancyPolicy::FriendlyStacking => 1,
    });

    let mut units = state.units().iter().collect::<Vec<_>>();
    units.sort_unstable_by(|left, right| left.id().cmp(right.id()));
    writer.usize(units.len());
    for unit in units {
        hash_unit(&mut writer, unit);
    }

    let mut cities = state.cities().iter().collect::<Vec<_>>();
    cities.sort_unstable_by(|left, right| left.id().cmp(right.id()));
    writer.usize(cities.len());
    for city in cities {
        writer.text(city.id().as_str());
        writer.text(city.owner_player_id().as_str());
        writer.coordinate(city.center());
        writer.usize(city.controlled_hexes().len());
        for coordinate in city.controlled_hexes() {
            writer.coordinate(*coordinate);
        }
    }

    writer.usize(state.fog_of_war().players().len());
    for fog in state.fog_of_war().players() {
        writer.text(fog.player_id().as_str());
        writer.coordinates(fog.discovered_hexes());
        writer.coordinates(fog.visible_hexes());
    }

    writer.usize(state.diplomacy().contacts().len());
    for pair in state.diplomacy().contacts() {
        writer.text(pair.first().as_str());
        writer.text(pair.second().as_str());
    }

    writer.usize(state.transport_network().segments().len());
    for segment in state.transport_network().segments() {
        writer.coordinate(segment.coordinate());
        writer.u8(match segment.condition() {
            TransportCondition::Operational => 0,
            TransportCondition::Pillaged => 1,
        });
        writer.text(segment.built_by_player_id().as_str());
        writer.optional_text(segment.built_by_city_id().map(aonw_domain::CityId::as_str));
    }
    StateDigest(writer.0.finalize().into())
}

fn hash_unit(writer: &mut DigestWriter, unit: &Unit) {
    writer.text(unit.id().as_str());
    writer.text(unit.owner_player_id().as_str());
    writer.u8(unit_kind_tag(unit.kind()));
    writer.text(unit.name());
    writer.coordinate(unit.position());
    writer.u32(unit.movement_units().get());
    writer.optional_u32(unit.skipped_movement_restore().map(MovementUnits::get));
    writer.usize(unit.army().len());
    for troop in unit.army() {
        writer.u8(match troop.kind() {
            TroopKind::Warrior => 0,
            TroopKind::Archer => 1,
            TroopKind::Settler => 2,
        });
        writer.u32(troop.count());
    }
    writer.optional_route(unit.queued_path());
    match unit.merchant_trade_route() {
        None => writer.u8(0),
        Some(route) => {
            writer.u8(1);
            writer.text(route.origin_city_id().as_str());
            writer.text(route.destination_city_id().as_str());
            writer.steps(route.steps());
            writer.text(route.transport_network_fingerprint());
        }
    }
    hash_activity(writer, unit.activity());
    writer.u32(unit.worker_build_charges());
    writer.optional_u32(unit.hit_points());
    writer.u32(unit.experience_points());
    writer.u8(match unit.posture() {
        UnitPosture::Active => 0,
        UnitPosture::Fortified => 1,
        UnitPosture::AutoExploring => 2,
        UnitPosture::AutoWorking => 3,
    });
    writer.optional_text(
        unit.carried_artifact_id()
            .map(aonw_domain::ArtifactId::as_str),
    );
}

fn hash_activity(writer: &mut DigestWriter, activity: &UnitActivity) {
    match activity.worker_job() {
        None => writer.u8(0),
        Some(WorkerJob::FieldImprovement {
            target,
            improvement,
            remaining_turns,
            total_turns,
        }) => {
            writer.u8(1);
            writer.coordinate(*target);
            writer.u8(improvement_tag(*improvement));
            writer.u32(*remaining_turns);
            writer.u32(*total_turns);
        }
        Some(WorkerJob::RoadConstruction {
            target,
            remaining_turns,
            total_turns,
        }) => {
            writer.u8(2);
            writer.coordinate(*target);
            writer.u32(*remaining_turns);
            writer.u32(*total_turns);
        }
    }
    match activity.city_founding_job() {
        None => writer.u8(0),
        Some(job) => {
            writer.u8(1);
            writer.coordinate(job.center());
            writer.coordinates(job.controlled_hexes());
            writer.u32(job.remaining_turns());
            writer.u32(job.total_turns());
        }
    }
    writer.optional_coordinate(activity.worker_assignment());
    writer.optional_text(
        activity
            .excavating_artifact_id()
            .map(aonw_domain::ArtifactId::as_str),
    );
}

const fn unit_kind_tag(kind: UnitKind) -> u8 {
    match kind {
        UnitKind::Commander => 0,
        UnitKind::Warrior => 1,
        UnitKind::Archer => 2,
        UnitKind::Settler => 3,
        UnitKind::Worker => 4,
        UnitKind::Merchant => 5,
        UnitKind::Scout => 6,
        UnitKind::Spearman => 7,
        UnitKind::Cavalry => 8,
        UnitKind::Catapult => 9,
        UnitKind::HeavyInfantry => 10,
        UnitKind::FieldCannon => 11,
        UnitKind::Rifleman => 12,
        UnitKind::Tank => 13,
        UnitKind::ScoutShip => 14,
        UnitKind::Warship => 15,
        UnitKind::ReconPlane => 16,
    }
}

const fn improvement_tag(kind: FieldImprovementKind) -> u8 {
    match kind {
        FieldImprovementKind::Farm => 0,
        FieldImprovementKind::RiverFarm => 1,
        FieldImprovementKind::Mine => 2,
        FieldImprovementKind::LumberMill => 3,
        FieldImprovementKind::Pasture => 4,
        FieldImprovementKind::Camp => 5,
        FieldImprovementKind::Quarry => 6,
        FieldImprovementKind::FishingBoats => 7,
        FieldImprovementKind::Orchard => 8,
        FieldImprovementKind::Plantation => 9,
        FieldImprovementKind::Vineyard => 10,
        FieldImprovementKind::TradingPost => 11,
        FieldImprovementKind::ProspectorCamp => 12,
        FieldImprovementKind::HorseRanch => 13,
        FieldImprovementKind::PearlDivers => 14,
        FieldImprovementKind::CoalShaft => 15,
        FieldImprovementKind::OilWell => 16,
        FieldImprovementKind::BauxiteMine => 17,
        FieldImprovementKind::UraniumMine => 18,
    }
}

struct DigestWriter(Sha256);

impl DigestWriter {
    fn u8(&mut self, value: u8) {
        self.0.update([value]);
    }
    fn u16(&mut self, value: u16) {
        self.0.update(value.to_le_bytes());
    }
    fn u32(&mut self, value: u32) {
        self.0.update(value.to_le_bytes());
    }
    fn u64(&mut self, value: u64) {
        self.0.update(value.to_le_bytes());
    }
    fn usize(&mut self, value: usize) {
        self.u64(u64::try_from(value).expect("bounded length"));
    }
    fn text(&mut self, value: &str) {
        self.usize(value.len());
        self.0.update(value.as_bytes());
    }
    fn coordinate(&mut self, value: HexCoord) {
        self.0.update(value.col().to_le_bytes());
        self.0.update(value.row().to_le_bytes());
    }
    fn coordinates(&mut self, values: &[HexCoord]) {
        self.usize(values.len());
        for value in values {
            self.coordinate(*value);
        }
    }
    fn optional_coordinate(&mut self, value: Option<HexCoord>) {
        match value {
            None => self.u8(0),
            Some(value) => {
                self.u8(1);
                self.coordinate(value);
            }
        }
    }
    fn optional_u32(&mut self, value: Option<u32>) {
        match value {
            None => self.u8(0),
            Some(value) => {
                self.u8(1);
                self.u32(value);
            }
        }
    }
    fn optional_text(&mut self, value: Option<&str>) {
        match value {
            None => self.u8(0),
            Some(value) => {
                self.u8(1);
                self.text(value);
            }
        }
    }
    fn steps(&mut self, steps: &[aonw_domain::MovementStep]) {
        self.usize(steps.len());
        for step in steps {
            self.coordinate(step.coordinate());
            self.u32(step.enter_cost().get());
            self.u32(step.cumulative_cost().get());
        }
    }
    fn optional_route(&mut self, route: Option<&aonw_domain::QueuedMovePath>) {
        match route {
            None => self.u8(0),
            Some(route) => {
                self.u8(1);
                self.coordinate(route.target());
                self.steps(route.steps());
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        GameState, HexCoord, HexGridBounds, MovementUnits, PlayerId, StateRevision, Unit, UnitId,
        UnitKind, UnitOccupancyPolicy,
    };

    use super::digest_state;

    fn unit(id: &str, position: HexCoord) -> Unit {
        Unit::builder(
            UnitId::new(id).expect("id"),
            PlayerId::new("player-1").expect("player"),
            UnitKind::Commander,
            "unit.commander",
            position,
            MovementUnits::new(10),
        )
        .build()
        .expect("unit")
    }

    #[test]
    fn digest_is_independent_of_entity_input_order() {
        let bounds = HexGridBounds::new(3, 3).expect("bounds");
        let left = GameState::try_new(
            StateRevision::new(1),
            2,
            bounds,
            UnitOccupancyPolicy::Exclusive,
            [
                unit("b", HexCoord::new(1, 1)),
                unit("a", HexCoord::new(0, 0)),
            ],
        )
        .expect("state");
        let right = GameState::try_new(
            StateRevision::new(1),
            2,
            bounds,
            UnitOccupancyPolicy::Exclusive,
            [
                unit("a", HexCoord::new(0, 0)),
                unit("b", HexCoord::new(1, 1)),
            ],
        )
        .expect("state");
        assert_eq!(digest_state(&left), digest_state(&right));
        assert_eq!(
            digest_state(&left).to_string(),
            "d23fad065c66ce354727b8bd29c8a80b671f9e6c0956b9cf4887d70d9d39756c"
        );
    }

    #[test]
    fn digest_includes_reversible_skip_balance() {
        let bounds = HexGridBounds::new(3, 3).expect("bounds");
        let base = unit("unit", HexCoord::new(1, 1));
        let skipped = Unit::builder(
            base.id().clone(),
            base.owner_player_id().clone(),
            base.kind(),
            base.name(),
            base.position(),
            MovementUnits::ZERO,
        )
        .with_skipped_movement_restore(Some(MovementUnits::new(10)))
        .build()
        .expect("skipped unit");
        let base_state = GameState::try_new(
            StateRevision::new(1),
            2,
            bounds,
            UnitOccupancyPolicy::Exclusive,
            [base],
        )
        .expect("base state");
        let skipped_state = GameState::try_new(
            StateRevision::new(1),
            2,
            bounds,
            UnitOccupancyPolicy::Exclusive,
            [skipped],
        )
        .expect("skipped state");

        assert_ne!(digest_state(&base_state), digest_state(&skipped_state));
    }
}
