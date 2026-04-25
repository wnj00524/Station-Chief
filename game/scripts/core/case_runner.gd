class_name CaseRunner
extends Node

signal decision_registered(action_id: StringName, resolution_time_minutes: float)
signal analysis_assigned(analyst_id: StringName, target_label: String, ready_at_minutes: float)

const CASE_REGISTRY_PATH: String = "res://data/cases/case_registry.json"

var _event_bus
var _clock
var _game_state
var _rng := RandomNumberGenerator.new()
var _loaded_case: Dictionary = {}
var _scheduled_events: Array[Dictionary] = []
var _decision_payload: Dictionary = {}
var _hidden_content_by_channel: Dictionary = {}
var _pending_analyses: Array[Dictionary] = []
var _case_registry: Array[Dictionary] = []
var _active_seed: int = 0
var _last_processed_minute_bucket: int = -1

func _init(event_bus, clock, game_state) -> void:
	_event_bus = event_bus
	_clock = clock
	_game_state = game_state
	_rng.randomize()
	_load_case_registry()

func _ready() -> void:
	_clock.ticked.connect(_on_clock_ticked)

func list_cases() -> Array[Dictionary]:
	return _case_registry.duplicate(true)

func get_active_seed() -> int:
	return _active_seed

func start_case(case_id: StringName, seed: int = -1) -> bool:
	if _case_registry.is_empty():
		_load_case_registry()
	if _case_registry.is_empty():
		push_warning("No cases available in registry")
		return false

	var case_entry: Dictionary = _find_case_entry(case_id)
	if case_entry.is_empty():
		push_warning("Case id not found in registry: %s" % String(case_id))
		return false
	var case_path: String = String(case_entry.get("path", ""))
	if case_path == "":
		return false

	if seed < 0:
		seed = int(Time.get_unix_time_from_system()) % 2147483647
	_active_seed = seed
	_rng.seed = seed

	var parsed: Variant = _read_json(case_path)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Case file is not a dictionary: %s" % case_path)
		return false
	_loaded_case = parsed

	_reset_run_state()
	_load_case_content_for_active_definition(case_path)
	_event_bus.publish(&"case_loaded", {
		"case_id": _game_state.active_case_id,
		"seed": _active_seed
	})
	_event_bus.publish(&"staff_status", {"message": _game_state.staff_status})
	return true

func start_random_case(seed: int = -1) -> bool:
	if _case_registry.is_empty():
		_load_case_registry()
	if _case_registry.is_empty():
		return false
	var index: int = _rng.randi_range(0, _case_registry.size() - 1)
	var case_id: StringName = StringName(_case_registry[index].get("id", ""))
	return start_case(case_id, seed)

func restart_active_case_with_new_seed() -> bool:
	if _game_state.active_case_id == &"":
		return start_random_case()
	return start_case(_game_state.active_case_id, -1)

func assign_analysis(analyst_id: StringName, target: Dictionary) -> bool:
	if _game_state.case_phase == &"resolved":
		return false
	var analyst: Dictionary = _get_analyst(analyst_id)
	if analyst.is_empty():
		return false
	var speed: float = float(analyst.get("speed", 1.0))
	var ready_at: float = _clock.mission_time_minutes + max(1.5, 4.0 / speed)
	var assignment := {
		"analyst_id": analyst_id,
		"target": target,
		"ready_at": ready_at,
		"accuracy": float(analyst.get("accuracy", 0.5)),
		"name": String(analyst.get("name", "Analyst"))
	}
	_pending_analyses.append(assignment)
	var message: String = "%s reviewing %s." % [assignment["name"], String(target.get("label", "case material"))]
	_game_state.set_staff_status(message)
	_event_bus.publish(&"staff_status", {"message": message})
	analysis_assigned.emit(analyst_id, String(target.get("label", "case material")), ready_at)
	return true

func list_analysis_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = [{"id": "case_overview", "type": "case", "label": "Falcon case overview"}]
	for message: Dictionary in _game_state.case_content.get("inbox", []):
		targets.append({"id": String(message.get("id", "")), "type": "inbox", "label": "MSG: %s" % String(message.get("subject", "Untitled"))})
	for entry: Dictionary in _game_state.case_content.get("intercepts", []):
		targets.append({"id": String(entry.get("id", "")), "type": "intercept", "label": "INT: %s" % String(entry.get("channel", "UNKNOWN"))})
	for marker: Dictionary in _game_state.case_content.get("map_markers", []):
		targets.append({"id": String(marker.get("id", "")), "type": "map", "label": "MAP: %s" % String(marker.get("label", "Unknown"))})
	for nominal: Dictionary in _game_state.case_content.get("nominals", []):
		targets.append({"id": String(nominal.get("id", "")), "type": "nominal", "label": "NOM: %s" % String(nominal.get("name", "Unknown"))})
	return targets

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
	var current_minute_bucket: int = int(floor(_clock.mission_time_minutes))
	if current_minute_bucket != _last_processed_minute_bucket:
		_last_processed_minute_bucket = current_minute_bucket
		_process_scheduled_events()
		_reveal_due_content()
		_process_no_decision_pressure()
	_process_outcome_resolution()
	_process_pending_analysis()

