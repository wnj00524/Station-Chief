extends Control

@onready var status_value: RichTextLabel = %StaffStatusValue
@onready var trust_button: Button = %ActionTrust
@onready var verify_button: Button = %ActionVerify
@onready var surveil_button: Button = %ActionSurveil
@onready var abort_button: Button = %ActionAbort

var _game_state: GameState
var _case_runner: CaseRunner

func bind_systems(_clock: Clock, game_state: GameState, case_runner: CaseRunner) -> void:
	_game_state = game_state
	_case_runner = case_runner
	_game_state.case_resolved.connect(_on_case_resolved)
	_case_runner.decision_registered.connect(_on_decision_registered)
	status_value.text = "Awaiting your order. Cross-check HUMINT and SIGINT before committing station assets."

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
	status_value.text = "Order sent: %s. Waiting for downstream effects..." % String(action_id).replace("_", " ")

func _on_decision_registered(_action_id: StringName, _resolve_at_minutes: float) -> void:
	status_value.text += "\nField traffic pending."

func _on_case_resolved(outcome_id: StringName, summary: String) -> void:
	status_value.text = "Result: [%s]\n%s\nPolitical Capital now %d." % [String(outcome_id), summary, _game_state.political_capital]

func _set_buttons_enabled(is_enabled: bool) -> void:
	trust_button.disabled = not is_enabled
	verify_button.disabled = not is_enabled
	surveil_button.disabled = not is_enabled
	abort_button.disabled = not is_enabled
