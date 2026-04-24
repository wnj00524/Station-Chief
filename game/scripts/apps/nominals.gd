extends Control

@onready var list: ItemList = %NominalsList
@onready var name_value: Label = %NominalNameValue
@onready var notes_value: RichTextLabel = %NominalNotesValue

var _game_state: GameState
var _entries: Array = []

func bind_systems(_clock: Clock, game_state: GameState) -> void:
	_game_state = game_state
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_reload_entries()

func _on_case_content_loaded(_case_id: StringName) -> void:
	_reload_entries()

func _reload_entries() -> void:
	if _game_state == null:
		return
	_entries = _game_state.case_content.get("nominals", [])
	list.clear()
	for entry: Dictionary in _entries:
		list.add_item(String(entry.get("name", "Unknown")))
	if not _entries.is_empty():
		list.select(0)
		_render_entry(0)

func _on_nominals_list_item_selected(index: int) -> void:
	_render_entry(index)

func _render_entry(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	name_value.text = String(entry.get("name", "Unknown"))
	notes_value.text = String(entry.get("notes", "No notes."))
	if String(entry.get("id", "")) == "local_official":
		_game_state.mark_evidence_viewed(&"nominal_logistics")
