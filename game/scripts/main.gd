extends Node

@onready var clock: Clock = $Clock
@onready var event_bus: EventBus = $EventBus
@onready var desktop_shell: DesktopShell = $DesktopShell

func _ready() -> void:
	var game_state := GameState.new()
	var case_runner := CaseRunner.new(event_bus, clock, game_state)
	add_child(game_state)
	add_child(case_runner)
	desktop_shell.bind_systems(clock, game_state, case_runner)
	case_runner.load_case("res://data/cases/falcon_meeting/case_definition.json")
