extends Node

const DISTRICT_COUNT: int = 5
const DAYS_PER_DISTRICT: int = 7

const DISTRICT_NAMES: Array[String] = [
	"Mahalle 1",
	"Mahalle 2",
	"Mahalle 3",
	"Mahalle 4",
	"Mahalle 5"
]

var unlocked_district_count: int = 1
var current_district: int = 0
var district_day_progress: Array[int] = [0, 0, 0, 0, 0]

# Day upgrades
var day_coin_bonus: int = 0
var day_patience_bonus: float = 0.0
var day_timing_bonus: float = 0.0

# Night upgrades
var night_stand_hp_bonus: int = 0
var night_player_damage_bonus: int = 0
var night_recover_health_bonus: int = 0

func reset_run() -> void:
	unlocked_district_count = 1
	current_district = 0
	district_day_progress = [0, 0, 0, 0, 0]

	day_coin_bonus = 0
	day_patience_bonus = 0.0
	day_timing_bonus = 0.0

	night_stand_hp_bonus = 0
	night_player_damage_bonus = 0
	night_recover_health_bonus = 0

func is_district_unlocked(index: int) -> bool:
	return index >= 0 and index < unlocked_district_count

func select_district(index: int) -> bool:
	if not is_district_unlocked(index):
		return false

	current_district = index
	return true

func get_current_district_name() -> String:
	return DISTRICT_NAMES[current_district]

func get_current_day() -> int:
	return min(district_day_progress[current_district] + 1, DAYS_PER_DISTRICT)

func get_day_progress_for(index: int) -> int:
	if index < 0 or index >= district_day_progress.size():
		return 0
	return district_day_progress[index]

func register_night_won() -> String:
	district_day_progress[current_district] += 1

	if district_day_progress[current_district] >= DAYS_PER_DISTRICT:
		if current_district >= DISTRICT_COUNT - 1:
			return "all_complete"

		unlocked_district_count = max(unlocked_district_count, current_district + 2)
		return "district_complete"

	return "next_day"
