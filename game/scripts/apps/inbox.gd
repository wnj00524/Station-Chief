extends Control

@onready var message_list: ItemList = %InboxMessageList
@onready var from_value: Label = %InboxFromValue
@onready var subject_value: Label = %InboxSubjectValue
@onready var timestamp_value: Label = %InboxTimestampValue
@onready var body_value: RichTextLabel = %InboxBodyValue
@onready var tag_input: LineEdit = %InboxTagInput
@onready var tags_value: Label = %InboxTagsValue

var _game_state
var _messages: Array = []
var _selected_id: String = ""

func bind_systems(_clock, game_state, _event_bus = null, _case_runner = null) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_game_state.case_content_updated.connect(_on_case_content_updated)
	_game_state.tags_updated.connect(_on_tags_updated)
	_reload_messages()

func _on_case_content_loaded(_case_id: StringName) -> void:
	_reload_messages()

func _on_case_content_updated(channel: StringName) -> void:
	if channel == &"inbox":
		_reload_messages()

func _reload_messages() -> void:
	if _game_state == null:
		return
	_messages = _game_state.case_content.get("inbox", [])
	message_list.clear()
	for message: Dictionary in _messages:
		message_list.add_item("%s | %s" % [message.get("timestamp", "--:--"), message.get("subject", "Untitled")])
	if not _messages.is_empty():
		message_list.select(_messages.size() - 1)
		_render_message(_messages.size() - 1)
	else:
		_selected_id = ""
		from_value.text = "--"
		subject_value.text = "No traffic"
		timestamp_value.text = "--:--"
		body_value.text = "No inbox messages available yet."
		tags_value.text = "Tags: --"

func _on_inbox_message_list_item_selected(index: int) -> void:
	_render_message(index)

func _render_message(index: int) -> void:
	if index < 0 or index >= _messages.size():
		return
	var message: Dictionary = _messages[index]
	_selected_id = String(message.get("id", ""))
	from_value.text = String(message.get("from", "Unknown"))
	subject_value.text = String(message.get("subject", "Untitled"))
	timestamp_value.text = String(message.get("timestamp", "--:--"))
	body_value.text = String(message.get("body", ""))
	_refresh_tags()
	if _selected_id == "falcon_initial":
		_game_state.mark_evidence_viewed(&"inbox_claim")

func _on_inbox_add_tag_pressed() -> void:
	if _selected_id == "":
		return
	_game_state.add_tag(&"inbox", _selected_id, tag_input.text)
	tag_input.clear()

func _on_tags_updated(item_key: StringName) -> void:
	if String(item_key) == "inbox:%s" % _selected_id:
		_refresh_tags()

func _refresh_tags() -> void:
	if _selected_id == "":
		tags_value.text = "Tags: --"
		return
	var tags: Array = _game_state.get_tags(&"inbox", _selected_id)
	tags_value.text = "Tags: %s" % (", ".join(tags) if not tags.is_empty() else "--")
