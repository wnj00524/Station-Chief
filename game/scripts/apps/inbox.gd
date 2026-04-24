extends Control

@onready var message_list: ItemList = %InboxMessageList
@onready var from_value: Label = %InboxFromValue
@onready var subject_value: Label = %InboxSubjectValue
@onready var timestamp_value: Label = %InboxTimestampValue
@onready var body_value: RichTextLabel = %InboxBodyValue

var _game_state: GameState
var _messages: Array = []

func bind_systems(_clock: Clock, game_state: GameState) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_reload_messages()

func _on_case_content_loaded(_case_id: StringName) -> void:
	_reload_messages()

func _reload_messages() -> void:
	if _game_state == null:
		return
	_messages = _game_state.case_content.get("inbox", [])
	message_list.clear()
	for message: Dictionary in _messages:
		message_list.add_item("%s | %s" % [message.get("timestamp", "--:--"), message.get("subject", "Untitled")])
	if not _messages.is_empty():
		message_list.select(0)
		_render_message(0)

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
