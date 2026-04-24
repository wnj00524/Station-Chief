class_name Clock
extends Node

signal ticked(current_time: float)

@export var minutes_per_second: float = 1.0 / 30
var mission_time_minutes: float = 8.0 * 60.0

func _process(delta: float) -> void:
	mission_time_minutes += delta * minutes_per_second
	ticked.emit(mission_time_minutes)

func format_time() -> String:
	var hours: int = int(mission_time_minutes / 60.0) % 24
	var minutes: int = int(mission_time_minutes) % 60
	return "%02d:%02d" % [hours, minutes]
