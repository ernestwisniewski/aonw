@tool
class_name AonwTerrain3DControlCodec
extends RefCounted

const BASE_SHIFT := 27
const OVERLAY_SHIFT := 22
const BLEND_SHIFT := 14
const ANGLE_SHIFT := 10
const SCALE_SHIFT := 7
const HOLE_SHIFT := 2
const NAVIGATION_SHIFT := 1
const AUTOSHADER_SHIFT := 0

const TEXTURE_MASK := 0x1f
const BLEND_MASK := 0xff
const ANGLE_MASK := 0x0f
const SCALE_MASK := 0x07

static func encode(
	base_texture_id: int,
	overlay_texture_id: int = 0,
	blend: int = 0,
	angle: int = 0,
	scale: int = 0,
	hole: bool = false,
	navigation: bool = false,
	autoshader: bool = false,
) -> int:
	var bits := 0
	bits |= (base_texture_id & TEXTURE_MASK) << BASE_SHIFT
	bits |= (overlay_texture_id & TEXTURE_MASK) << OVERLAY_SHIFT
	bits |= (blend & BLEND_MASK) << BLEND_SHIFT
	bits |= (angle & ANGLE_MASK) << ANGLE_SHIFT
	bits |= (scale & SCALE_MASK) << SCALE_SHIFT
	bits |= int(hole) << HOLE_SHIFT
	bits |= int(navigation) << NAVIGATION_SHIFT
	bits |= int(autoshader) << AUTOSHADER_SHIFT
	return bits

static func encode_float(bits: int) -> float:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, bits)
	return bytes.decode_float(0)

static func decode_float(value: float) -> int:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, value)
	return bytes.decode_u32(0)

static func base_texture_id(bits: int) -> int:
	return (bits >> BASE_SHIFT) & TEXTURE_MASK

static func overlay_texture_id(bits: int) -> int:
	return (bits >> OVERLAY_SHIFT) & TEXTURE_MASK

static func blend_value(bits: int) -> int:
	return (bits >> BLEND_SHIFT) & BLEND_MASK

static func angle_value(bits: int) -> int:
	return (bits >> ANGLE_SHIFT) & ANGLE_MASK

static func scale_value(bits: int) -> int:
	return (bits >> SCALE_SHIFT) & SCALE_MASK

static func is_hole(bits: int) -> bool:
	return ((bits >> HOLE_SHIFT) & 1) == 1

static func has_navigation(bits: int) -> bool:
	return ((bits >> NAVIGATION_SHIFT) & 1) == 1

static func uses_autoshader(bits: int) -> bool:
	return ((bits >> AUTOSHADER_SHIFT) & 1) == 1
