class_name CaseRunner
extends Node

signal decision_registered(action_id: StringName, resolution_time_minutes: float)

var _event_bus: EventBus
var _clock: Clock
var _game_state: GameState
var _loaded_case: Dictionary = {}
var _scheduled_events: Array[Dictionary] = []
var _decision_payload: Dictionary = {}

func _init(event_bus: EventBus, clock: Clock, game_state: GameState) -> void:
	_event_bus = event_bus
	_clock = clock
	_game_state = game_state

func _ready() -> void:
	_clock.ticked.connect(_on_clock_ticked)

func load_case(case_path: String) -> void:
	if not FileAccess.file_exists(case_path):
		push_warning("Case file not found: %s" % case_path)
		return

	var parsed := _read_json(case_path)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Case file is not a dictionary: %s" % case_path)
		return

	_loaded_case = parsed
	_game_state.active_case_id = StringName(_loaded_case.get("id", ""))
	_game_state.hidden_truth = _loaded_case.get("hidden_truth", {})
	_game_state.political_capital = int(_loaded_case.get("starting_political_capital", 0))
	_game_state.timeline_flags = {}
	_game_state.decision_locked = false
	_game_state.resolved_outcome_id = &""
	_scheduled_events.clear()
	_decision_payload = {}

	var content := _load_case_content(_loaded_case.get("content_files", {}), case_path.get_base_dir())
	_game_state.set_case_content(content)

	for scheduled_event: Dictionary in _loaded_case.get("scheduled_events", []):
		var event_copy := scheduled_event.duplicate(true)
		event_copy["fired"] = false
		_scheduled_events.append(event_copy)

	_event_bus.publish(&"case_loaded", {"case_id": _game_state.active_case_id})

func commit_player_action(action_id: StringName) -> bool:
	if _game_state.decision_locked:
		return false

	if not _loaded_case.has("decision"):
		return false

	var decision: Dictionary = _loaded_case.get("decision", {})
	var outcomes_by_action: Dictionary = decision.get("action_outcome", {})
	var outcome_id: StringName = StringName(outcomes_by_action.get(String(action_id), ""))
	if outcome_id == &"":
		return false

	_game_state.decision_locked = true
	var consequence_delay := float(decision.get("consequence_delay_minutes", 25.0))
	var resolve_at := _clock.mission_time_minutes + consequence_delay
	_decision_payload = {
		"action_id": action_id,
		"outcome_id": outcome_id,
		"resolve_at": resolve_at
	}
	decision_registered.emit(action_id, resolve_at)
	_event_bus.publish(&"player_action_committed", {
		"case_id": _game_state.active_case_id,
		"action_id": action_id,
		"mission_time": _clock.mission_time_minutes,
		"resolve_at": resolve_at
	})
	return true

func _on_clock_ticked(_mission_time: float) -> void:
	_process_scheduled_events()
	_process_outcome_resolution()

func _process_scheduled_events() -> void:
	for scheduled_event in _scheduled_events:
		if bool(scheduled_event.get("fired", false)):
			continue
		if _clock.mission_time_minutes < float(scheduled_event.get("time_minutes", 0.0)):
			continue

		scheduled_event["fired"] = true
		var topic := StringName(scheduled_event.get("topic", ""))
		if topic != &"":
			_event_bus.publish(topic, scheduled_event.get("payload", {}))

func _process_outcome_resolution() -> void:
	if _decision_payload.is_empty():
		return
	if _clock.mission_time_minutes < float(_decision_payload.get("resolve_at", INF)):
		return

	var outcome_id := StringName(_decision_payload.get("outcome_id", ""))
	var outcomes: Dictionary = _loaded_case.get("outcomes", {})
	var outcome_data: Dictionary = outcomes.get(String(outcome_id), {})
	_game_state.apply_political_capital(int(outcome_data.get("political_capital_delta", 0)))
	var summary := String(outcome_data.get("summary", "Outcome unavailable."))
	_game_state.mark_case_resolved(outcome_id, summary)
	_event_bus.publish(&"case_outcome_resolved", {
		"case_id": _game_state.active_case_id,
		"outcome_id": outcome_id,
		"summary": summary
	})
	_decision_payload = {}

func _load_case_content(content_files: Dictionary, case_root_path: String) -> Dictionary:
	var content := {}
	for key in content_files.keys():
		var relative_path := String(content_files[key])
		var absolute_path := "%s/%s" % [case_root_path, relative_path]
		content[key] = _read_json(absolute_path)
	return content

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("JSON file missing: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed := JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_warning("JSON parse failed: %s" % path)
		return {}
	return parsed
