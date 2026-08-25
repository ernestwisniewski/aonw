use core::cmp::Ordering;

use aonw_domain::{CityId, HexCoord, UnitId};

use crate::player_view::{
    CityFoundingDraftView, PendingActionView, PlayerCityView, PlayerFieldImprovementView,
    PlayerRoadView, PlayerTurnLifecycleView, PlayerUnitView,
};

/// Recipient-safe view delta produced by one dispatch.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerViewPatch {
    /// Revision the patch applies to.
    pub from_revision: u64,
    /// Revision after the patch.
    pub to_revision: u64,
    /// Replacement turn projection when lifecycle state changed.
    pub turn_lifecycle: Option<PlayerTurnLifecycleView>,
    /// New or changed visible units.
    pub upserted_units: Box<[PlayerUnitView]>,
    /// Units no longer visible.
    pub removed_unit_ids: Box<[UnitId]>,
    /// New or changed cities known to this recipient.
    pub upserted_cities: Box<[PlayerCityView]>,
    /// Cities no longer known to this recipient.
    pub removed_city_ids: Box<[CityId]>,
    /// New or changed field improvements known to the recipient.
    pub upserted_field_improvements: Box<[PlayerFieldImprovementView]>,
    /// Field improvements no longer known to the recipient.
    pub removed_field_improvement_coordinates: Box<[HexCoord]>,
    /// New or changed roads known to the recipient.
    pub upserted_roads: Box<[PlayerRoadView]>,
    /// Roads no longer known to the recipient.
    pub removed_road_coordinates: Box<[HexCoord]>,
    /// Current action awaiting input from this recipient.
    pub pending_action: Option<PendingActionView>,
    /// Current recipient-owned city-founding workflow.
    pub city_founding_draft: Option<CityFoundingDraftView>,
}

pub(crate) struct ProjectedView {
    turn: PlayerTurnLifecycleView,
    units: Vec<PlayerUnitView>,
    cities: Vec<PlayerCityView>,
    field_improvements: Vec<PlayerFieldImprovementView>,
    roads: Vec<PlayerRoadView>,
}

impl ProjectedView {
    pub(crate) fn new(
        turn: PlayerTurnLifecycleView,
        units: Vec<PlayerUnitView>,
        cities: Vec<PlayerCityView>,
        field_improvements: Vec<PlayerFieldImprovementView>,
        roads: Vec<PlayerRoadView>,
    ) -> Self {
        Self {
            turn,
            units,
            cities,
            field_improvements,
            roads,
        }
    }
}

pub(crate) fn diff_view(
    from_revision: u64,
    to_revision: u64,
    before: ProjectedView,
    after: ProjectedView,
    pending_action: Option<PendingActionView>,
    city_founding_draft: Option<CityFoundingDraftView>,
) -> PlayerViewPatch {
    debug_assert!(
        before
            .units
            .windows(2)
            .all(|pair| pair[0].id() < pair[1].id())
    );
    debug_assert!(
        after
            .units
            .windows(2)
            .all(|pair| pair[0].id() < pair[1].id())
    );
    let before_turn = before.turn;
    let after_turn = after.turn;
    let before_cities = before.cities;
    let after_cities = after.cities;
    let before_improvements = before.field_improvements;
    let after_improvements = after.field_improvements;
    let before_roads = before.roads;
    let after_roads = after.roads;
    let mut before = before.units.into_iter().peekable();
    let mut after = after.units.into_iter().peekable();
    let mut upserted_units = Vec::new();
    let mut removed_unit_ids = Vec::new();
    while let (Some(previous), Some(current)) = (before.peek(), after.peek()) {
        match previous.id().cmp(current.id()) {
            Ordering::Less => {
                if let Some(previous) = before.next() {
                    removed_unit_ids.push(previous.id().clone());
                }
            }
            Ordering::Equal => {
                if let (Some(previous), Some(current)) = (before.next(), after.next())
                    && previous != current
                {
                    upserted_units.push(current);
                }
            }
            Ordering::Greater => {
                if let Some(current) = after.next() {
                    upserted_units.push(current);
                }
            }
        }
    }
    removed_unit_ids.extend(before.map(|unit| unit.id().clone()));
    upserted_units.extend(after);
    let (upserted_cities, removed_city_ids) = diff_cities(before_cities, after_cities);
    let (upserted_field_improvements, removed_field_improvement_coordinates) =
        diff_improvements(before_improvements, after_improvements);
    let (upserted_roads, removed_road_coordinates) = diff_roads(before_roads, after_roads);
    PlayerViewPatch {
        from_revision,
        to_revision,
        turn_lifecycle: (before_turn != after_turn).then_some(after_turn),
        upserted_units: upserted_units.into_boxed_slice(),
        removed_unit_ids: removed_unit_ids.into_boxed_slice(),
        upserted_cities,
        removed_city_ids,
        upserted_field_improvements,
        removed_field_improvement_coordinates,
        upserted_roads,
        removed_road_coordinates,
        pending_action,
        city_founding_draft,
    }
}

