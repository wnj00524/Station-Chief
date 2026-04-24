extends Control

@onready var list: ItemList = %InterceptsList
@onready var channel_value: Label = %InterceptChannelValue
@onready var timestamp_value: Label = %InterceptTimestampValue
@onready var summary_value: RichTextLabel = %InterceptSummaryValue
@onready var tag_input: LineEdit = %InterceptTagInput
@onready var tags_value: Label = %InterceptTagsValue

var _game_state
var _entries: Array = []
var _selected_id: String = ""

func bind_systems(_clock, game_state, _event_bus = null, _case_runner = null) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_game_state.case_content_updated.connect(_on_case_content_updated)
	_game_state.tags_updated.connect(_on_tags_updated)
	_reload_entries()

func _on_case_content_loaded(_case_id: StringName) -> void:
	_reload_entries()

func _on_case_content_updated(channel: StringName) -> void:
	if channel == &"intercepts":
		_reload_entries()

func _reload_entries() -> void:
	if _game_state == null:
		return
	_entries = _game_state.case_content.get("intercepts", [])
	list.clear()
	for entry: Dictionary in _entries:
		list.add_item("%s | %s" % [entry.get("timestamp", "--:--"), entry.get("channel", "UNKNOWN")])
	if not _entries.is_empty():
		list.select(_entries.size() - 1)
		_render_entry(_entries.size() - 1)
	else:
		_selected_id = ""
		channel_value.text = "NO CHANNEL"
		timestamp_value.text = "--:--"
		summary_value.text = "No intercept traffic posted yet."
		tags_value.text = "Tags: --"

func _on_intercepts_list_item_selected(index: int) -> void:
	_render_entry(index)

func _render_entry(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	_selected_id = String(entry.get("id", ""))
	channel_value.text = String(entry.get("channel", "UNKNOWN"))
	timestamp_value.text = String(entry.get("timestamp", "--:--"))
	summary_value.text = String(entry.get("summary", ""))
	_refresh_tags()
	if _selected_id == "intercept_route_shift":
		_game_state.mark_evidence_viewed(&"intercept_clue")

func _on_intercept_add_tag_pressed() -> void:
	if _selected_id == "":
		return
	_game_state.add_tag(&"intercept", _selected_id, tag_input.text)
	tag_input.clear()

func _on_tags_updated(item_key: StringName) -> void:
	if String(item_key) == "intercept:%s" % _selected_id:
		_refresh_tags()

func _refresh_tags() -> void:
	if _selected_id == "":
		tags_value.text = "Tags: --"
		return
	var tags: Array = _game_state.get_tags(&"intercept", _selected_id)
	tags_value.text = "Tags: %s" % (", ".join(tags) if not tags.is_empty() else "--")
