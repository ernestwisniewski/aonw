use aonw_content::ContentHash;
use aonw_domain::{HexCoord, UnitId};
use aonw_engine::StateDigest;

use crate::{RuntimeQuery, RuntimeQueryResult, SessionStamp};

#[derive(Clone, Debug, Eq, PartialEq)]
enum QueryKind {
    Reachable,
    RoutePlan(HexCoord),
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct QueryCacheKey {
    revision: u64,
    expected_revision: u64,
    unit_id: UnitId,
    visibility_digest: StateDigest,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
    kind: QueryKind,
}

impl QueryCacheKey {
    fn new(stamp: SessionStamp, request: &RuntimeQuery) -> Self {
        let (expected_revision, unit_id, kind) = match request {
            RuntimeQuery::Reachable(request) => (
                request.expected_revision,
                request.unit_id.clone(),
                QueryKind::Reachable,
            ),
            RuntimeQuery::RoutePlan(request) => (
                request.expected_revision,
                request.unit_id.clone(),
                QueryKind::RoutePlan(request.target),
            ),
        };
        Self {
            revision: stamp.revision.get(),
            expected_revision,
            unit_id,
            visibility_digest: stamp.state_digest,
            map_hash: stamp.map_hash,
            ruleset_hash: stamp.ruleset_hash,
            kind,
        }
    }
}

/// Diagnostic counters for the bounded runtime query cache.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct QueryCacheStats {
    /// Exact-key cache hits.
    pub hits: u64,
    /// Queries requiring engine execution.
    pub misses: u64,
}

#[derive(Clone, Debug, Default)]
pub(crate) struct QueryCache {
    entry: Option<(QueryCacheKey, RuntimeQueryResult)>,
    stats: QueryCacheStats,
}

impl QueryCache {
    pub(crate) fn get(
        &mut self,
        stamp: SessionStamp,
        request: &RuntimeQuery,
    ) -> Option<RuntimeQueryResult> {
        let key = QueryCacheKey::new(stamp, request);
        if let Some((cached_key, result)) = &self.entry
            && cached_key == &key
        {
            self.stats.hits = self.stats.hits.saturating_add(1);
            return Some(result.clone());
        }
        self.stats.misses = self.stats.misses.saturating_add(1);
        None
    }

    pub(crate) fn insert(
        &mut self,
        stamp: SessionStamp,
        request: &RuntimeQuery,
        result: &RuntimeQueryResult,
    ) {
        self.entry = Some((QueryCacheKey::new(stamp, request), result.clone()));
    }

    pub(crate) fn clear(&mut self) {
        self.entry = None;
    }

    pub(crate) const fn stats(&self) -> QueryCacheStats {
        self.stats
    }
}