func _load_case_registry() -> void:
	_case_registry.clear()
	var parsed: Variant = _read_json(CASE_REGISTRY_PATH)
	if typeof(parsed) == TYPE_ARRAY:
		for entry: Dictionary in parsed:
			_case_registry.append(entry)

func _find_case_entry(case_id: StringName) -> Dictionary:
	for entry: Dictionary in _case_registry:
		if StringName(entry.get("id", "")) == case_id:
			return entry
	return {}

func _reset_run_state() -> void:
	var start_minutes: float = float(_loaded_case.get("start_time_minutes", 8.0 * 60.0))
	_clock.reset_time(start_minutes)
	_game_state.reset_case_state(
		StringName(_loaded_case.get("id", "")),
		_loaded_case.get("hidden_truth", {}),
		int(_loaded_case.get("starting_political_capital", 0))
	)
	_game_state.set_staff_status("Falcon channel active. Watch desk awaiting tasking.")
	_game_state.set_analysts(_build_analysts())
	_scheduled_events.clear()
	_pending_analyses.clear()
	_decision_payload = {}
	_hidden_content_by_channel = {}
	_last_processed_minute_bucket = -1
	for scheduled_event: Dictionary in _loaded_case.get("scheduled_events", []):
		var event_copy: Dictionary = scheduled_event.duplicate(true)
		event_copy["fired"] = false
		_scheduled_events.append(event_copy)

func _load_case_content_for_active_definition(case_path: String) -> void:
	var content: Dictionary = _load_case_content(_loaded_case.get("content_files", {}), case_path.get_base_dir())
	content = _generate_case_variant(content)
	content = _inject_noise_content(content)
	var visible_content: Dictionary = _partition_content_by_availability(content)
	_game_state.set_case_content(visible_content)
	_game_state.set_case_phase(&"live_window")

func _process_pending_analysis() -> void:
	if _pending_analyses.is_empty():
		return
	var remaining: Array[Dictionary] = []
	for assignment: Dictionary in _pending_analyses:
		if _clock.mission_time_minutes < float(assignment.get("ready_at", INF)):
			remaining.append(assignment)
			continue
		var report: Dictionary = _build_analysis_report(assignment)
		_event_bus.publish(&"staff_analysis_ready", report)
		_event_bus.publish(&"intel_ping", {
			"source": "ANALYST",
			"message": report.get("summary", "Analysis report posted.")
		})
		_game_state.set_staff_status("%s filed a report." % String(assignment.get("name", "Analyst")))
	_pending_analyses = remaining

func _build_analysis_report(assignment: Dictionary) -> Dictionary:
	var accuracy: float = float(assignment.get("accuracy", 0.5))
	var roll: float = _rng.randf()
	var high_confidence: bool = accuracy >= 0.72
	var close_to_truth: bool = roll <= accuracy
	var summary: String = ""
	if close_to_truth and high_confidence:
		summary = "High confidence: source account conflicts with communications activity in current window."
	elif close_to_truth:
		summary = "Medium confidence: timeline and source reporting still conflict. Verify before committing."
	elif high_confidence:
		summary = "High confidence: source account appears consistent with current picture."
	else:
		summary = "Low confidence: reporting picture still fragmented."
	return {
		"analyst_id": assignment.get("analyst_id", &""),
		"name": assignment.get("name", "Analyst"),
		"target": assignment.get("target", {}),
		"summary": summary,
		"confidence": "high" if high_confidence else "low"
	}

func _build_analysts() -> Array[Dictionary]:
	return [
		{"id": "nora", "name": "Nora Vance", "speed": 1.4, "accuracy": 0.82, "safety": 0.6},
		{"id": "idris", "name": "Idris Kade", "speed": 1.0, "accuracy": 0.64, "safety": 0.8},
		{"id": "mina", "name": "Mina Shah", "speed": 0.7, "accuracy": 0.9, "safety": 0.7}
	]

