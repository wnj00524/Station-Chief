extends Control

@onready var list: ItemList = %InterceptsList
@onready var channel_value: Label = %InterceptChannelValue
@onready var timestamp_value: Label = %InterceptTimestampValue
@onready var summary_value: RichTextLabel = %InterceptSummaryValue

var _game_state
var _entries: Array = []

func bind_systems(_clock, game_state, _event_bus = null, _case_runner = null) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_game_state.case_content_updated.connect(_on_case_content_updated)
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
		channel_value.text = "NO CHANNEL"
		timestamp_value.text = "--:--"
		summary_value.text = "No intercept traffic posted yet."

func _on_intercepts_list_item_selected(index: int) -> void:
	_render_entry(index)

func _render_entry(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	channel_value.text = String(entry.get("channel", "UNKNOWN"))
	timestamp_value.text = String(entry.get("timestamp", "--:--"))
	summary_value.text = String(entry.get("summary", ""))
	if String(entry.get("id", "")) == "intercept_route_shift":
		_game_state.mark_evidence_viewed(&"intercept_clue")
