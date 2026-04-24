extends Control

@onready var message_list: ItemList = %InboxMessageList
@onready var from_value: Label = %InboxFromValue
@onready var subject_value: Label = %InboxSubjectValue
@onready var timestamp_value: Label = %InboxTimestampValue
@onready var body_value: RichTextLabel = %InboxBodyValue

var _game_state
var _messages: Array = []

func bind_systems(_clock, game_state, _event_bus = null, _case_runner = null) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_game_state.case_content_updated.connect(_on_case_content_updated)
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
		from_value.text = "--"
		subject_value.text = "No traffic"
		timestamp_value.text = "--:--"
		body_value.text = "No inbox messages available yet."

func _on_inbox_message_list_item_selected(index: int) -> void:
	_render_message(index)

func _render_message(index: int) -> void:
	if index < 0 or index >= _messages.size():
		return
	var message: Dictionary = _messages[index]
	from_value.text = String(message.get("from", "Unknown"))
	subject_value.text = String(message.get("subject", "Untitled"))
	timestamp_value.text = String(message.get("timestamp", "--:--"))
	body_value.text = String(message.get("body", ""))
	if String(message.get("id", "")) == "falcon_initial":
		_game_state.mark_evidence_viewed(&"inbox_claim")
