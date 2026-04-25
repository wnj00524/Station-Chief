extends Control

@onready var message_list: ItemList = %InboxMessageList
@onready var from_value: Label = %InboxFromValue
@onready var subject_value: Label = %InboxSubjectValue
@onready var timestamp_value: Label = %InboxTimestampValue
@onready var body_value: RichTextLabel = %InboxBodyValue
@onready var tag_input: LineEdit = %InboxTagInput
@onready var tags_value: Label = %InboxTagsValue
@onready var filter_select: OptionButton = %InboxTagFilter

var _game_state
var _messages: Array = []
var _visible_indices: Array[int] = []
var _selected_id: String = ""
var _active_filter: String = ""

func bind_systems(_clock, game_state, _event_bus = null, _case_runner = null) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_game_state.case_content_updated.connect(_on_case_content_updated)
	_game_state.tags_updated.connect(_on_tags_updated)
	_reload_messages()

func _on_case_content_loaded(_case_id: StringName) -> void:
	_active_filter = ""
	_reload_messages()

func _on_case_content_updated(channel: StringName) -> void:
	if channel == &"inbox":
		_reload_messages()

func _reload_messages() -> void:
	if _game_state == null:
		return
	_messages = _game_state.case_content.get("inbox", [])
	_rebuild_filter_options()
	_rebuild_list()

func _rebuild_filter_options() -> void:
	var selected_text: String = _active_filter
	filter_select.clear()
	filter_select.add_item("All tags")
	var all_tags: Array[String] = _game_state.get_all_tags()
	for tag: String in all_tags:
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
	message_list.clear()
	_visible_indices.clear()
	for i in range(_messages.size()):
		var message: Dictionary = _messages[i]
		if _active_filter != "":
			var message_tags: Array = _game_state.get_tags(&"inbox", String(message.get("id", "")))
			if not message_tags.has(_active_filter):
				continue
		_visible_indices.append(i)
		message_list.add_item("%s | %s" % [message.get("timestamp", "--:--"), message.get("subject", "Untitled")])
	if not _visible_indices.is_empty():
		message_list.select(0)
		_render_message(0)
	else:
		_selected_id = ""
		from_value.text = "--"
		subject_value.text = "No traffic"
		timestamp_value.text = "--:--"
		body_value.text = "No inbox messages available for current filter."
		tags_value.text = "Tags: --"

func _on_inbox_message_list_item_selected(index: int) -> void:
	_render_message(index)

func _render_message(index: int) -> void:
	if index < 0 or index >= _visible_indices.size():
		return
	var message: Dictionary = _messages[_visible_indices[index]]
	_selected_id = String(message.get("id", ""))
	from_value.text = String(message.get("from", "Unknown"))
	subject_value.text = String(message.get("subject", "Untitled"))
	timestamp_value.text = String(message.get("timestamp", "--:--"))
	body_value.text = String(message.get("body", ""))
	_refresh_tags()

func _on_inbox_add_tag_pressed() -> void:
	if _selected_id == "":
		return
	_game_state.add_tag(&"inbox", _selected_id, tag_input.text)
	tag_input.clear()

func _on_tags_updated(_item_key: StringName) -> void:
	_rebuild_filter_options()
	_rebuild_list()
	_refresh_tags()

func _refresh_tags() -> void:
	if _selected_id == "":
		tags_value.text = "Tags: --"
		return
	var tags: Array = _game_state.get_tags(&"inbox", _selected_id)
	tags_value.text = "Tags: %s" % (", ".join(tags) if not tags.is_empty() else "--")

func _on_inbox_tag_filter_item_selected(index: int) -> void:
	_active_filter = "" if index == 0 else filter_select.get_item_text(index)
	_rebuild_list()
