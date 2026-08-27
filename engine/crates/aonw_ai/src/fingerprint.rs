use core::fmt;

use aonw_domain::PlayerId;
use aonw_local_runtime::{MoveUnitRequest, SessionStamp};
use sha2::{Digest, Sha256};

use crate::PlannedCommand;

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
        digest.update(stamp.revision.get().to_le_bytes());
        digest.update(stamp.state_digest.as_bytes());
        digest.update(stamp.map_hash.as_bytes());
        digest.update(stamp.ruleset_hash.as_bytes());
        hash_text(&mut digest, recipient.as_str());
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

impl fmt::Display for PlanFingerprint {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        for byte in self.0 {
            write!(formatter, "{byte:02x}")?;
        }
        Ok(())
    }
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
