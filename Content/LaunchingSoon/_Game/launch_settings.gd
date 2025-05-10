extends Node
class_name LaunchSettings

static var CARGO_TO_FULL:int = 23
static var WARNINGS_TO_FIRE:int = 3
static var BASE_PLACEMENT_SCORE:float = 1.0
static var PENALTY_VALUE:float = 1.0

enum PLACE_TIER{NONE,SLOPPY, DECENT, BASED, LEGEND}
static var MAX_PERFECT_PLACE_ACCURACY:float = 0.1
static var LEGEND_PLACE_RANGE:float = 0.1
static var LEGEND_MULTIPLIER:float = 5.0

static var BASED_PLACE_RANGE:float = 0.3
static var BASED_MULTIPLIER:float = 3.0

static var DECENT_PLACE_RANGE:float = 0.7
static var DECENT_MULTIPLIER:float = 2.0

static var SLOPPY_PLACE_RANGE:float = 1.0
static var SLOPPY_MULTIPLIER:float = 1.0

static var GRAVITY_STRENGTH:float = 9.8

static func get_place_accuracy(place_tier:PLACE_TIER) -> float:
	return float(place_tier)/PLACE_TIER.size()
	
static func get_score(place_tier:PLACE_TIER) -> float:
	match place_tier:
		PLACE_TIER.LEGEND:
			return BASE_PLACEMENT_SCORE * LEGEND_MULTIPLIER
		PLACE_TIER.BASED:
			return BASE_PLACEMENT_SCORE * BASED_MULTIPLIER
		PLACE_TIER.DECENT:
			return BASE_PLACEMENT_SCORE * DECENT_MULTIPLIER
		PLACE_TIER.SLOPPY:
			return BASE_PLACEMENT_SCORE * SLOPPY_MULTIPLIER
		PLACE_TIER.NONE:
			return 0
	return 0

static func get_max_placement_score() -> float:
	return BASE_PLACEMENT_SCORE * LEGEND_MULTIPLIER
	
static func get_max_score() -> float:
	return BASE_PLACEMENT_SCORE * LEGEND_MULTIPLIER * CARGO_TO_FULL
	
static func get_lose_score() -> float:
#	half of lowest possible score achievable through victory
	return BASE_PLACEMENT_SCORE * CARGO_TO_FULL * 0.5