func _get_analyst(analyst_id: StringName) -> Dictionary:
	for analyst: Dictionary in _game_state.analysts:
		if StringName(analyst.get("id", "")) == analyst_id:
			return analyst
	return {}

func _generate_case_variant(content: Dictionary) -> Dictionary:
	var result: Dictionary = content.duplicate(true)
	var patterns: Array[String] = ["location_conflict", "timing_conflict", "identity_conflict"]
	var selected_pattern: String = patterns[_rng.randi_range(0, patterns.size() - 1)]
	_game_state.hidden_truth["discrepancy_pattern"] = selected_pattern

	var airport: String = "Airport perimeter"
	var cafe: String = "Cedar Square cafe"
	var tea_room: String = "Old Harbor tea room"

	match selected_pattern:
		"location_conflict":
			var humint_location: String = [cafe, tea_room, "Meridian cafe"][_rng.randi_range(0, 2)]
			_game_state.hidden_truth["humint_claim_location"] = humint_location
			_game_state.hidden_truth["sigint_location"] = airport
			_patch_inbox_body(result, "falcon_initial", "I'm at %s awaiting the official. Need guidance before the window closes." % humint_location)
			_patch_intercept(result, "intercept_route_shift", "Device associated with Falcon registered near %s at 08:03." % airport.to_lower())
		"timing_conflict":
			var humint_time: String = "08:14"
			var sigint_time: String = "08:03"
			_game_state.hidden_truth["humint_claim_time"] = humint_time
			_game_state.hidden_truth["sigint_time"] = sigint_time
			_game_state.hidden_truth["true_handoff_location"] = airport
			_patch_inbox_body(result, "falcon_initial", "Contact says official won't arrive until %s. Holding at %s for now." % [humint_time, cafe])
			_patch_intercept(result, "intercept_route_shift", "Falcon-linked handset active near %s at %s; activity burst ended by 08:08." % [airport.to_lower(), sigint_time])
		"identity_conflict":
			_game_state.hidden_truth["humint_claim_contact"] = "Local Official"
			_game_state.hidden_truth["actual_contact_role"] = "handler_courier_chain"
			_patch_inbox_body(result, "falcon_initial", "Local Official point of contact is expected in person. Awaiting visual confirmation at cafe.")
			_patch_intercept(result, "intercept_ambiguous_handoff", "Voice capture: 'Official stays out. Courier takes package to handler by airport gate.'")
			_patch_nominal_note(result, "local_official", "Recent pattern: official avoids direct meetings and routes contacts through transport staff.")

	return result

func _inject_noise_content(content: Dictionary) -> Dictionary:
	var result: Dictionary = content.duplicate(true)
	var noise_inbox_pool: Array[Dictionary] = [
		{"id":"noise_cable_1","timestamp":"08:04","available_at_minutes":484,"from":"Admin","subject":"Vehicle pool maintenance","body":"Garage requests quarter-hour delay for non-operational pool cars."},
		{"id":"noise_cable_2","timestamp":"08:10","available_at_minutes":490,"from":"Consular Desk","subject":"Passport printer outage","body":"Local office asks for toner transfer by noon."},
		{"id":"noise_cable_3","timestamp":"08:13","available_at_minutes":493,"from":"Logistics","subject":"Warehouse inventory request","body":"Regional stores asks for corrected diesel counts before 09:00."},
		{"id":"noise_cable_4","timestamp":"08:15","available_at_minutes":495,"from":"Protocol","subject":"Reception seating chart","body":"Residence event staff asks for final seating approvals."}
	]
	var noise_intercepts_pool: Array[Dictionary] = [
		{"id":"noise_rf_market","timestamp":"08:06","available_at_minutes":486,"channel":"RF-CIV","summary":"Taxi dispatch chatter reports sporting-event congestion by riverfront."},
		{"id":"noise_sigint_customs","timestamp":"08:12","available_at_minutes":492,"channel":"SIGINT-COM","summary":"Customs system sync delay affects container logging for terminal C."},
		{"id":"noise_rf_freight","timestamp":"08:14","available_at_minutes":494,"channel":"RF-LOG","summary":"Freight crews discuss delayed refrigeration truck at dock access lane."},
		{"id":"noise_voip_admin","timestamp":"08:16","available_at_minutes":496,"channel":"VOIP-ADMIN","summary":"Municipal IT helpdesk call about courthouse network reboot window."}
	]

	var critical_inbox: int = result.get("inbox", []).size()
	var critical_intercepts: int = result.get("intercepts", []).size()
	var noise_target_inbox: int = int(ceil(float(critical_inbox) * _rng.randf_range(0.45, 0.95)))
	var noise_target_intercepts: int = int(ceil(float(critical_intercepts) * _rng.randf_range(0.45, 0.95)))
	noise_target_inbox = clamp(noise_target_inbox, 2, noise_inbox_pool.size())
	noise_target_intercepts = clamp(noise_target_intercepts, 2, noise_intercepts_pool.size())
	noise_inbox_pool.shuffle()
	noise_intercepts_pool.shuffle()
	for i in range(noise_target_inbox):
		result["inbox"].append(noise_inbox_pool[i])
	for j in range(noise_target_intercepts):
		result["intercepts"].append(noise_intercepts_pool[j])
	return result

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
	var pattern: String = String(_game_state.hidden_truth.get("discrepancy_pattern", "location_conflict"))
	var timely: bool = commit_time_minutes <= transfer_close
	var early: bool = commit_time_minutes <= transfer_close - 3.0

	match String(action_id):
		"task_surveillance_airport":
			if timely:
				return &"best"
			return &"partial"
		"assign_analyst_verify":
			if not timely:
				return &"defensive"
			if early and pattern != "identity_conflict":
				return &"best"
			return &"partial"
		"trust_and_proceed":
			if pattern == "timing_conflict" and early:
				return &"partial"
			return &"failure"
		"abort_or_delay":
			if timely:
				return &"defensive"
			return &"failure"
		_:
			return &""

