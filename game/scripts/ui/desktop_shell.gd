class_name DesktopShell
extends Control

const InboxScene: PackedScene = preload("res://scenes/apps/inbox.tscn")
const NominalsScene: PackedScene = preload("res://scenes/apps/nominals.tscn")
const InterceptsScene: PackedScene = preload("res://scenes/apps/intercepts.tscn")
const MapScene: PackedScene = preload("res://scenes/apps/map.tscn")
const StaffScene: PackedScene = preload("res://scenes/apps/staff_panel.tscn")
const TerminalScene: PackedScene = preload("res://scenes/apps/terminal_stub.tscn")

@onready var clock_label: Label = %ClockLabel
@onready var political_capital_label: Label = %PoliticalCapitalLabel
@onready var feed_log: RichTextLabel = %FeedLog
@onready var desktop_area: Control = %DesktopArea
@onready var taskbar: HBoxContainer = %Taskbar
@onready var app_window_prototype: AppWindow = %AppWindowPrototype

@onready var launcher_inbox: Button = %LauncherInbox
@onready var launcher_database: Button = %LauncherDatabase
@onready var launcher_intercepts: Button = %LauncherIntercepts
@onready var launcher_map: Button = %LauncherMap
@onready var launcher_staff: Button = %LauncherStaff
@onready var launcher_terminal: Button = %LauncherTerminal

var _clock
var _event_bus
var _game_state
var _case_runner

var _app_windows: Dictionary = {}
var _app_instances: Dictionary = {}
var _minimized_buttons: Dictionary = {}

func bind_systems(clock, event_bus, game_state, case_runner) -> void:
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

	_build_app_shell()
	_bind_launchers()
	_refresh_top_bar()
	_append_feed("Station chief online. Reviewing Falcon channel traffic.")

func _build_app_shell() -> void:
	_register_app(&"inbox", "Inbox", InboxScene, Vector2(16, 14), Vector2(640, 420))
	_register_app(&"database", "Database", NominalsScene, Vector2(170, 58), Vector2(620, 380))
	_register_app(&"intercepts", "Intercepts", InterceptsScene, Vector2(120, 120), Vector2(620, 360))
	_register_app(&"map", "Map", MapScene, Vector2(240, 46), Vector2(560, 320))
	_register_app(&"staff", "Staff", StaffScene, Vector2(270, 140), Vector2(560, 330))
	_register_app(&"terminal", "Terminal", TerminalScene, Vector2(210, 90), Vector2(520, 280))

	for app_id in _app_instances.keys():
		var app_control: Control = _app_instances[app_id]
		if app_control.has_method("bind_systems"):
			app_control.call("bind_systems", _clock, _game_state, _event_bus, _case_runner)

func _register_app(app_id: StringName, title: String, scene: PackedScene, position: Vector2, size: Vector2) -> void:
	var app_control: Control = scene.instantiate()
	_app_instances[app_id] = app_control

	var app_window: AppWindow = app_window_prototype.duplicate()
	app_window.visible = false
	app_window.position = position
	app_window.custom_minimum_size = size
	app_window.size = size
	desktop_area.add_child(app_window)
	app_window.configure(app_id, title, app_control)
	app_window.focus_requested.connect(_on_window_focus_requested)
	app_window.close_requested.connect(_on_window_close_requested)
	app_window.minimize_requested.connect(_on_window_minimize_requested)
	_app_windows[app_id] = app_window

func _bind_launchers() -> void:
	launcher_inbox.pressed.connect(func() -> void: _open_app(&"inbox"))
	launcher_database.pressed.connect(func() -> void: _open_app(&"database"))
	launcher_intercepts.pressed.connect(func() -> void: _open_app(&"intercepts"))
	launcher_map.pressed.connect(func() -> void: _open_app(&"map"))
	launcher_staff.pressed.connect(func() -> void: _open_app(&"staff"))
	launcher_terminal.pressed.connect(func() -> void: _open_app(&"terminal"))

func _open_app(app_id: StringName) -> void:
	var app_window: AppWindow = _app_windows.get(app_id)
	if app_window == null:
		return
	app_window.show_window()
	_focus_window(app_window)
	if _minimized_buttons.has(app_id):
		_minimized_buttons[app_id].queue_free()
		_minimized_buttons.erase(app_id)

func _focus_window(app_window: AppWindow) -> void:
	desktop_area.move_child(app_window, desktop_area.get_child_count() - 1)

func _on_window_focus_requested(app_window: AppWindow) -> void:
	_focus_window(app_window)

func _on_window_close_requested(app_window: AppWindow) -> void:
	app_window.visible = false
	app_window.is_minimized = false
	if _minimized_buttons.has(app_window.app_id):
		_minimized_buttons[app_window.app_id].queue_free()
		_minimized_buttons.erase(app_window.app_id)

func _on_window_minimize_requested(app_window: AppWindow) -> void:
	if app_window.is_minimized:
		return
	app_window.minimize_window()
	if _minimized_buttons.has(app_window.app_id):
		return
	var reopen_button := Button.new()
	reopen_button.text = String(app_window.app_id).capitalize()
	reopen_button.pressed.connect(func() -> void:
		_open_app(app_window.app_id)
	)
	taskbar.add_child(reopen_button)
	_minimized_buttons[app_window.app_id] = reopen_button

func _on_clock_ticked(_mission_time: float) -> void:
	_refresh_top_bar()

func _on_game_event(topic: StringName, payload: Dictionary) -> void:
	if topic == &"intel_ping":
		_append_feed("%s: %s" % [payload.get("source", "SYSTEM"), payload.get("message", "Intel update")])
	elif topic == &"clock_pressure":
		_append_feed("%s" % payload.get("message", "Station timeline update."))
	elif topic == &"case_loaded":
		_append_feed("Case loaded: Falcon family seed active. Evidence channels are live.")
	elif topic == &"case_station_report":
		_append_feed("Station report filed for HQ review.")
	elif topic == &"staff_status":
		_append_feed("STAFF: %s" % String(payload.get("message", "Status update.")))
	elif topic == &"staff_analysis_ready":
		_append_feed("STAFF REPORT: %s" % String(payload.get("summary", "Analysis ready.")))

func _on_political_capital_changed(_new_value: int) -> void:
	_refresh_top_bar()

func _on_decision_registered(action_id: StringName, resolve_at_minutes: float) -> void:
	var resolve_hour: int = int(resolve_at_minutes / 60.0) % 24
	var resolve_minute: int = int(resolve_at_minutes) % 60
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
