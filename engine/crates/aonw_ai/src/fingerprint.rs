use core::fmt;

use aonw_domain::PlayerId;
use aonw_local_runtime::{MoveUnitRequest, SessionStamp};
use sha2::{Digest, Sha256};

use crate::{AiRngTrace, PlannedCommand, PlanningBudget};

/// SHA-256 identity of one deterministic plan for one canonical state.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct PlanFingerprint([u8; 32]);

impl PlanFingerprint {
    pub(crate) fn for_command(
        stamp: SessionStamp,
        recipient: &PlayerId,
        command: &PlannedCommand,
    ) -> Self {
        let mut digest = Sha256::new();
        digest.update(b"aonw-ai-plan");
        hash_context(&mut digest, stamp, recipient);
        match command {
            PlannedCommand::MoveUnit(request) => hash_move(&mut digest, request),
        }
        Self(digest.finalize().into())
    }

    /// Returns fingerprint bytes.
    #[must_use]
    pub const fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

/// SHA-256 identity of deterministic search inputs, draws, result, and work.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct SearchFingerprint([u8; 32]);

impl SearchFingerprint {
    pub(crate) fn for_search(input: SearchFingerprintInput<'_>) -> Self {
        let mut digest = Sha256::new();
        digest.update(b"aonw-ai-search");
        hash_text(&mut digest, input.strategy);
        hash_context(&mut digest, input.stamp, input.recipient);
        digest.update(input.base_seed.to_le_bytes());
        match input.budget {
            Some(budget) => {
                digest.update([1]);
                digest.update(budget.iterations().to_le_bytes());
                digest.update(budget.max_nodes().to_le_bytes());
                digest.update(budget.max_depth().to_le_bytes());
            }
            None => digest.update([0]),
        }
        digest.update(input.trace.initial_state().to_le_bytes());
        digest.update(input.trace.final_state().to_le_bytes());
        digest.update(
            u64::try_from(input.trace.draws().len())
                .unwrap_or(u64::MAX)
                .to_le_bytes(),
        );
        for draw in input.trace.draws() {
            digest.update(draw.to_le_bytes());
        }
        digest.update(
            u64::try_from(input.counters.len())
                .unwrap_or(u64::MAX)
                .to_le_bytes(),
        );
        for counter in input.counters {
            digest.update(counter.to_le_bytes());
        }
        digest.update(input.plan.as_bytes());
        Self(digest.finalize().into())
    }

    /// Returns fingerprint bytes.
    #[must_use]
    pub const fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

#[derive(Clone, Copy)]
pub(crate) struct SearchFingerprintInput<'a> {
    pub(crate) stamp: SessionStamp,
    pub(crate) recipient: &'a PlayerId,
    pub(crate) strategy: &'a str,
    pub(crate) base_seed: u32,
    pub(crate) budget: Option<PlanningBudget>,
    pub(crate) trace: &'a AiRngTrace,
    pub(crate) counters: &'a [u64],
    pub(crate) plan: PlanFingerprint,
}

impl fmt::Display for SearchFingerprint {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write_hex(formatter, &self.0)
    }
}

impl fmt::Display for PlanFingerprint {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write_hex(formatter, &self.0)
    }
}

fn hash_context(digest: &mut Sha256, stamp: SessionStamp, recipient: &PlayerId) {
    digest.update(stamp.revision.get().to_le_bytes());
    digest.update(stamp.state_digest.as_bytes());
    digest.update(stamp.map_hash.as_bytes());
    digest.update(stamp.ruleset_hash.as_bytes());
    hash_text(digest, recipient.as_str());
}

fn hash_move(digest: &mut Sha256, request: &MoveUnitRequest) {
    digest.update([0]);
    digest.update(request.expected_revision.to_le_bytes());
    hash_text(digest, request.unit_id.as_str());
    digest.update(request.target.col().to_le_bytes());
    digest.update(request.target.row().to_le_bytes());
}

fn hash_text(digest: &mut Sha256, value: &str) {
    digest.update(u64::try_from(value.len()).unwrap_or(u64::MAX).to_le_bytes());
    digest.update(value.as_bytes());
}

fn write_hex(formatter: &mut fmt::Formatter<'_>, bytes: &[u8; 32]) -> fmt::Result {
    for byte in bytes {
        write!(formatter, "{byte:02x}")?;
    }
    Ok(())
}
