use crate::{CityId, HexCoord, PlayerId};

/// Persisted transport segment identity.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TransportKind {
    Road,
}

/// Current condition of a road.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TransportCondition {
    Operational,
    Pillaged,
}

/// One road segment occupying a coordinate.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TransportSegment {
    coordinate: HexCoord,
    kind: TransportKind,
    condition: TransportCondition,
    built_by_player_id: PlayerId,
    built_by_city_id: Option<CityId>,
}

impl TransportSegment {
    /// Constructs a road segment.
    #[must_use]
    pub const fn road(
        coordinate: HexCoord,
        condition: TransportCondition,
        built_by_player_id: PlayerId,
        built_by_city_id: Option<CityId>,
    ) -> Self {
        Self {
            coordinate,
            kind: TransportKind::Road,
            condition,
            built_by_player_id,
            built_by_city_id,
        }
    }

    /// Returns the segment coordinate.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }

    /// Returns the persisted transport segment identity.
    #[must_use]
    pub const fn kind(&self) -> TransportKind {
        self.kind
    }

    /// Returns whether the road can reduce movement cost.
    #[must_use]
    pub const fn is_operational(&self) -> bool {
        matches!(self.condition, TransportCondition::Operational)
    }

    /// Returns the segment condition.
    #[must_use]
    pub const fn condition(&self) -> TransportCondition {
        self.condition
    }

    /// Returns the builder player.
    #[must_use]
    pub const fn built_by_player_id(&self) -> &PlayerId {
        &self.built_by_player_id
    }

    /// Returns the owning builder city when present.
    #[must_use]
    pub const fn built_by_city_id(&self) -> Option<&CityId> {
        self.built_by_city_id.as_ref()
    }
}

/// Immutable road network sorted by coordinate.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct TransportNetwork {
    segments: Box<[TransportSegment]>,
}

impl TransportNetwork {
    /// Normalizes segments and rejects duplicate coordinates.
    ///
    /// # Errors
    ///
    /// Returns the duplicated coordinate.
    pub fn try_new(segments: impl IntoIterator<Item = TransportSegment>) -> Result<Self, HexCoord> {
        let mut segments = segments.into_iter().collect::<Vec<_>>();
        segments.sort_unstable_by_key(TransportSegment::coordinate);
        if let Some(pair) = segments
            .windows(2)
            .find(|pair| pair[0].coordinate() == pair[1].coordinate())
        {
            return Err(pair[0].coordinate());
        }
        Ok(Self {
            segments: segments.into_boxed_slice(),
        })
    }

    /// Returns the segment at a coordinate.
    #[must_use]
    pub fn at(&self, coordinate: HexCoord) -> Option<&TransportSegment> {
        self.segments
            .binary_search_by_key(&coordinate, TransportSegment::coordinate)
            .ok()
            .map(|index| &self.segments[index])
    }

    /// Returns segments in coordinate order.
    #[must_use]
    pub const fn segments(&self) -> &[TransportSegment] {
        &self.segments
    }
}
