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

const DISTRICT_DAY_PROFILES: Array[Dictionary] = [
	{
		"name": "Mahalle 1",
		"description": "Balanced neighborhood",
		"favored_recipes": ["BURGER", "HOTDOG"],
		"patience_bonus": 0.0,
		"serve_coin_bonus": 0,
		"customer_count_bonus": 0
	},
	{
		"name": "Mahalle 2",
		"description": "People here love quick toast orders",
		"favored_recipes": ["TOAST", "HOTDOG"],
		"patience_bonus": 10.0,
		"serve_coin_bonus": 0,
		"customer_count_bonus": 0
	},
	{
		"name": "Mahalle 3",
		"description": "Busy area with more customers",
		"favored_recipes": ["SOUP", "BURGER"],
		"patience_bonus": 0.0,
		"serve_coin_bonus": 0,
		"customer_count_bonus": 1
	},
	{
		"name": "Mahalle 4",
		"description": "Demanding customers but better profits",
		"favored_recipes": ["MEATBALL", "SOUP"],
		"patience_bonus": -10.0,
		"serve_coin_bonus": 1,
		"customer_count_bonus": 0
	},
	{
		"name": "Mahalle 5",
		"description": "High pressure district with strong rewards",
		"favored_recipes": ["MEATBALL", "TOAST"],
		"patience_bonus": -5.0,
		"serve_coin_bonus": 2,
		"customer_count_bonus": 1
	}
]

