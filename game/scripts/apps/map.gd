extends Control

@onready var marker_list: ItemList = %MapMarkerList
@onready var marker_name_value: Label = %MapMarkerNameValue
@onready var marker_coord_value: Label = %MapMarkerCoordValue
@onready var tag_input: LineEdit = %MapTagInput
@onready var tags_value: Label = %MapTagsValue
@onready var filter_select: OptionButton = %MapTagFilter

var _game_state
var _markers: Array = []
var _visible_indices: Array[int] = []
var _selected_id: String = ""
var _active_filter: String = ""

func bind_systems(_clock, game_state, _event_bus = null, _case_runner = null) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_game_state.case_content_updated.connect(_on_case_content_updated)
	_game_state.tags_updated.connect(_on_tags_updated)
	_reload_markers()

func _on_case_content_loaded(_case_id: StringName) -> void:
	_active_filter = ""
	_reload_markers()

func _on_case_content_updated(channel: StringName) -> void:
	if channel == &"map_markers":
		_reload_markers()

func _reload_markers() -> void:
	if _game_state == null:
		return
	_markers = _game_state.case_content.get("map_markers", [])
	_rebuild_filter_options()
	_rebuild_list()

func _rebuild_filter_options() -> void:
	var selected_text: String = _active_filter
	filter_select.clear()
	filter_select.add_item("All tags")
	for tag: String in _game_state.get_all_tags():
		filter_select.add_item(tag)
	var selected_index: int = 0
	if selected_text != "":
		for i in range(1, filter_select.item_count):
			if filter_select.get_item_text(i) == selected_text:
				selected_index = i
				break
		if selected_index == 0:
			_active_filter = ""
	filter_select.select(selected_index)

func _rebuild_list() -> void:
	marker_list.clear()
	_visible_indices.clear()
	for i in range(_markers.size()):
		var marker: Dictionary = _markers[i]
		if _active_filter != "":
			var marker_tags: Array = _game_state.get_tags(&"map", String(marker.get("id", "")))
			if not marker_tags.has(_active_filter):
				continue
		_visible_indices.append(i)
		marker_list.add_item(String(marker.get("label", "Unknown")))
	if not _visible_indices.is_empty():
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
	if index < 0 or index >= _visible_indices.size():
		return
	var marker: Dictionary = _markers[_visible_indices[index]]
	_selected_id = String(marker.get("id", ""))
	marker_name_value.text = String(marker.get("label", "Unknown"))
	var x: float = float(marker.get("x", 0.0))
	var y: float = float(marker.get("y", 0.0))
	marker_coord_value.text = "Grid %.2f, %.2f" % [x, y]
	_refresh_tags()

func _on_map_add_tag_pressed() -> void:
	if _selected_id == "":
		return
	_game_state.add_tag(&"map", _selected_id, tag_input.text)
	tag_input.clear()

func _on_tags_updated(_item_key: StringName) -> void:
	_rebuild_filter_options()
	_rebuild_list()
	_refresh_tags()

func _refresh_tags() -> void:
	if _selected_id == "":
		tags_value.text = "Tags: --"
		return
	var tags: Array = _game_state.get_tags(&"map", _selected_id)
	tags_value.text = "Tags: %s" % (", ".join(tags) if not tags.is_empty() else "--")

func _on_map_tag_filter_item_selected(index: int) -> void:
	_active_filter = "" if index == 0 else filter_select.get_item_text(index)
	_rebuild_list()
