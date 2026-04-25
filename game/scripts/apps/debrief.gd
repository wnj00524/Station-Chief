extends Control

@onready var report_value: RichTextLabel = %DebriefReportValue

var _game_state

func bind_systems(_clock, game_state, _event_bus = null, _case_runner = null) -> void:
	_game_state = game_state
	_game_state.station_report_ready.connect(_on_station_report_ready)
	report_value.text = "No debrief available. Resolve a case to view ground truth."

func _on_station_report_ready(report: Dictionary) -> void:
	var lines: Array[String] = []
	lines.append("POST-CASE DEBRIEF")
	lines.append("Run seed: %s" % String(report.get("seed", "n/a")))
	lines.append("Action taken: %s" % String(report.get("action_id", "unknown")).replace("_", " "))
	lines.append("Outcome: %s" % String(report.get("outcome_id", "unknown")))
	lines.append("Political Capital: %+d (Total %d)" % [
		int(report.get("political_capital_delta", 0)),
		int(report.get("political_capital_total", 0))
	])
	lines.append("")
	lines.append("Operational result")
	lines.append(String(report.get("operational_summary", "No operational summary.")))
	lines.append("")
	lines.append("Ground truth")
	lines.append(String(report.get("ground_truth_summary", "No ground truth summary.")))
	lines.append("")
	lines.append("Missed signals")
	for signal_text: String in report.get("missed_signals", []):
		lines.append("- %s" % signal_text)
	lines.append("")
	lines.append("Forward hook")
	lines.append(String(report.get("forward_hook", "No follow-up hook.")))
	report_value.text = "\n".join(lines)