const ALL_RECIPE_NAMES: Array[String] = [
	"BURGER",
	"HOTDOG",
	"TOAST",
	"SOUP",
	"MEATBALL"
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

# Permanent progression
var permanent_appeal_bonus: int = 0
var unlocked_recipe_names: Array[String] = ["BURGER", "HOTDOG"]
var district_rewards_claimed: Array[bool] = [false, false, false, false, false]
var district_claimed_reward_titles: Array[String] = ["", "", "", "", ""]

# Pending reward selection
var pending_reward_district_index: int = -1
var pending_reward_options: Array = []

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

	permanent_appeal_bonus = 0
	unlocked_recipe_names = ["BURGER", "HOTDOG"]
	district_rewards_claimed = [false, false, false, false, false]
	district_claimed_reward_titles = ["", "", "", "", ""]

	pending_reward_district_index = -1
	pending_reward_options.clear()

func is_district_unlocked(index: int) -> bool:
	return index >= 0 and index < unlocked_district_count

func select_district(index: int) -> bool:
	if not is_district_unlocked(index):
		return false

	current_district = index
	return true

func get_current_district_name() -> String:
	return DISTRICT_NAMES[current_district]

func get_current_district_profile() -> Dictionary:
	if current_district < 0 or current_district >= DISTRICT_DAY_PROFILES.size():
		return DISTRICT_DAY_PROFILES[0]
	return DISTRICT_DAY_PROFILES[current_district]

func get_current_day() -> int:
	return min(district_day_progress[current_district] + 1, DAYS_PER_DISTRICT)

func get_day_progress_for(index: int) -> int:
	if index < 0 or index >= district_day_progress.size():
		return 0
	return district_day_progress[index]

func get_claimed_reward_title(index: int) -> String:
	if index < 0 or index >= district_claimed_reward_titles.size():
		return ""
	return district_claimed_reward_titles[index]

func get_unlocked_recipe_names() -> Array[String]:
	return unlocked_recipe_names.duplicate()

func is_recipe_unlocked(recipe_name: String) -> bool:
	return recipe_name in unlocked_recipe_names

func unlock_recipe(recipe_name: String) -> void:
	if recipe_name in ALL_RECIPE_NAMES and recipe_name not in unlocked_recipe_names:
		unlocked_recipe_names.append(recipe_name)

func add_permanent_appeal(amount: int) -> void:
	permanent_appeal_bonus += amount

func build_reward_options_for_district(index: int) -> Array:
	match index:
		0:
			return [
				{
					"id": "unlock_toast" if not is_recipe_unlocked("TOAST") else "coin_plus_1",
					"title": "Unlock TOAST" if not is_recipe_unlocked("TOAST") else "Better Ingredients +1",
					"description": "New recipe added." if not is_recipe_unlocked("TOAST") else "Earn more coin from serves."
				},
				{
					"id": "appeal_plus_2",
					"title": "Permanent Appeal +2",
					"description": "More local appeal every run."
				},
				{
					"id": "patience_plus_10",
					"title": "Customer Calm +10",
					"description": "Customers wait longer."
				}
			]

		1:
			return [
				{
					"id": "unlock_soup" if not is_recipe_unlocked("SOUP") else "timing_plus_5",
					"title": "Unlock SOUP" if not is_recipe_unlocked("SOUP") else "Steady Hands +5",
					"description": "New recipe added." if not is_recipe_unlocked("SOUP") else "Service timing becomes easier."
				},
				{
					"id": "appeal_plus_3",
					"title": "Permanent Appeal +3",
					"description": "More local appeal every run."
				},
				{
					"id": "coin_plus_1",
					"title": "Better Ingredients +1",
					"description": "Earn more coin from serves."
				}
			]

		2:
			return [
				{
					"id": "unlock_meatball" if not is_recipe_unlocked("MEATBALL") else "patience_plus_15",
					"title": "Unlock MEATBALL" if not is_recipe_unlocked("MEATBALL") else "Customer Calm +15",
					"description": "New recipe added." if not is_recipe_unlocked("MEATBALL") else "Customers wait much longer."
				},
				{
					"id": "appeal_plus_4",
					"title": "Permanent Appeal +4",
					"description": "More local appeal every run."
				},
				{
					"id": "timing_plus_5",
					"title": "Steady Hands +5",
					"description": "Service timing becomes easier."
				}
			]

		3:
			return [
				{
					"id": "appeal_plus_5",
					"title": "Permanent Appeal +5",
					"description": "More local appeal every run."
				},
				{
					"id": "patience_plus_15",
					"title": "Customer Calm +15",
					"description": "Customers wait much longer."
				},
				{
					"id": "stand_hp_plus_5",
					"title": "Reinforced Cart +5",
					"description": "Stand survives longer at night."
				}
			]

		4:
			return [
				{
					"id": "appeal_plus_6",
					"title": "Permanent Appeal +6",
					"description": "More local appeal every run."
				},
				{
					"id": "coin_plus_2",
					"title": "Better Ingredients +2",
					"description": "Earn much more coin from serves."
				},
				{
					"id": "timing_plus_10",
					"title": "Steady Hands +10",
					"description": "Service timing becomes much easier."
				}
			]

	return []

func prepare_current_district_reward_selection() -> Array:
	if current_district < 0 or current_district >= DISTRICT_COUNT:
		return []

	if district_day_progress[current_district] < DAYS_PER_DISTRICT:
		return []

	if district_rewards_claimed[current_district]:
		return []

	pending_reward_district_index = current_district
	pending_reward_options = build_reward_options_for_district(current_district)
	return pending_reward_options.duplicate(true)

func get_pending_reward_options() -> Array:
	return pending_reward_options.duplicate(true)

func apply_reward_option(option_id: String) -> Dictionary:
	if pending_reward_district_index < 0:
		return {}

	var result: Dictionary = {}

	match option_id:
		"unlock_toast":
			unlock_recipe("TOAST")
			result = {
				"title": "Unlocked TOAST"
			}

		"unlock_soup":
			unlock_recipe("SOUP")
			result = {
				"title": "Unlocked SOUP"
			}

		"unlock_meatball":
			unlock_recipe("MEATBALL")
			result = {
				"title": "Unlocked MEATBALL"
			}

		"appeal_plus_2":
			add_permanent_appeal(2)
			result = {
				"title": "Permanent Appeal +2"
			}

		"appeal_plus_3":
			add_permanent_appeal(3)
			result = {
				"title": "Permanent Appeal +3"
			}

		"appeal_plus_4":
			add_permanent_appeal(4)
			result = {
				"title": "Permanent Appeal +4"
			}

		"appeal_plus_5":
			add_permanent_appeal(5)
			result = {
				"title": "Permanent Appeal +5"
			}

		"appeal_plus_6":
			add_permanent_appeal(6)
			result = {
				"title": "Permanent Appeal +6"
			}

		"patience_plus_10":
			day_patience_bonus += 10.0
			result = {
				"title": "Customer Calm +10"
			}

		"patience_plus_15":
			day_patience_bonus += 15.0
			result = {
				"title": "Customer Calm +15"
			}

		"coin_plus_1":
			day_coin_bonus += 1
			result = {
				"title": "Better Ingredients +1"
			}

		"coin_plus_2":
			day_coin_bonus += 2
			result = {
				"title": "Better Ingredients +2"
			}

		"timing_plus_5":
			day_timing_bonus += 5.0
			result = {
				"title": "Steady Hands +5"
			}

		"timing_plus_10":
			day_timing_bonus += 10.0
			result = {
				"title": "Steady Hands +10"
			}

		"stand_hp_plus_5":
			night_stand_hp_bonus += 5
			result = {
				"title": "Reinforced Cart +5"
			}

		_:
			result = {
				"title": "Reward applied"
			}

	if result.has("title"):
		district_claimed_reward_titles[pending_reward_district_index] = str(result["title"])

	district_rewards_claimed[pending_reward_district_index] = true
	pending_reward_district_index = -1
	pending_reward_options.clear()

	return result

func register_night_won() -> String:
	district_day_progress[current_district] += 1

	if district_day_progress[current_district] >= DAYS_PER_DISTRICT:
		if current_district >= DISTRICT_COUNT - 1:
			return "all_complete"

		unlocked_district_count = max(unlocked_district_count, current_district + 2)
		return "district_complete"

	return "next_day"
