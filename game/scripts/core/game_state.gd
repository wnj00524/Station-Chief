class_name GameState
extends Node

var political_capital: int = 0
var active_case_id: StringName = &""
var hidden_truth: Dictionary = {}
var timeline_flags: Dictionary = {}

func apply_political_capital(delta_value: int) -> void:
	political_capital += delta_value
