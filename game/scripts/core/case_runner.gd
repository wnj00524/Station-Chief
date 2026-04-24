class_name CaseRunner
extends Node

signal decision_registered(action_id: StringName, resolution_time_minutes: float)

var _event_bus
var _clock
var _game_state
var _loaded_case: Dictionary = {}
var _scheduled_events: Array[Dictionary] = []
var _decision_payload: Dictionary = {}
var _hidden_content_by_channel: Dictionary = {}

func _init(event_bus, clock, game_state) -> void:
	_event_bus = event_bus
	_clock = clock
	_game_state = game_state

func _ready() -> void:
	_clock.ticked.connect(_on_clock_ticked)

func load_case(case_path: String) -> void:
	if not FileAccess.file_exists(case_path):
		push_warning("Case file not found: %s" % case_path)
		return

	var parsed: Variant = _read_json(case_path)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Case file is not a dictionary: %s" % case_path)
		return

	_loaded_case = parsed
	_game_state.active_case_id = StringName(_loaded_case.get("id", ""))
	_game_state.hidden_truth = _loaded_case.get("hidden_truth", {})
	_game_state.political_capital = int(_loaded_case.get("starting_political_capital", 0))
	_game_state.timeline_flags = {}
	_game_state.decision_locked = false
	_game_state.selected_action_id = &""
	_game_state.decision_committed_at_minutes = -1.0
	_game_state.resolved_outcome_id = &""
	_game_state.station_report = {}
	_game_state.set_case_phase(&"briefing")
	_game_state.set_staff_status("Falcon channel active. Watch desk awaiting tasking.")
	_scheduled_events.clear()
	_decision_payload = {}
	_hidden_content_by_channel = {}

	var content: Dictionary = _load_case_content(_loaded_case.get("content_files", {}), case_path.get_base_dir())
	var visible_content: Dictionary = _partition_content_by_availability(content)
	_game_state.set_case_content(visible_content)
	_game_state.set_case_phase(&"live_window")

	for scheduled_event: Dictionary in _loaded_case.get("scheduled_events", []):
		var event_copy: Dictionary = scheduled_event.duplicate(true)
		event_copy["fired"] = false
		_scheduled_events.append(event_copy)

	_event_bus.publish(&"case_loaded", {"case_id": _game_state.active_case_id})
	_event_bus.publish(&"staff_status", {"message": _game_state.staff_status})

func commit_player_action(action_id: StringName) -> bool:
	if _game_state.decision_locked:
		return false
	if _loaded_case.is_empty() or not _loaded_case.has("decision"):
		return false

	var decision: Dictionary = _loaded_case.get("decision", {})
	var now: float = float(_clock.mission_time_minutes)
	var outcome_id: StringName = _resolve_outcome(action_id, now)
	if outcome_id == &"":
		return false

	var consequence_delay: float = float(decision.get("consequence_delay_minutes", 6.0))
	var resolve_at: float = now + consequence_delay
	_game_state.mark_decision_committed(action_id, now)
	_game_state.set_staff_status("Order pending: %s." % String(action_id).replace("_", " "))
	_decision_payload = {
		"action_id": action_id,
		"outcome_id": outcome_id,
		"resolve_at": resolve_at,
		"committed_at": now
	}
	decision_registered.emit(action_id, resolve_at)
	_event_bus.publish(&"player_action_committed", {
		"case_id": _game_state.active_case_id,
		"action_id": action_id,
		"mission_time": now,
		"resolve_at": resolve_at
	})
	return true

func _on_clock_ticked(_mission_time: float) -> void:
	_process_scheduled_events()
	_reveal_due_content()
	_process_no_decision_pressure()
	_process_outcome_resolution()

func _process_scheduled_events() -> void:
	for scheduled_event in _scheduled_events:
		if bool(scheduled_event.get("fired", false)):
			continue
		if _clock.mission_time_minutes < float(scheduled_event.get("time_minutes", 0.0)):
			continue

		scheduled_event["fired"] = true
		var topic: StringName = StringName(scheduled_event.get("topic", ""))
		if topic != &"":
			_event_bus.publish(topic, scheduled_event.get("payload", {}))
		for effect: Dictionary in scheduled_event.get("effects", []):
			_apply_scheduled_effect(effect)

