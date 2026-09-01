use aonw_domain::{
    City, CityFoundingDraft, CityId, FogVisibility, GameState, HexCoord, PlayerId, UnitId,
};

/// Private city-planning fields visible only to the owning recipient.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct OwnedCityPlanningView {
    population: i64,
    worked_hexes: Box<[HexCoord]>,
    preferred_expansion_hex: Option<HexCoord>,
}

impl OwnedCityPlanningView {
    /// Returns current population.
    #[must_use]
    pub const fn population(&self) -> i64 {
        self.population
    }
    /// Returns canonical manual worked coordinates.
    #[must_use]
    pub const fn worked_hexes(&self) -> &[HexCoord] {
        &self.worked_hexes
    }
    /// Returns the private preferred expansion coordinate.
    #[must_use]
    pub const fn preferred_expansion_hex(&self) -> Option<HexCoord> {
        self.preferred_expansion_hex
    }
}

/// Recipient-safe city projection.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerCityView {
    id: CityId,
    owner_player_id: PlayerId,
    name: Box<str>,
    center: HexCoord,
    visible_controlled_hexes: Box<[HexCoord]>,
    owned_planning: Option<OwnedCityPlanningView>,
}

impl PlayerCityView {
    fn from_city(city: &City, state: &GameState, actor: &PlayerId) -> Self {
        let owned = city.owner_player_id() == actor;
        let visible_controlled_hexes = city
            .controlled_hexes()
            .iter()
            .copied()
            .filter(|coordinate| {
                owned || state.fog_of_war().visibility(actor, *coordinate) != FogVisibility::Hidden
            })
            .collect::<Vec<_>>();
        let owned_planning = owned.then(|| {
            let mut worked_hexes = city.worked_hexes().to_vec();
            worked_hexes.sort_unstable();
            OwnedCityPlanningView {
                population: city.population(),
                worked_hexes: worked_hexes.into_boxed_slice(),
                preferred_expansion_hex: city.preferred_expansion_hex(),
            }
        });
        Self {
            id: city.id().clone(),
            owner_player_id: city.owner_player_id().clone(),
            name: city.name().into(),
            center: city.center(),
            visible_controlled_hexes: visible_controlled_hexes.into_boxed_slice(),
            owned_planning,
        }
    }

    /// Returns city identity.
    #[must_use]
    pub const fn id(&self) -> &CityId {
        &self.id
    }
    /// Returns visible owner identity.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the public name.
    #[must_use]
    pub fn name(&self) -> &str {
        &self.name
    }
    /// Returns the public center.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }
    /// Returns controlled coordinates discovered by this recipient.
    #[must_use]
    pub const fn visible_controlled_hexes(&self) -> &[HexCoord] {
        &self.visible_controlled_hexes
    }
    /// Returns private planning fields only for an owned city.
    #[must_use]
    pub const fn owned_planning(&self) -> Option<&OwnedCityPlanningView> {
        self.owned_planning.as_ref()
    }
}

/// Recipient-owned city-founding workflow.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityFoundingDraftView {
    founder_unit_id: UnitId,
    center: HexCoord,
    controlled_hexes: Box<[HexCoord]>,
}

impl CityFoundingDraftView {
    fn from_draft(draft: &CityFoundingDraft) -> Self {
        let mut controlled_hexes = draft.controlled_hexes().to_vec();
        controlled_hexes.sort_unstable();
        Self {
            founder_unit_id: draft.unit_id().clone(),
            center: draft.center(),
            controlled_hexes: controlled_hexes.into_boxed_slice(),
        }
    }
    /// Returns founder identity.
    #[must_use]
    pub const fn founder_unit_id(&self) -> &UnitId {
        &self.founder_unit_id
    }
    /// Returns the immutable center.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }
    /// Returns canonical current selection.
    #[must_use]
    pub const fn controlled_hexes(&self) -> &[HexCoord] {
        &self.controlled_hexes
    }
}

pub(crate) fn visible_cities(state: &GameState, actor: &PlayerId) -> Vec<PlayerCityView> {
    state
        .cities()
        .iter()
        .filter(|city| {
            city.owner_player_id() == actor
                || state.fog_of_war().visibility(actor, city.center()) != FogVisibility::Hidden
        })
        .map(|city| PlayerCityView::from_city(city, state, actor))
        .collect()
}

pub(crate) fn city_founding_draft(
    state: &GameState,
    actor: &PlayerId,
) -> Option<CityFoundingDraftView> {
    state
        .interaction()
        .city_founding_draft()
        .filter(|draft| draft.owner_player_id() == actor)
        .map(CityFoundingDraftView::from_draft)
}
