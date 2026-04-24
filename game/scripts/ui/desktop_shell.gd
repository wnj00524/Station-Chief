class_name DesktopShell
extends Control

@onready var clock_label: Label = %ClockLabel
@onready var political_capital_label: Label = %PoliticalCapitalLabel
@onready var feed_log: RichTextLabel = %FeedLog
@onready var workspace_tabs: TabContainer = %WorkspaceTabs
@onready var launcher_inbox: Button = %LauncherInbox
@onready var launcher_nominals: Button = %LauncherNominals
@onready var launcher_intercepts: Button = %LauncherIntercepts
@onready var launcher_map: Button = %LauncherMap
@onready var launcher_staff: Button = %LauncherStaff
@onready var inbox_app: Control = %Inbox
@onready var nominals_app: Control = %Nominals
@onready var intercepts_app: Control = %Intercepts
@onready var map_app: Control = %Map
@onready var staff_app: Control = %StaffPanel

var _clock: Clock
var _event_bus: EventBus
var _game_state: GameState
var _case_runner: CaseRunner

func bind_systems(clock: Clock, event_bus: EventBus, game_state: GameState, case_runner: CaseRunner) -> void:
	_clock = clock
	_event_bus = event_bus
	_game_state = game_state
	_case_runner = case_runner
	_clock.ticked.connect(_on_clock_ticked)
	_event_bus.game_event.connect(_on_game_event)
	_game_state.political_capital_changed.connect(_on_political_capital_changed)
	_game_state.case_resolved.connect(_on_case_resolved)
	_game_state.station_report_ready.connect(_on_station_report_ready)
	_case_runner.decision_registered.connect(_on_decision_registered)

	_bind_apps()
	_bind_launchers()
	_refresh_top_bar()
	_append_feed("Station chief online. Reviewing Falcon channel traffic.")

func _bind_apps() -> void:
	if inbox_app.has_method("bind_systems"):
		inbox_app.call("bind_systems", _clock, _game_state, _event_bus, _case_runner)
	if nominals_app.has_method("bind_systems"):
		nominals_app.call("bind_systems", _clock, _game_state, _event_bus, _case_runner)
	if intercepts_app.has_method("bind_systems"):
		intercepts_app.call("bind_systems", _clock, _game_state, _event_bus, _case_runner)
	if map_app.has_method("bind_systems"):
		map_app.call("bind_systems", _clock, _game_state, _event_bus, _case_runner)
	if staff_app.has_method("bind_systems"):
		staff_app.call("bind_systems", _clock, _game_state, _event_bus, _case_runner)

func _bind_launchers() -> void:
	launcher_inbox.pressed.connect(func() -> void: workspace_tabs.current_tab = 0)
	launcher_nominals.pressed.connect(func() -> void: workspace_tabs.current_tab = 1)
	launcher_intercepts.pressed.connect(func() -> void: workspace_tabs.current_tab = 2)
	launcher_map.pressed.connect(func() -> void: workspace_tabs.current_tab = 3)
	launcher_staff.pressed.connect(func() -> void: workspace_tabs.current_tab = 4)

func _on_clock_ticked(_mission_time: float) -> void:
	_refresh_top_bar()

func _on_game_event(topic: StringName, payload: Dictionary) -> void:
	if topic == &"intel_ping":
		_append_feed("%s: %s" % [payload.get("source", "SYSTEM"), payload.get("message", "Intel update")])
	elif topic == &"clock_pressure":
		_append_feed("%s" % payload.get("message", "Station timeline update."))
	elif topic == &"case_loaded":
		_append_feed("Case loaded: Falcon Meeting. Evidence channels are live.")
	elif topic == &"case_station_report":
		_append_feed("Station report filed for HQ review.")
	elif topic == &"staff_status":
		_append_feed("STAFF: %s" % String(payload.get("message", "Status update.")))

func _on_political_capital_changed(_new_value: int) -> void:
	_refresh_top_bar()

func _on_decision_registered(action_id: StringName, resolve_at_minutes: float) -> void:
	var resolve_hour := int(resolve_at_minutes / 60.0) % 24
	var resolve_minute := int(resolve_at_minutes) % 60
	_append_feed("Order logged: %s. Consequence expected around %02d:%02d." % [String(action_id).replace("_", " "), resolve_hour, resolve_minute])

func _on_case_resolved(outcome_id: StringName, summary: String) -> void:
	_append_feed("Outcome [%s]: %s" % [String(outcome_id), summary])

func _on_station_report_ready(report: Dictionary) -> void:
	_append_feed("REPORT // ACTION: %s | ΔPC: %+d | TOTAL: %d" % [
		String(report.get("action_id", "unknown")).replace("_", " "),
		int(report.get("political_capital_delta", 0)),
		int(report.get("political_capital_total", _game_state.political_capital))
	])
	_append_feed("REPORT // %s" % String(report.get("operational_summary", "No operational summary.")))
	_append_feed("REPORT // %s" % String(report.get("evidence_note", "Evidence notes unavailable.")))
	_append_feed("REPORT // FORWARD: %s" % String(report.get("forward_hook", "No forward hook available.")))

func _refresh_top_bar() -> void:
	if _clock != null:
		clock_label.text = "Local %s" % _clock.format_time()
	if _game_state != null:
		political_capital_label.text = "POLITICAL CAPITAL: %d" % _game_state.political_capital

func _append_feed(message: String) -> void:
	feed_log.append_text("[%s] %s\n" % [_clock.format_time() if _clock != null else "--:--", message])