func _build_station_report(action_id: StringName, outcome_id: StringName, political_capital_delta: int, outcome_data: Dictionary) -> Dictionary:
	var discrepancy_pattern: String = String(_game_state.hidden_truth.get("discrepancy_pattern", "location_conflict"))
	var truth_summary: String = _build_truth_summary(discrepancy_pattern)
	var missed_signals: Array[String] = _build_missed_signals(discrepancy_pattern)
	return {
		"case_id": _game_state.active_case_id,
		"seed": _active_seed,
		"action_id": action_id,
		"outcome_id": outcome_id,
		"political_capital_delta": political_capital_delta,
		"political_capital_total": _game_state.political_capital,
		"summary": String(outcome_data.get("summary", "Outcome unavailable.")),
		"operational_summary": String(outcome_data.get("operational_summary", "No additional operational detail available.")),
		"forward_hook": String(outcome_data.get("forward_hook", "Recommend opening follow-on assessment with HQ counterparts.")),
		"ground_truth_summary": truth_summary,
		"missed_signals": missed_signals
	}

func _build_truth_summary(pattern: String) -> String:
	match pattern:
		"location_conflict":
			return "Falcon's location report was bait. Real transfer traffic stayed near the airport perimeter."
		"timing_conflict":
			return "Falcon's timing report lagged the operation. Activity had already started near the airport window."
		"identity_conflict":
			return "Falcon reported direct official contact, but the handoff ran through courier/handler intermediaries."
		_:
			return "Ground truth was inconclusive from surviving records."

func _build_missed_signals(pattern: String) -> Array[String]:
	match pattern:
		"location_conflict":
			return [
				"SIGINT metadata pinned the handset near airport cells while HUMINT cited a cafe meet.",
				"Liaison schedule traffic still showed residence prep instead of public movement."
			]
		"timing_conflict":
			return [
				"Intercept timing burst appeared before HUMINT claimed contact would arrive.",
				"RF logistics chatter indicated transfer closure was earlier than the HUMINT narrative."
			]
		"identity_conflict":
			return [
				"Voice scrape referenced courier handling instead of official face-to-face contact.",
				"Nominal notes indicated the official had shifted to proxy intermediaries."
			]
		_:
			return ["No structured missed-signal package available."]

func _patch_inbox_body(content: Dictionary, message_id: String, body: String) -> void:
	for i in range(content.get("inbox", []).size()):
		var msg: Dictionary = content["inbox"][i]
		if String(msg.get("id", "")) == message_id:
			msg["body"] = body
			content["inbox"][i] = msg
			return

func _patch_intercept(content: Dictionary, intercept_id: String, summary: String) -> void:
	for i in range(content.get("intercepts", []).size()):
		var entry: Dictionary = content["intercepts"][i]
		if String(entry.get("id", "")) == intercept_id:
			entry["summary"] = summary
			content["intercepts"][i] = entry
			return

func _patch_nominal_note(content: Dictionary, nominal_id: String, extra_note: String) -> void:
	for i in range(content.get("nominals", []).size()):
		var entry: Dictionary = content["nominals"][i]
		if String(entry.get("id", "")) == nominal_id:
			entry["notes"] = "%s\n\n%s" % [String(entry.get("notes", "")), extra_note]
			content["nominals"][i] = entry
			return

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
