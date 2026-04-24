extends Control

@onready var status_value: RichTextLabel = %StaffStatusValue
@onready var trust_button: Button = %ActionTrust
@onready var verify_button: Button = %ActionVerify
@onready var surveil_button: Button = %ActionSurveil
@onready var abort_button: Button = %ActionAbort

var _game_state: GameState
var _case_runner: CaseRunner
var _event_bus: EventBus

func bind_systems(_clock: Clock, game_state: GameState, event_bus: EventBus = null, case_runner: CaseRunner = null) -> void:
	_game_state = game_state
	_case_runner = case_runner
	_event_bus = event_bus
	_game_state.case_resolved.connect(_on_case_resolved)
	_game_state.station_report_ready.connect(_on_station_report_ready)
	_game_state.staff_status_changed.connect(_on_staff_status_changed)
	_case_runner.decision_registered.connect(_on_decision_registered)
	if _event_bus != null:
		_event_bus.game_event.connect(_on_game_event)

	trust_button.text = "Commit cafe surveillance"
	verify_button.text = "Assign analyst verification"
	surveil_button.text = "Task airport surveillance"
	abort_button.text = "Abort / delay operation"

	_set_buttons_enabled(not _game_state.decision_locked)
	status_value.text = _game_state.staff_status if _game_state.staff_status != "" else "Falcon channel active. Watch desk awaiting tasking."

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

func _on_staff_status_changed(message: String) -> void:
	if _game_state.decision_locked and _game_state.case_phase == &"resolved":
		return
	status_value.text = message

func _on_game_event(topic: StringName, payload: Dictionary) -> void:
	if topic == &"clock_pressure":
		status_value.text = String(payload.get("message", "Window pressure increasing."))

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
