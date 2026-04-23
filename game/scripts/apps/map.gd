extends Control

@onready var marker_list: ItemList = %MapMarkerList
@onready var marker_name_value: Label = %MapMarkerNameValue
@onready var marker_coord_value: Label = %MapMarkerCoordValue

var _game_state: GameState
var _markers: Array = []

func bind_systems(_clock: Clock, game_state: GameState) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_reload_markers()

func _on_case_content_loaded(_case_id: StringName) -> void:
	_reload_markers()

func _reload_markers() -> void:
	if _game_state == null:
		return
	_markers = _game_state.case_content.get("map_markers", [])
	marker_list.clear()
	for marker: Dictionary in _markers:
		marker_list.add_item(String(marker.get("label", "Unknown")))
	if not _markers.is_empty():
		marker_list.select(0)
		_render_marker(0)

func _on_map_marker_list_item_selected(index: int) -> void:
	_render_marker(index)

func _render_marker(index: int) -> void:
	if index < 0 or index >= _markers.size():
		return
	var marker: Dictionary = _markers[index]
	marker_name_value.text = String(marker.get("label", "Unknown"))
	var x := float(marker.get("x", 0.0))
	var y := float(marker.get("y", 0.0))
	marker_coord_value.text = "Grid %.2f, %.2f" % [x, y]
