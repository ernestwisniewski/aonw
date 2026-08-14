@tool
class_name AonwTerrainVisualCatalog
extends RefCounted

const FALLBACK_COLOR := Color("6c7178")
const FALLBACK_TEXTURE_ID := 2

# Terrain3D persists these identifiers in its control map. Keep existing values stable.
const TEXTURE_IDS := {
	"ocean": 0,
	"coast": 1,
	"lake": 1,
	"grassland": 2,
	"plains": 3,
	"forest": 4,
	"jungle": 4,
	"hills": 5,
	"mountain": 6,
	"desert": 7,
	"tundra": 8,
	"snow": 8,
	"wetlands": 9,
	"river": 1,
}

const COLORS := {
	"ocean": Color("245b91"),
	"coast": Color("4f9dc4"),
	"lake": Color("3f87b3"),
	"plains": Color("b7a66a"),
	"grassland": Color("6e9c54"),
	"desert": Color("c5a15f"),
	"tundra": Color("89938a"),
	"snow": Color("d9e2e3"),
	"mountain": Color("666b6f"),
	"hills": Color("8a7957"),
	"wetlands": Color("537a68"),
	"jungle": Color("356a43"),
	"forest": Color("3e7148"),
	"river": Color("3e83ad"),
}

const FEATURE_PRIORITY := ["river", "mountain", "forest", "jungle", "hills"]

static func dominant_terrain(terrains: Array) -> String:
	for feature in FEATURE_PRIORITY:
		if feature in terrains:
			return feature
	if terrains.is_empty():
		return "grassland"
	return str(terrains[0])

static func color_for(terrains: Array) -> Color:
	return COLORS.get(dominant_terrain(terrains), FALLBACK_COLOR)

static func texture_id_for(terrains: Array) -> int:
	return int(TEXTURE_IDS.get(dominant_terrain(terrains), FALLBACK_TEXTURE_ID))
