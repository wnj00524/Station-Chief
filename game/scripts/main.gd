extends Node

const GameStateScript = preload("res://scripts/core/game_state.gd")
const CaseRunnerScript = preload("res://scripts/core/case_runner.gd")
const ClockScript = preload("res://scripts/core/clock.gd")
const EventBusScript = preload("res://scripts/core/event_bus.gd")
const DesktopShellScript = preload("res://scripts/ui/desktop_shell.gd")

@onready var clock = $Clock
@onready var event_bus = $EventBus
@onready var desktop_shell = $DesktopShell

func _ready() -> void:
	assert(clock.get_script() == ClockScript)
	assert(event_bus.get_script() == EventBusScript)
	assert(desktop_shell.get_script() == DesktopShellScript)

	var game_state = GameStateScript.new()
	var case_runner = CaseRunnerScript.new(event_bus, clock, game_state)
	add_child(game_state)
	add_child(case_runner)
	desktop_shell.bind_systems(clock, event_bus, game_state, case_runner)
	case_runner.load_case("res://data/cases/falcon_meeting/case_definition.json")
