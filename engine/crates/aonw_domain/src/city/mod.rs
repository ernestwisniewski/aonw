use crate::{CityId, HexCoord, PlayerId};

/// City data required by world topology, visibility, and entry rules.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct City {
    id: CityId,
    owner_player_id: PlayerId,
    center: HexCoord,
    controlled_hexes: Box<[HexCoord]>,
}

impl City {
    /// Constructs a city movement slice and normalizes controlled coordinates.
    #[must_use]
    pub fn new(
        id: CityId,
        owner_player_id: PlayerId,
        center: HexCoord,
        controlled_hexes: impl IntoIterator<Item = HexCoord>,
    ) -> Self {
        let mut controlled_hexes = controlled_hexes.into_iter().collect::<Vec<_>>();
        controlled_hexes.sort_unstable();
        controlled_hexes.dedup();
        controlled_hexes.retain(|coordinate| *coordinate != center);
        Self {
            id,
            owner_player_id,
            center,
            controlled_hexes: controlled_hexes.into_boxed_slice(),
        }
    }

    /// Returns the city identifier.
    #[must_use]
    pub const fn id(&self) -> &CityId {
        &self.id
    }

    /// Returns the current owner.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }

    /// Returns the city-center coordinate.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }

    /// Returns controlled coordinates in deterministic order.
    #[must_use]
    pub const fn controlled_hexes(&self) -> &[HexCoord] {
        &self.controlled_hexes
    }
}
