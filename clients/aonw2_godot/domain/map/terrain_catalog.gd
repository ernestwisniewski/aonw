class_name AonwTerrainCatalog
extends RefCounted

const NAMES := [
	"ocean", "coast", "lake", "plains", "grassland", "desert", "tundra",
	"snow", "mountain", "hills", "wetlands", "jungle", "forest", "river",
]

static func contains(value: String) -> bool:
	return NAMES.has(value)
