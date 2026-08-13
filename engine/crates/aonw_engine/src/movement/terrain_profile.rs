use aonw_content::TerrainType;

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub(super) struct TerrainProfile {
    pub(super) base: Option<TerrainType>,
    features: u8,
}

impl TerrainProfile {
    const FOREST: u8 = 1 << 0;
    const JUNGLE: u8 = 1 << 1;
    const HILLS: u8 = 1 << 2;
    const WETLANDS: u8 = 1 << 3;
    const MOUNTAIN: u8 = 1 << 4;

    pub(super) fn from_terrains(terrains: &[TerrainType]) -> Self {
        let mut profile = Self::default();
        for terrain in terrains {
            match terrain {
                TerrainType::Mountain => profile.features |= Self::MOUNTAIN,
                TerrainType::Forest => profile.features |= Self::FOREST,
                TerrainType::Jungle => profile.features |= Self::JUNGLE,
                TerrainType::Hills => profile.features |= Self::HILLS,
                TerrainType::Wetlands => profile.features |= Self::WETLANDS,
                TerrainType::River => {}
                base => profile.select_base(*base),
            }
        }
        if profile.base.is_none() {
            profile.base = if profile.has_any(Self::FOREST | Self::JUNGLE | Self::WETLANDS) {
                Some(TerrainType::Grassland)
            } else if profile.has(Self::HILLS) {
                Some(TerrainType::Plains)
            } else {
                None
            };
        }
        profile
    }

    fn select_base(&mut self, candidate: TerrainType) {
        if self.base.is_none() || self.base.is_some_and(is_open_water) && !is_open_water(candidate)
        {
            self.base = Some(candidate);
        }
    }

    pub(super) const fn has_forest(self) -> bool {
        self.has(Self::FOREST)
    }

    pub(super) const fn has_jungle(self) -> bool {
        self.has(Self::JUNGLE)
    }

    pub(super) const fn has_hills(self) -> bool {
        self.has(Self::HILLS)
    }

    pub(super) const fn has_wetlands(self) -> bool {
        self.has(Self::WETLANDS)
    }

    pub(super) const fn has_mountain(self) -> bool {
        self.has(Self::MOUNTAIN)
    }

    const fn has(self, flag: u8) -> bool {
        self.features & flag != 0
    }

    const fn has_any(self, flags: u8) -> bool {
        self.features & flags != 0
    }
}

const fn is_open_water(terrain: TerrainType) -> bool {
    matches!(terrain, TerrainType::Ocean | TerrainType::Lake)
}
