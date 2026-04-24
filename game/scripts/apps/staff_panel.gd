extends Control

@onready var status_value: RichTextLabel = %StaffStatusValue
@onready var analyst_select: OptionButton = %AnalystSelect
@onready var target_select: OptionButton = %TargetSelect
@onready var assign_button: Button = %AssignAnalysis
@onready var reports_value: RichTextLabel = %AnalysisReports

@onready var trust_button: Button = %ActionTrust
@onready var verify_button: Button = %ActionVerify
@onready var surveil_button: Button = %ActionSurveil
@onready var abort_button: Button = %ActionAbort

var _game_state
var _case_runner
var _event_bus
var _target_cache: Array[Dictionary] = []

func bind_systems(_clock, game_state, event_bus = null, case_runner = null) -> void:
	_game_state = game_state
	_case_runner = case_runner
	_event_bus = event_bus
	_game_state.case_resolved.connect(_on_case_resolved)
	_game_state.station_report_ready.connect(_on_station_report_ready)
	_game_state.staff_status_changed.connect(_on_staff_status_changed)
	_game_state.case_content_loaded.connect(_on_case_content_loaded)
	_game_state.case_content_updated.connect(_on_case_content_updated)
	_case_runner.decision_registered.connect(_on_decision_registered)
	_case_runner.analysis_assigned.connect(_on_analysis_assigned)
	if _event_bus != null:
		_event_bus.game_event.connect(_on_game_event)

	trust_button.text = "Commit cafe surveillance"
	verify_button.text = "Assign analyst verification"
	surveil_button.text = "Task airport surveillance"
	abort_button.text = "Abort / delay operation"

	_rebuild_analysts()
	_rebuild_targets()
	_set_buttons_enabled(not _game_state.decision_locked)
	status_value.text = _game_state.staff_status if _game_state.staff_status != "" else "Falcon channel active. Watch desk awaiting tasking."
	reports_value.text = "No analyst reports yet."

func _on_case_content_loaded(_case_id: StringName) -> void:
	_rebuild_targets()

func _on_case_content_updated(_channel: StringName) -> void:
	_rebuild_targets()

func _rebuild_analysts() -> void:
	analyst_select.clear()
	for analyst in _game_state.analysts:
		analyst_select.add_item("%s (SPD %.1f / ACC %.0f%%)" % [
			String(analyst.get("name", "Analyst")),
			float(analyst.get("speed", 1.0)),
			float(analyst.get("accuracy", 0.5)) * 100.0
		])

func _rebuild_targets() -> void:
	if _case_runner == null:
		return
	target_select.clear()
	_target_cache = _case_runner.list_analysis_targets()
	for target: Dictionary in _target_cache:
		target_select.add_item(String(target.get("label", "Case material")))

func _on_assign_analysis_pressed() -> void:
	if _game_state.analysts.is_empty() or _target_cache.is_empty():
		return
	var analyst_index: int = analyst_select.selected
	var target_index: int = target_select.selected
	if analyst_index < 0 or analyst_index >= _game_state.analysts.size():
		return
	if target_index < 0 or target_index >= _target_cache.size():
		return
	var analyst_id: StringName = StringName(_game_state.analysts[analyst_index].get("id", ""))
	if not _case_runner.assign_analysis(analyst_id, _target_cache[target_index]):
		status_value.text = "Assignment unavailable for current case phase."

func _on_action_trust_pressed() -> void:
	_commit(&"trust_and_proceed")

func _on_action_verify_pressed() -> void:
	_commit(&"assign_analyst_verify")

func _on_action_surveil_pressed() -> void:
	_commit(&"task_surveillance_airport")

func _on_action_abort_pressed() -> void:
	_commit(&"abort_or_delay")

func _commit(action_id: StringName) -> void:
	if _case_runner == null:
		return
	if not _case_runner.commit_player_action(action_id):
		status_value.text = "Action unavailable. An order may already be active or the case is not loaded."
		return
	_set_buttons_enabled(false)
	status_value.text = "Order pending: %s." % String(action_id).replace("_", " ")

func _on_decision_registered(_action_id: StringName, _resolve_at_minutes: float) -> void:
	status_value.text += "\nWatch desk acknowledges and awaits consequence traffic."

func _on_analysis_assigned(_analyst_id: StringName, target_label: String, ready_at_minutes: float) -> void:
	var ready_hour: int = int(ready_at_minutes / 60.0) % 24
	var ready_minute: int = int(ready_at_minutes) % 60
	status_value.text = "Analysis assigned on %s. Earliest return %02d:%02d." % [target_label, ready_hour, ready_minute]

func _on_staff_status_changed(message: String) -> void:
	if _game_state.decision_locked and _game_state.case_phase == &"resolved":
		return
	status_value.text = message

func _on_game_event(topic: StringName, payload: Dictionary) -> void:
	if topic == &"clock_pressure":
		status_value.text = String(payload.get("message", "Window pressure increasing."))
	elif topic == &"staff_analysis_ready":
		var report_line: String = "%s // %s" % [String(payload.get("name", "Analyst")), String(payload.get("summary", "Report ready."))]
		if reports_value.text == "No analyst reports yet.":
			reports_value.text = report_line
		else:
			reports_value.append_text("\n" + report_line)

func _on_case_resolved(outcome_id: StringName, summary: String) -> void:
	status_value.text = "Result: [%s]\n%s\nPolitical Capital now %d." % [String(outcome_id), summary, _game_state.political_capital]

func _on_station_report_ready(report: Dictionary) -> void:
	status_value.text = "STATION REPORT\n"
	status_value.text += "Action: %s\n" % String(report.get("action_id", "unknown")).replace("_", " ")
	status_value.text += "Outcome: %s\n" % String(report.get("outcome_id", "unknown"))
	status_value.text += "Political Capital Δ: %+d (Total %d)\n\n" % [
		int(report.get("political_capital_delta", 0)),
		int(report.get("political_capital_total", _game_state.political_capital))
	]
	status_value.text += "%s\n\n" % String(report.get("operational_summary", "No operational summary."))
	status_value.text += "Evidence note: %s\n" % String(report.get("evidence_note", "No evidence note."))
	status_value.text += "Forward hook: %s" % String(report.get("forward_hook", "No follow-up hook."))

func _set_buttons_enabled(is_enabled: bool) -> void:
	trust_button.disabled = not is_enabled
	verify_button.disabled = not is_enabled
	surveil_button.disabled = not is_enabled
	abort_button.disabled = not is_enabled
