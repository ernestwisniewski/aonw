use crate::PlayerId;

/// Ordered identity of one diplomatic relationship.
#[derive(Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct PlayerPair {
    first: PlayerId,
    second: PlayerId,
}

impl PlayerPair {
    /// Constructs a normalized pair, rejecting self-relations.
    #[must_use]
    pub fn new(left: PlayerId, right: PlayerId) -> Option<Self> {
        if left == right {
            return None;
        }
        let (first, second) = if left < right {
            (left, right)
        } else {
            (right, left)
        };
        Some(Self { first, second })
    }

    /// Returns the lexicographically first player.
    #[must_use]
    pub const fn first(&self) -> &PlayerId {
        &self.first
    }

    /// Returns the lexicographically second player.
    #[must_use]
    pub const fn second(&self) -> &PlayerId {
        &self.second
    }
}

/// Movement-relevant diplomacy state.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct Diplomacy {
    contacts: Box<[PlayerPair]>,
}

impl Diplomacy {
    /// Normalizes discovered contacts.
    #[must_use]
    pub fn new(contacts: impl IntoIterator<Item = PlayerPair>) -> Self {
        let mut contacts = contacts.into_iter().collect::<Vec<_>>();
        contacts.sort_unstable();
        contacts.dedup();
        Self {
            contacts: contacts.into_boxed_slice(),
        }
    }

    /// Returns all contact pairs in deterministic order.
    #[must_use]
    pub const fn contacts(&self) -> &[PlayerPair] {
        &self.contacts
    }

    /// Returns whether two players have met.
    #[must_use]
    pub fn has_contact(&self, left: &PlayerId, right: &PlayerId) -> bool {
        PlayerPair::new(left.clone(), right.clone())
            .is_some_and(|pair| self.contacts.binary_search(&pair).is_ok())
    }

    /// Merges newly discovered contacts.
    #[must_use]
    pub fn merging(&self, contacts: impl IntoIterator<Item = PlayerPair>) -> Self {
        Self::new(self.contacts.iter().cloned().chain(contacts))
    }
}
