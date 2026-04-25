extends Control

@onready var list: ItemList = %InterceptsList
@onready var channel_value: Label = %InterceptChannelValue
@onready var timestamp_value: Label = %InterceptTimestampValue
@onready var summary_value: RichTextLabel = %InterceptSummaryValue
@onready var tag_input: LineEdit = %InterceptTagInput
@onready var tags_value: Label = %InterceptTagsValue
@onready var filter_select: OptionButton = %InterceptTagFilter

var _game_state
var _entries: Array = []
var _visible_indices: Array[int] = []
var _selected_id: String = ""
var _active_filter: String = ""

func bind_systems(_clock, game_state, _event_bus = null, _case_runner = null) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_game_state.case_content_updated.connect(_on_case_content_updated)
	_game_state.tags_updated.connect(_on_tags_updated)
	_reload_entries()

func _on_case_content_loaded(_case_id: StringName) -> void:
	_active_filter = ""
	_reload_entries()

func _on_case_content_updated(channel: StringName) -> void:
	if channel == &"intercepts":
		_reload_entries()

func _reload_entries() -> void:
	if _game_state == null:
		return
	_entries = _game_state.case_content.get("intercepts", [])
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
	list.clear()
	_visible_indices.clear()
	for i in range(_entries.size()):
		var entry: Dictionary = _entries[i]
		if _active_filter != "":
			var entry_tags: Array = _game_state.get_tags(&"intercept", String(entry.get("id", "")))
			if not entry_tags.has(_active_filter):
				continue
		_visible_indices.append(i)
		list.add_item("%s | %s" % [entry.get("timestamp", "--:--"), entry.get("channel", "UNKNOWN")])
	if not _visible_indices.is_empty():
		list.select(0)
		_render_entry(0)
	else:
		_selected_id = ""
		channel_value.text = "NO CHANNEL"
		timestamp_value.text = "--:--"
		summary_value.text = "No intercept traffic available for current filter."
		tags_value.text = "Tags: --"

func _on_intercepts_list_item_selected(index: int) -> void:
	_render_entry(index)

func _render_entry(index: int) -> void:
	if index < 0 or index >= _visible_indices.size():
		return
	var entry: Dictionary = _entries[_visible_indices[index]]
	_selected_id = String(entry.get("id", ""))
	channel_value.text = String(entry.get("channel", "UNKNOWN"))
	timestamp_value.text = String(entry.get("timestamp", "--:--"))
	summary_value.text = String(entry.get("summary", ""))
	_refresh_tags()

func _on_intercept_add_tag_pressed() -> void:
	if _selected_id == "":
		return
	_game_state.add_tag(&"intercept", _selected_id, tag_input.text)
	tag_input.clear()

func _on_tags_updated(_item_key: StringName) -> void:
	_rebuild_filter_options()
	_rebuild_list()
	_refresh_tags()

func _refresh_tags() -> void:
	if _selected_id == "":
		tags_value.text = "Tags: --"
		return
	var tags: Array = _game_state.get_tags(&"intercept", _selected_id)
	tags_value.text = "Tags: %s" % (", ".join(tags) if not tags.is_empty() else "--")

func _on_intercept_tag_filter_item_selected(index: int) -> void:
	_active_filter = "" if index == 0 else filter_select.get_item_text(index)
	_rebuild_list()
