use serde::{Deserialize, Serialize};

use crate::CoordinateDto;

/// One current client protocol request.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientRequestDto {
    /// Client protocol version.
    pub api_version: u16,
    /// Requested lifecycle, query, or command operation.
    pub request: ClientRequestBodyDto,
}

/// Operations supported by the current local client protocol.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientRequestBodyDto {
    /// Returns protocol and engine capabilities.
    Capabilities,
    /// Opens a session from strict authored content.
    OpenSession {
        /// Strict canonical map document.
        map_document: String,
        /// Strict current scenario document.
        scenario_document: String,
        /// Player receiving the local view.
        actor_player_id: String,
    },
    /// Closes the current session.
    CloseSession,
    /// Returns a complete recipient-safe snapshot.
    Snapshot,
    /// Executes one recipient-safe query.
    Query {
        /// Query payload.
        query: ClientQueryDto,
    },
    /// Dispatches one authoritative command.
    Dispatch {
        /// Command payload.
        command: ClientCommandDto,
    },
    /// Exports the current canonical save document.
    ExportSave,
    /// Opens a current save against its canonical map.
    OpenSave {
        /// Strict canonical map document.
        map_document: String,
        /// Strict current save document.
        save_document: String,
    },
    /// Exports the current deterministic replay segment.
    ExportReplay,
    /// Verifies a replay against its canonical map.
    VerifyReplay {
        /// Strict canonical map document.
        map_document: String,
        /// Strict current replay document.
        replay_document: String,
    },
}

/// Authoritative commands available to local clients.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientCommandDto {
    /// Moves one controlled unit toward a map coordinate.
    MoveUnit {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit receiving the command.
        unit_id: String,
        /// Requested target.
        target: CoordinateDto,
    },
    /// Clears cancellable work and orders owned by one unit.
    CancelUnitAction {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit receiving the command.
        unit_id: String,
    },
    /// Consumes one unit's movement for the current turn.
    SkipUnitTurn {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit receiving the command.
        unit_id: String,
    },
    /// Fortifies one available unit.
    FortifyUnit {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit receiving the command.
        unit_id: String,
    },
}

/// Read-only queries available to local clients.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientQueryDto {
    /// Returns every current-turn reachable coordinate.
    Reachable {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit inspected by the query.
        unit_id: String,
    },
    /// Plans a deterministic route toward one coordinate.
    RoutePlan {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit inspected by the query.
        unit_id: String,
        /// Requested target.
        target: CoordinateDto,
    },
}