func _apply_scheduled_effect(effect: Dictionary) -> void:
	var effect_type: String = String(effect.get("type", ""))
	match effect_type:
		"reveal_content":
			_reveal_content_item(String(effect.get("channel", "")), String(effect.get("id", "")))
		"append_nominal_note":
			_append_nominal_note(String(effect.get("id", "")), String(effect.get("note", "")))
		"staff_status":
			var status: String = String(effect.get("message", ""))
			if status != "":
				_game_state.set_staff_status(status)
				_event_bus.publish(&"staff_status", {"message": status})
		"set_phase":
			var phase: StringName = StringName(effect.get("phase", ""))
			if phase != &"":
				_game_state.set_case_phase(phase)

func _reveal_due_content() -> void:
	for channel_key in _hidden_content_by_channel.keys():
		var waiting: Array = _hidden_content_by_channel[channel_key]
		if waiting.is_empty():
			continue
		var still_hidden: Array = []
		for item: Dictionary in waiting:
			var available_at: float = float(item.get("available_at_minutes", -1.0))
			if available_at >= 0.0 and _clock.mission_time_minutes >= available_at:
				_reveal_content_item(channel_key, String(item.get("id", "")))
			else:
				still_hidden.append(item)
		_hidden_content_by_channel[channel_key] = still_hidden

func _process_no_decision_pressure() -> void:
	if _game_state.decision_locked:
		return
	var decision: Dictionary = _loaded_case.get("decision", {})
	var warn_at: float = float(decision.get("no_decision_warning_minutes", -1.0))
	var resolve_at: float = float(decision.get("no_decision_resolve_minutes", -1.0))

	if warn_at >= 0.0 and _clock.mission_time_minutes >= warn_at and not bool(_game_state.timeline_flags.get("no_decision_warned", false)):
		_game_state.timeline_flags["no_decision_warned"] = true
		_event_bus.publish(&"clock_pressure", {"message": "No order logged. Transfer window narrowing rapidly."})
		_game_state.set_staff_status("No order logged. Window narrowing.")
		_event_bus.publish(&"staff_status", {"message": _game_state.staff_status})

	if resolve_at >= 0.0 and _clock.mission_time_minutes >= resolve_at:
		_game_state.mark_decision_committed(&"no_decision", _clock.mission_time_minutes)
		_game_state.set_case_phase(&"resolving")
		_game_state.set_staff_status("Window closed before tasking. Logging missed opportunity report.")
		_event_bus.publish(&"staff_status", {"message": _game_state.staff_status})
		_decision_payload = {
			"action_id": StringName("no_decision"),
			"outcome_id": StringName(decision.get("no_decision_outcome", "failure")),
			"resolve_at": _clock.mission_time_minutes + float(decision.get("no_decision_consequence_delay_minutes", 2.0)),
			"committed_at": _clock.mission_time_minutes
		}

func _process_outcome_resolution() -> void:
	if _decision_payload.is_empty():
		return
	if _clock.mission_time_minutes < float(_decision_payload.get("resolve_at", INF)):
		return

	var outcome_id: StringName = StringName(_decision_payload.get("outcome_id", ""))
	var action_id: StringName = StringName(_decision_payload.get("action_id", ""))
	var outcomes: Dictionary = _loaded_case.get("outcomes", {})
	var outcome_data: Dictionary = outcomes.get(String(outcome_id), {})
	var political_capital_delta: int = int(outcome_data.get("political_capital_delta", 0))
	_game_state.apply_political_capital(political_capital_delta)
	var summary: String = String(outcome_data.get("summary", "Outcome unavailable."))
	_game_state.set_case_phase(&"resolved")
	_game_state.mark_case_resolved(outcome_id, summary)

	var report: Dictionary = _build_station_report(action_id, outcome_id, political_capital_delta, outcome_data)
	_game_state.set_station_report(report)
	_event_bus.publish(&"case_station_report", report)
	_event_bus.publish(&"case_outcome_resolved", {
		"case_id": _game_state.active_case_id,
		"outcome_id": outcome_id,
		"summary": summary
	})
	_decision_payload = {}

func _resolve_outcome(action_id: StringName, commit_time_minutes: float) -> StringName:
	var decision: Dictionary = _loaded_case.get("decision", {})
	var transfer_close: float = float(decision.get("transfer_window_close_minutes", 498.0))
	var has_airport_context: bool = bool(_game_state.has_viewed_evidence(&"intercept_clue") or _game_state.has_viewed_evidence(&"map_airport_cafe"))
	var has_schedule_context: bool = bool(_game_state.has_viewed_evidence(&"nominal_logistics"))

	match String(action_id):
		"task_surveillance_airport":
			if commit_time_minutes <= transfer_close:
				return &"best"
			return &"partial"
		"assign_analyst_verify":
			if commit_time_minutes <= transfer_close - 3.0 and not has_airport_context:
				return &"partial"
			if has_airport_context and has_schedule_context:
				return &"defensive"
			return &"partial"
		"trust_and_proceed":
			return &"failure"
		"abort_or_delay":
			return &"defensive"
		_:
			return &""