fn diff_improvements(
    before: Vec<PlayerFieldImprovementView>,
    after: Vec<PlayerFieldImprovementView>,
) -> (Box<[PlayerFieldImprovementView]>, Box<[HexCoord]>) {
    diff_coordinate_views(before, after, PlayerFieldImprovementView::coordinate)
}

fn diff_roads(
    before: Vec<PlayerRoadView>,
    after: Vec<PlayerRoadView>,
) -> (Box<[PlayerRoadView]>, Box<[HexCoord]>) {
    diff_coordinate_views(before, after, PlayerRoadView::coordinate)
}

fn diff_coordinate_views<View: Copy + Eq>(
    before: Vec<View>,
    after: Vec<View>,
    coordinate: impl Fn(View) -> HexCoord,
) -> (Box<[View]>, Box<[HexCoord]>) {
    let mut before = before.into_iter().peekable();
    let mut after = after.into_iter().peekable();
    let mut upserted = Vec::new();
    let mut removed = Vec::new();
    while let (Some(previous), Some(current)) = (before.peek(), after.peek()) {
        match coordinate(*previous).cmp(&coordinate(*current)) {
            Ordering::Less => removed.push(coordinate(before.next().expect("previous view"))),
            Ordering::Equal => {
                let previous = before.next().expect("previous view");
                let current = after.next().expect("current view");
                if previous != current {
                    upserted.push(current);
                }
            }
            Ordering::Greater => upserted.push(after.next().expect("current view")),
        }
    }
    removed.extend(before.map(coordinate));
    upserted.extend(after);
    (upserted.into_boxed_slice(), removed.into_boxed_slice())
}

fn diff_cities(
    before: Vec<PlayerCityView>,
    after: Vec<PlayerCityView>,
) -> (Box<[PlayerCityView]>, Box<[CityId]>) {
    debug_assert!(before.windows(2).all(|pair| pair[0].id() < pair[1].id()));
    debug_assert!(after.windows(2).all(|pair| pair[0].id() < pair[1].id()));
    let mut before = before.into_iter().peekable();
    let mut after = after.into_iter().peekable();
    let mut upserted = Vec::new();
    let mut removed = Vec::new();
    while let (Some(previous), Some(current)) = (before.peek(), after.peek()) {
        match previous.id().cmp(current.id()) {
            Ordering::Less => {
                if let Some(previous) = before.next() {
                    removed.push(previous.id().clone());
                }
            }
            Ordering::Equal => {
                if let (Some(previous), Some(current)) = (before.next(), after.next())
                    && previous != current
                {
                    upserted.push(current);
                }
            }
            Ordering::Greater => {
                if let Some(current) = after.next() {
                    upserted.push(current);
                }
            }
        }
    }
    removed.extend(before.map(|city| city.id().clone()));
    upserted.extend(after);
    (upserted.into_boxed_slice(), removed.into_boxed_slice())
}

#[cfg(test)]
mod tests {
    use aonw_domain::{HexCoord, MovementUnits, PlayerId, Unit, UnitId, UnitKind};

    use super::{ProjectedView, diff_view};
    use crate::player_view::{PlayerTurnLifecycleView, PlayerUnitView};

    #[test]
    fn sorted_view_diff_reports_updates_insertions_and_removals() {
        let before = vec![view("unit-a", 0), view("unit-b", 1)];
        let after = vec![view("unit-b", 2), view("unit-c", 3)];

        let turn = PlayerTurnLifecycleView::default();
        let patch = diff_view(
            4,
            5,
            ProjectedView::new(turn, before, Vec::new(), Vec::new(), Vec::new()),
            ProjectedView::new(turn, after, Vec::new(), Vec::new(), Vec::new()),
            None,
            None,
        );

        assert_eq!(patch.from_revision, 4);
        assert_eq!(patch.to_revision, 5);
        assert_eq!(
            patch
                .upserted_units
                .iter()
                .map(|unit| unit.id().as_str())
                .collect::<Vec<_>>(),
            ["unit-b", "unit-c"]
        );
        assert_eq!(
            patch
                .removed_unit_ids
                .iter()
                .map(UnitId::as_str)
                .collect::<Vec<_>>(),
            ["unit-a"]
        );
        assert_eq!(patch.pending_action, None);
    }

    fn view(id: &str, col: i32) -> PlayerUnitView {
        let unit = Unit::builder(
            UnitId::new(id).expect("unit id"),
            PlayerId::new("player-1").expect("player id"),
            UnitKind::Commander,
            "Commander",
            HexCoord::new(col, 0),
            MovementUnits::new(10),
        )
        .build()
        .expect("unit");
        PlayerUnitView::from_unit(&unit, true)
    }
}
