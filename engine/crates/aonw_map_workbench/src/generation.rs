use core::fmt::Write as _;

use aonw_content::{
    GridLayout, MapDefinition, MapDocument, TerrainProfile, TerrainType, TileDefinition,
};
use aonw_domain::HexCoord;
use aonw_map_authoring::TerrainAuthoringProfile;
use serde::Serialize;
use sha2::{Digest, Sha256};

use crate::spec::{PersistedGenerationSpec, pretty_json};
use crate::{MapGenerationSpec, MapWorkbenchError};

const GENERATION_PROVENANCE_SCHEMA_VERSION: u64 = 1;
const GENERATED_DECORATION_PLAN_SCHEMA_VERSION: u64 = 1;

/// Complete deterministic document package returned to a persistence adapter.
#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GeneratedMapPackage {
    map_document: String,
    terrain_authoring_document: String,
    generation_document: String,
    generated_decoration_plan_document: String,
    map_content_hash: String,
    authoring_profile_hash: String,
    generation_spec_hash: String,
    generated_decoration_plan_hash: String,
}

#[allow(missing_docs)]
impl GeneratedMapPackage {
    /// Generates a canonical empty logical map and its authoring artifacts.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] if any generated aggregate or document
    /// violates its authoritative Rust model.
    pub fn generate(spec: &MapGenerationSpec) -> Result<Self, MapWorkbenchError> {
        let map_document = blank_map(spec)?;
        let map = map_document.map();
        let terrain_profile = TerrainAuthoringProfile::standard_v1(
            map,
            spec.hex_radius_meters(),
            spec.max_terrain_height_meters(),
        )?;
        let map_content_hash = map.content_hash()?.to_string();
        let authoring_profile_hash = terrain_profile.authoring_profile_hash()?.to_string();
        let generation_spec_hash = spec.spec_hash()?.to_string();
        let decoration_plan = GeneratedDecorationPlan {
            schema_version: GENERATED_DECORATION_PLAN_SCHEMA_VERSION,
            source_map_content_hash: &map_content_hash,
            generation_spec_hash: &generation_spec_hash,
            generator_id: spec.generator_id(),
            generator_version: spec.generator_version(),
            seed: spec.seed().to_string(),
            placements: [],
        };
        let decoration_bytes = serde_json::to_vec(&decoration_plan)?;
        let generated_decoration_plan_hash = sha256_hex(&decoration_bytes);
        let generation_document = pretty_json(&GenerationProvenance {
            schema_version: GENERATION_PROVENANCE_SCHEMA_VERSION,
            spec: PersistedGenerationSpec::from(spec),
            generation_spec_hash: &generation_spec_hash,
            map_content_hash: &map_content_hash,
            authoring_profile_hash: &authoring_profile_hash,
            generated_decoration_plan_hash: &generated_decoration_plan_hash,
        })?;
        Ok(Self {
            map_document: map_document.to_versioned_json()?,
            terrain_authoring_document: terrain_profile.to_versioned_json()?,
            generation_document,
            generated_decoration_plan_document: pretty_json(&decoration_plan)?,
            map_content_hash,
            authoring_profile_hash,
            generation_spec_hash,
            generated_decoration_plan_hash,
        })
    }

    #[must_use]
    pub fn map_document(&self) -> &str {
        &self.map_document
    }

    #[must_use]
    pub fn terrain_authoring_document(&self) -> &str {
        &self.terrain_authoring_document
    }

    #[must_use]
    pub fn generation_document(&self) -> &str {
        &self.generation_document
    }

    #[must_use]
    pub fn generated_decoration_plan_document(&self) -> &str {
        &self.generated_decoration_plan_document
    }

    #[must_use]
    pub fn map_content_hash(&self) -> &str {
        &self.map_content_hash
    }

    #[must_use]
    pub fn authoring_profile_hash(&self) -> &str {
        &self.authoring_profile_hash
    }

    #[must_use]
    pub fn generation_spec_hash(&self) -> &str {
        &self.generation_spec_hash
    }

    #[must_use]
    pub fn generated_decoration_plan_hash(&self) -> &str {
        &self.generated_decoration_plan_hash
    }
}

fn blank_map(spec: &MapGenerationSpec) -> Result<MapDocument, MapWorkbenchError> {
    let terrain = TerrainProfile::try_new(vec![TerrainType::Grassland])?;
    let mut tiles = Vec::with_capacity(usize::from(spec.cols()) * usize::from(spec.rows()));
    for row in 0..spec.rows() {
        for col in 0..spec.cols() {
            tiles.push(TileDefinition::try_new(
                HexCoord::new(i32::from(col), i32::from(row)),
                terrain.clone(),
                Vec::new(),
                0,
            )?);
        }
    }
    let map = MapDefinition::try_new(
        spec.map_id(),
        GridLayout::OddQFlatTop,
        spec.cols(),
        spec.rows(),
        tiles,
        Vec::new(),
    )?;
    Ok(MapDocument::try_new(map, spec.default_zoom())?)
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GenerationProvenance<'a> {
    schema_version: u64,
    spec: PersistedGenerationSpec<'a>,
    generation_spec_hash: &'a str,
    map_content_hash: &'a str,
    authoring_profile_hash: &'a str,
    generated_decoration_plan_hash: &'a str,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedDecorationPlan<'a> {
    schema_version: u64,
    source_map_content_hash: &'a str,
    generation_spec_hash: &'a str,
    generator_id: &'a str,
    generator_version: u16,
    seed: String,
    placements: [GeneratedDecorationPlacement; 0],
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedDecorationPlacement {
    placement_id: String,
    kind: String,
    source_col: i32,
    source_row: i32,
    x_meters: f64,
    y_meters: f64,
    z_meters: f64,
    rotation_degrees_y: f64,
    scale: f64,
}

fn sha256_hex(bytes: &[u8]) -> String {
    let mut output = String::with_capacity(64);
    for byte in Sha256::digest(bytes) {
        write!(&mut output, "{byte:02x}").expect("writing to String cannot fail");
    }
    output
}