func _build_station_report(action_id: StringName, outcome_id: StringName, political_capital_delta: int, outcome_data: Dictionary) -> Dictionary:
	var reviewed_evidence: Array[String] = []
	if _game_state.has_viewed_evidence(&"inbox_claim"):
		reviewed_evidence.append("initial Falcon inbox claim")
	if _game_state.has_viewed_evidence(&"intercept_clue"):
		reviewed_evidence.append("SIGINT/intercept traffic")
	if _game_state.has_viewed_evidence(&"nominal_logistics"):
		reviewed_evidence.append("nominal logistics links")
	if _game_state.has_viewed_evidence(&"map_airport_cafe"):
		reviewed_evidence.append("cafe/airport map markers")

	var evidence_note: String = "Desk review was incomplete before commitment."
	if reviewed_evidence.size() >= 4:
		evidence_note = "Review included %s." % ", ".join(reviewed_evidence)
	elif reviewed_evidence.is_empty():
		evidence_note = "No evidence panes were reviewed before dispatch."
	else:
		evidence_note = "Review included %s; other panes were left unverified." % ", ".join(reviewed_evidence)

	return {
		"case_id": _game_state.active_case_id,
		"action_id": action_id,
		"outcome_id": outcome_id,
		"political_capital_delta": political_capital_delta,
		"political_capital_total": _game_state.political_capital,
		"summary": String(outcome_data.get("summary", "Outcome unavailable.")),
		"operational_summary": String(outcome_data.get("operational_summary", "No additional operational detail available.")),
		"evidence_note": evidence_note,
		"forward_hook": String(outcome_data.get("forward_hook", "Recommend opening follow-on assessment with HQ counterparts."))
	}

func _load_case_content(content_files: Dictionary, case_root_path: String) -> Dictionary:
	var content: Dictionary = {}
	for key in content_files.keys():
		var relative_path: String = String(content_files[key])
		var absolute_path: String = "%s/%s" % [case_root_path, relative_path]
		content[key] = _read_json(absolute_path)
	return content

func _partition_content_by_availability(content: Dictionary) -> Dictionary:
	var visible: Dictionary = {}
	for channel_key in content.keys():
		var entries: Array = content[channel_key]
		var visible_entries: Array = []
		var hidden_entries: Array = []
		for raw_entry in entries:
			var entry: Dictionary = raw_entry.duplicate(true)
			var available_at: float = float(entry.get("available_at_minutes", -1.0))
			if available_at >= 0.0 and available_at > _clock.mission_time_minutes:
				hidden_entries.append(entry)
			else:
				visible_entries.append(entry)
		visible[channel_key] = visible_entries
		_hidden_content_by_channel[channel_key] = hidden_entries
	return visible

func _reveal_content_item(channel: String, item_id: String) -> void:
	if channel == "" or item_id == "":
		return
	var channel_entries: Array = _game_state.case_content.get(channel, [])
	for entry: Dictionary in channel_entries:
		if String(entry.get("id", "")) == item_id:
			return

	var waiting_entries: Array = _hidden_content_by_channel.get(channel, [])
	for index in range(waiting_entries.size()):
		var entry: Dictionary = waiting_entries[index]
		if String(entry.get("id", "")) != item_id:
			continue
		channel_entries.append(entry)
		waiting_entries.remove_at(index)
		_hidden_content_by_channel[channel] = waiting_entries
		_game_state.update_case_content_channel(StringName(channel), channel_entries)
		break

func _append_nominal_note(nominal_id: String, note: String) -> void:
	if nominal_id == "" or note == "":
		return
	var entries: Array = _game_state.case_content.get("nominals", [])
	var changed: bool = false
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		if String(entry.get("id", "")) != nominal_id:
			continue
		entry["notes"] = "%s\n\n%s" % [String(entry.get("notes", "")), note]
		entries[index] = entry
		changed = true
		break
	if changed:
		_game_state.update_case_content_channel(&"nominals", entries)

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("JSON file missing: %s" % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_warning("JSON parse failed: %s" % path)
		return {}
	return parsed
