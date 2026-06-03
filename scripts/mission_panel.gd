extends Control

const UI_SCALE := 3.0
const PANEL_MARGIN := 24.0
const PANEL_HEIGHT := 220.0
const ENTRY_SEPARATION := 6

const HEADER_TEXTURE := preload("res://assets/props/props_missions/missions.png")
const MISSION_TEXTURES := {
	"collect_trash": {
		"pending": preload("res://assets/props/props_missions/collecttrashred.png"),
		"completed": preload("res://assets/props/props_missions/collectrashgreen.png")
	},
	"go_food_cart": {
		"pending": preload("res://assets/props/props_missions/gofoodcartred.png"),
		"completed": preload("res://assets/props/props_missions/gofoodcartgreen.png")
	}
}

var header_rect: TextureRect = null
var mission_list: VBoxContainer = null
var mission_entries: Dictionary = {}

func _ready() -> void:
	_ensure_ui()

func reset_missions() -> void:
	_ensure_ui()
	mission_entries.clear()

	for child in mission_list.get_children():
		child.free()

func add_mission(mission_id: String) -> void:
	_ensure_ui()

	if not MISSION_TEXTURES.has(mission_id):
		return

	if mission_entries.has(mission_id):
		_set_mission_state(mission_id, false)
		return

	var mission_rect := _create_texture_rect(MISSION_TEXTURES[mission_id]["pending"])
	mission_rect.name = mission_id
	mission_entries[mission_id] = mission_rect
	mission_list.add_child(mission_rect)

func complete_mission(mission_id: String) -> void:
	_set_mission_state(mission_id, true)

func _set_mission_state(mission_id: String, completed: bool) -> void:
	_ensure_ui()

	if not mission_entries.has(mission_id):
		return

	var state_key := "completed" if completed else "pending"
	var mission_rect: TextureRect = mission_entries[mission_id]
	mission_rect.texture = MISSION_TEXTURES[mission_id][state_key]

func _ensure_ui() -> void:
	if mission_list != null:
		return

	name = "MissionPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50

	var header_size: Vector2 = HEADER_TEXTURE.get_size() * UI_SCALE
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -header_size.x - PANEL_MARGIN
	offset_top = PANEL_MARGIN
	offset_right = -PANEL_MARGIN
	offset_bottom = PANEL_MARGIN + PANEL_HEIGHT

	var root_box := VBoxContainer.new()
	root_box.name = "Root"
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", ENTRY_SEPARATION)
	add_child(root_box)

	header_rect = _create_texture_rect(HEADER_TEXTURE)
	root_box.add_child(header_rect)

	mission_list = VBoxContainer.new()
	mission_list.name = "MissionList"
	mission_list.add_theme_constant_override("separation", ENTRY_SEPARATION)
	root_box.add_child(mission_list)

func _create_texture_rect(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture = texture
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = texture.get_size() * UI_SCALE
	return rect
