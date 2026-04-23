class_name CaseRunner
extends Node

var _event_bus: EventBus
var _clock: Clock
var _game_state: GameState
var _loaded_case: Dictionary = {}

func _init(event_bus: EventBus, clock: Clock, game_state: GameState) -> void:
	_event_bus = event_bus
	_clock = clock
	_game_state = game_state

func load_case(case_path: String) -> void:
	if not FileAccess.file_exists(case_path):
		push_warning("Case file not found: %s" % case_path)
		return

	var file := FileAccess.open(case_path, FileAccess.READ)
	var json_text := file.get_as_text()
	var parsed := JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Case file is not a dictionary: %s" % case_path)
		return

	_loaded_case = parsed
	_game_state.active_case_id = StringName(_loaded_case.get("id", ""))
	_game_state.hidden_truth = _loaded_case.get("hidden_truth", {})
	_event_bus.publish(&"case_loaded", {"case_id": _game_state.active_case_id})

func commit_player_action(action_id: StringName) -> void:
	_event_bus.publish(&"player_action_committed", {
		"case_id": _game_state.active_case_id,
		"action_id": action_id,
		"mission_time": _clock.mission_time_minutes
	})
