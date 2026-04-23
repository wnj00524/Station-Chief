class_name DesktopShell
extends Control

@onready var clock_label: Label = %ClockLabel
@onready var political_capital_label: Label = %PoliticalCapitalLabel

var _clock: Clock
var _game_state: GameState
var _case_runner: CaseRunner

func bind_systems(clock: Clock, game_state: GameState, case_runner: CaseRunner) -> void:
	_clock = clock
	_game_state = game_state
	_case_runner = case_runner
	_clock.ticked.connect(_on_clock_ticked)
	_refresh_top_bar()

func _on_clock_ticked(_mission_time: float) -> void:
	_refresh_top_bar()

func _refresh_top_bar() -> void:
	if _clock != null:
		clock_label.text = "Local %s" % _clock.format_time()
	if _game_state != null:
		political_capital_label.text = "POLITICAL CAPITAL: %d" % _game_state.political_capital
