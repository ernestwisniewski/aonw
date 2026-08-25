use aonw_content::ContentHash;
use aonw_domain::{GameState, StateRevision};

use super::{
    CommandRejectionCode, DomainRejection, DomainTransition, DomainTransitionParts,
    ExecutionEvidence,
};
use crate::StateDigest;

impl DomainTransition {
    pub(crate) fn accepted(
        state: GameState,
        events: Box<[super::DomainEvent]>,
        evidence: Option<ExecutionEvidence>,
        map_hash: ContentHash,
        ruleset_hash: ContentHash,
    ) -> Self {
        Self {
            digest: crate::state_digest::digest_state(&state),
            state,
            rejection: None,
            events,
            evidence,
            map_hash,
            ruleset_hash,
        }
    }

    pub(crate) fn rejected(
        state: GameState,
        code: CommandRejectionCode,
        map_hash: ContentHash,
        ruleset_hash: ContentHash,
    ) -> Self {
        Self {
            digest: crate::state_digest::digest_state(&state),
            state,
            rejection: Some(DomainRejection { code }),
            events: Box::new([]),
            evidence: None,
            map_hash,
            ruleset_hash,
        }
    }

    pub(crate) fn with_evidence(mut self, evidence: Option<ExecutionEvidence>) -> Self {
        self.evidence = evidence;
        self
    }

    /// Returns whether the command was accepted.
    #[must_use]
    pub const fn is_accepted(&self) -> bool {
        self.rejection.is_none()
    }

    /// Returns the unchanged or next canonical state.
    #[must_use]
    pub const fn state(&self) -> &GameState {
        &self.state
    }

    /// Returns a stable rejection when the command was not accepted.
    #[must_use]
    pub const fn rejection(&self) -> Option<DomainRejection> {
        self.rejection
    }

    /// Returns ordered domain events.
    #[must_use]
    pub const fn events(&self) -> &[super::DomainEvent] {
        &self.events
    }

    /// Returns exact command execution evidence.
    #[must_use]
    pub const fn evidence(&self) -> Option<&ExecutionEvidence> {
        self.evidence.as_ref()
    }

    /// Returns the revision of the returned state.
    #[must_use]
    pub const fn revision(&self) -> StateRevision {
        self.state.revision()
    }

    /// Returns canonical state identity.
    #[must_use]
    pub const fn digest(&self) -> StateDigest {
        self.digest
    }

    /// Returns the exact map identity used by the transition.
    #[must_use]
    pub const fn map_hash(&self) -> ContentHash {
        self.map_hash
    }

    /// Returns the exact ruleset identity used by the transition.
    #[must_use]
    pub const fn ruleset_hash(&self) -> ContentHash {
        self.ruleset_hash
    }

    /// Consumes the transition without cloning its canonical state.
    #[must_use]
    pub fn into_parts(self) -> DomainTransitionParts {
        DomainTransitionParts {
            state: self.state,
            rejection: self.rejection,
            events: self.events,
            evidence: self.evidence,
            digest: self.digest,
            map_hash: self.map_hash,
            ruleset_hash: self.ruleset_hash,
        }
    }
}
