use aonw_contracts::TechnologyIdDto;
use aonw_contracts::client::{
    ClientCommandDto, ClientQueryDto, ClientQueryResultDto, ClientRequestBodyDto,
    ClientResponseBodyDto, ResearchOptionDto, TechnologyAvailabilityDto,
};

use super::stamp;

pub(super) fn requests() -> [ClientRequestBodyDto; 2] {
    [
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ResearchOptions {
                expected_revision: 8,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SelectTechnology {
                expected_revision: 8,
                technology_id: TechnologyIdDto::Agriculture,
            },
        },
    ]
}

pub(super) fn response() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::ResearchOptions {
            stamp: stamp(),
            player_id: "player-1".to_owned(),
            active_technology_id: None,
            science_overflow: 3,
            options: vec![ResearchOptionDto {
                technology_id: TechnologyIdDto::Agriculture,
                availability: TechnologyAvailabilityDto::Available,
                effective_cost: 10,
                progress: 2,
                boost_discount_basis_points: 2_500,
                prerequisites: Vec::new(),
                blocked_by: Vec::new(),
                unlocks: Vec::new(),
            }],
        },
    }
}
