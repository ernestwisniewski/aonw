//! Current-only recipient-safe client protocol shared by native adapters.

mod codec;
mod map;
mod request;
mod response;

pub use codec::{ClientCodecError, MAX_CLIENT_REQUEST_JSON_BYTES, MAX_CLIENT_RESPONSE_JSON_BYTES};
pub use map::{
    MapGridLayoutDto, MapObjectiveTypeDto, MapObjectiveViewDto, MapResourceDto, MapTerrainDto,
    MapTileViewDto, MapViewDto,
};
pub use request::{ClientCommandDto, ClientQueryDto, ClientRequestBodyDto, ClientRequestDto};
pub use response::{
    AutoExploreOptionDto, CityExpansionCandidateDto, CityFoundingDraftViewDto,
    ClientCommandOutcomeDto, ClientCommandRejectionCodeDto, ClientCommandResultDto, ClientErrorDto,
    ClientEventDto, ClientEvidenceDto, ClientFeatureDto, ClientLogisticsEvidenceDto,
    ClientOutcomeDto, ClientQueryResultDto, ClientReplayVerificationDto, ClientResponseBodyDto,
    ClientResponseDto, ClientSessionStampDto, DetachmentOptionDto, MerchantDestinationOptionDto,
    MovementSearchMetricsDto, MovementStepViewDto, OwnedCityPlanningViewDto, PendingActionViewDto,
    PlayerCityViewDto, PlayerTurnLifecycleViewDto, PlayerUnitViewDto, PlayerViewPatchDto,
    PlayerViewSnapshotDto, ReachableTileViewDto, UnitMovementExecutionDto,
};

/// The only client protocol version accepted by this build.
pub const CLIENT_API_VERSION: u16 = 5;
