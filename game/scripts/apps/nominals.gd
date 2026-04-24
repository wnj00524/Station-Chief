extends Control

@onready var list: ItemList = %NominalsList
@onready var name_value: Label = %NominalNameValue
@onready var notes_value: RichTextLabel = %NominalNotesValue
@onready var tag_input: LineEdit = %NominalTagInput
@onready var tags_value: Label = %NominalTagsValue

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
	if channel == &"nominals":
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
	else:
		_selected_id = ""
		name_value.text = "No nominal"
		notes_value.text = "Nominal records pending."
		tags_value.text = "Tags: --"

func _on_nominals_list_item_selected(index: int) -> void:
	_render_entry(index)

func _render_entry(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	_selected_id = String(entry.get("id", ""))
	name_value.text = String(entry.get("name", "Unknown"))
	notes_value.text = String(entry.get("notes", "No notes."))
	_refresh_tags()
	if _selected_id == "local_official":
		_game_state.mark_evidence_viewed(&"nominal_logistics")

func _on_nominal_add_tag_pressed() -> void:
	if _selected_id == "":
		return
	_game_state.add_tag(&"nominal", _selected_id, tag_input.text)
	tag_input.clear()

func _on_tags_updated(item_key: StringName) -> void:
	if String(item_key) == "nominal:%s" % _selected_id:
		_refresh_tags()

func _refresh_tags() -> void:
	if _selected_id == "":
		tags_value.text = "Tags: --"
		return
	var tags: Array = _game_state.get_tags(&"nominal", _selected_id)
	tags_value.text = "Tags: %s" % (", ".join(tags) if not tags.is_empty() else "--")
