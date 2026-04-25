class_name GameState
extends Node

signal political_capital_changed(current_value: int)
signal case_content_loaded(case_id: StringName)
signal case_content_updated(channel: StringName)
signal case_phase_changed(phase: StringName)
signal staff_status_changed(message: String)
signal case_resolved(outcome_id: StringName, summary: String)
signal evidence_viewed(category: StringName)
signal station_report_ready(report: Dictionary)
signal tags_updated(item_key: StringName)
signal analysts_changed()

var political_capital: int = 0
var active_case_id: StringName = &""
var hidden_truth: Dictionary = {}
var timeline_flags: Dictionary = {}
var case_content: Dictionary = {}
var decision_locked: bool = false
var selected_action_id: StringName = &""
var decision_committed_at_minutes: float = -1.0
var case_phase: StringName = &"briefing"
var staff_status: String = ""
var resolved_outcome_id: StringName = &""
var station_report: Dictionary = {}
var player_tags: Dictionary = {}
var analysts: Array[Dictionary] = []

func reset_case_state(case_id: StringName, truth: Dictionary, starting_political_capital: int) -> void:
	active_case_id = case_id
	hidden_truth = truth.duplicate(true)
	political_capital = starting_political_capital
	timeline_flags = {}
	case_content = {}
	decision_locked = false
	selected_action_id = &""
	decision_committed_at_minutes = -1.0
	resolved_outcome_id = &""
	station_report = {}
	player_tags = {}
	set_case_phase(&"briefing")
	political_capital_changed.emit(political_capital)

func apply_political_capital(delta_value: int) -> void:
	political_capital += delta_value
	political_capital_changed.emit(political_capital)

func set_case_content(content: Dictionary) -> void:
	case_content = content
	case_content_loaded.emit(active_case_id)

func update_case_content_channel(channel: StringName, entries: Array) -> void:
	case_content[String(channel)] = entries
	case_content_updated.emit(channel)

func set_case_phase(phase: StringName) -> void:
	if case_phase == phase:
		return
	case_phase = phase
	case_phase_changed.emit(case_phase)

func set_staff_status(message: String) -> void:
	staff_status = message
	staff_status_changed.emit(staff_status)

func mark_decision_committed(action_id: StringName, mission_time_minutes: float) -> void:
	decision_locked = true
	selected_action_id = action_id
	decision_committed_at_minutes = mission_time_minutes
	set_case_phase(&"decision_committed")

func mark_case_resolved(outcome_id: StringName, summary: String) -> void:
	resolved_outcome_id = outcome_id
	decision_locked = true
	set_case_phase(&"resolved")
	case_resolved.emit(outcome_id, summary)

func mark_evidence_viewed(category: StringName) -> void:
	var key: String = "evidence_%s_viewed" % String(category)
	if bool(timeline_flags.get(key, false)):
		return
	timeline_flags[key] = true
	evidence_viewed.emit(category)

func has_viewed_evidence(category: StringName) -> bool:
	var key: String = "evidence_%s_viewed" % String(category)
	return bool(timeline_flags.get(key, false))

func set_station_report(report: Dictionary) -> void:
	station_report = report
	station_report_ready.emit(station_report)

func add_tag(item_type: StringName, item_id: String, tag_text: String) -> void:
	if item_id.strip_edges() == "":
		return
	var cleaned_tag: String = tag_text.strip_edges()
	if cleaned_tag == "":
		return
	var key: StringName = StringName("%s:%s" % [String(item_type), item_id])
	var tags: Array = player_tags.get(String(key), [])
	if tags.has(cleaned_tag):
		return
	tags.append(cleaned_tag)
	player_tags[String(key)] = tags
	tags_updated.emit(key)

func get_tags(item_type: StringName, item_id: String) -> Array:
	var key: String = "%s:%s" % [String(item_type), item_id]
	return player_tags.get(key, [])

func get_all_tags() -> Array[String]:
	var unique: Dictionary = {}
	for key in player_tags.keys():
		for tag: String in player_tags[key]:
			unique[tag] = true
	var tags: Array[String] = []
	for tag in unique.keys():
		tags.append(String(tag))
	tags.sort()
	return tags

func set_analysts(new_analysts: Array[Dictionary]) -> void:
	analysts = new_analysts
	analysts_changed.emit()
