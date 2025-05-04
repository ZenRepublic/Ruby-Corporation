extends Node
class_name LaunchSettings

static var CARGO_TO_FULL:int = 20
static var MAX_PLACEMENT_SCORE:int = 10
static var PERFECT_DROP_MULTIPLIER:float = 2.0

static var MAX_PERFECT_PLACE_ACCURACY:float = 0.1
static var MAX_PLACE_ACCURACY:float = 1.0

static var WARNINGS_TO_FIRE:int = 3

static var GRAVITY_STRENGTH:float = 9.8

static func get_max_placement_score() -> int:
	return ceili(MAX_PLACEMENT_SCORE * PERFECT_DROP_MULTIPLIER)

static func get_max_total_score() -> int:
	return ceili(CARGO_TO_FULL * MAX_PLACEMENT_SCORE * PERFECT_DROP_MULTIPLIER)
