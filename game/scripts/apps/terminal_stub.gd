extends Control

@onready var output: RichTextLabel = %TerminalOutput

var _event_bus

func bind_systems(_clock, _game_state, event_bus = null, _case_runner = null) -> void:
	_event_bus = event_bus
	if _event_bus != null:
		_event_bus.game_event.connect(_on_game_event)
	output.text = "STATION TERMINAL v0.1\nType access unavailable in vertical slice.\nListening for traffic..."

func _on_game_event(topic: StringName, payload: Dictionary) -> void:
	if topic == &"intel_ping":
		output.append_text("\nPING %s :: %s" % [String(payload.get("source", "SYS")), String(payload.get("message", ""))])
	elif topic == &"staff_analysis_ready":
		output.append_text("\nANALYSIS :: %s" % String(payload.get("summary", "Report delivered.")))
