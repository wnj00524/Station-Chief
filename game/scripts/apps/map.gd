extends Control

@onready var marker_list: ItemList = %MapMarkerList
@onready var marker_name_value: Label = %MapMarkerNameValue
@onready var marker_coord_value: Label = %MapMarkerCoordValue
@onready var tag_input: LineEdit = %MapTagInput
@onready var tags_value: Label = %MapTagsValue

var _game_state
var _markers: Array = []
var _seen_markers: Dictionary = {}
var _selected_id: String = ""

func bind_systems(_clock, game_state, _event_bus = null, _case_runner = null) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_game_state.case_content_updated.connect(_on_case_content_updated)
	_game_state.tags_updated.connect(_on_tags_updated)
	_reload_markers()

func _on_case_content_loaded(_case_id: StringName) -> void:
	_reload_markers()

func _on_case_content_updated(channel: StringName) -> void:
	if channel == &"map_markers":
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
	else:
		_selected_id = ""
		marker_name_value.text = "No marker"
		marker_coord_value.text = "Grid --, --"
		tags_value.text = "Tags: --"

func _on_map_marker_list_item_selected(index: int) -> void:
	_render_marker(index)

func _render_marker(index: int) -> void:
	if index < 0 or index >= _markers.size():
		return
	var marker: Dictionary = _markers[index]
	_selected_id = String(marker.get("id", ""))
	marker_name_value.text = String(marker.get("label", "Unknown"))
	var x: float = float(marker.get("x", 0.0))
	var y: float = float(marker.get("y", 0.0))
	marker_coord_value.text = "Grid %.2f, %.2f" % [x, y]
	_refresh_tags()
	if _selected_id != "":
		_seen_markers[_selected_id] = true
		if bool(_seen_markers.get("cafe", false)) and bool(_seen_markers.get("airport_perimeter", false)):
			_game_state.mark_evidence_viewed(&"map_airport_cafe")

func _on_map_add_tag_pressed() -> void:
	if _selected_id == "":
		return
	_game_state.add_tag(&"map", _selected_id, tag_input.text)
	tag_input.clear()

func _on_tags_updated(item_key: StringName) -> void:
	if String(item_key) == "map:%s" % _selected_id:
		_refresh_tags()

func _refresh_tags() -> void:
	if _selected_id == "":
		tags_value.text = "Tags: --"
		return
	var tags: Array = _game_state.get_tags(&"map", _selected_id)
	tags_value.text = "Tags: %s" % (", ".join(tags) if not tags.is_empty() else "--")
