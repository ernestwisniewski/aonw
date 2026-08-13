class_name AonwResourceCatalog
extends RefCounted

const NAMES := [
	"wheat", "fish", "deer", "sheep", "rice", "cow", "apple", "banana",
	"citrus", "gold", "silver", "gems", "silk", "spices", "cotton",
	"grapes", "ivory", "pearls", "coffee", "cocoa", "tobacco", "sugar",
	"iron", "coal", "oil", "aluminium", "uranium", "horses", "marble",
]

static func contains(value: String) -> bool:
	return NAMES.has(value)
