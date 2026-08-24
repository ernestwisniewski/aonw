use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, TroopKindDto};

/// One current client protocol request.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientRequestDto {
    /// Client protocol version shared by independently packaged adapters.
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
    /// Validates authored map content and returns its presentation read model.
    InspectMap {
        /// Strict canonical map document.
        map_document: String,
    },
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
    /// Starts or continues deterministic scout auto-exploration.
    AutoExploreUnit {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Scout receiving the command.
        unit_id: String,
    },
    /// Assigns a cyclic route between two owned cities.
    AssignMerchantTradeRoute {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Merchant receiving the route.
        unit_id: String,
        /// Owned destination city.
        destination_city_id: String,
    },
    /// Queues explicit merchant travel to an owned city.
    MoveMerchantToCity {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Merchant receiving the order.
        unit_id: String,
        /// Owned destination city.
        destination_city_id: String,
    },
    /// Detaches one troop into an engine-selected adjacent tile.
    DetachTroop {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Army unit losing the troop.
        unit_id: String,
        /// Troop kind to detach.
        troop_kind: TroopKindDto,
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
    /// Completes the authenticated participant's sequential turn.
    EndTurn {
        /// Revision observed by the client.
        expected_revision: u64,
    },
    /// Submits the authenticated participant's simultaneous turn.
    SubmitTurn {
        /// Revision observed by the client.
        expected_revision: u64,
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
    /// Returns engine-owned logistics options for one controlled unit.
    UnitLogisticsOptions {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit inspected by the query.
        unit_id: String,
    },
}
