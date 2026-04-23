class_name EventBus
extends Node

signal game_event(topic: StringName, payload: Dictionary)

func publish(topic: StringName, payload: Dictionary = {}) -> void:
	game_event.emit(topic, payload)
