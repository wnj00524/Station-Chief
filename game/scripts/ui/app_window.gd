class_name AppWindow
extends PanelContainer

signal focus_requested(window: AppWindow)
signal close_requested(window: AppWindow)
signal minimize_requested(window: AppWindow)

@onready var title_label: Label = %WindowTitle
@onready var content_host: MarginContainer = %WindowContent

var app_id: StringName = &""
var is_minimized: bool = false

func configure(new_app_id: StringName, title: String, content: Control) -> void:
	app_id = new_app_id
	title_label.text = title
	for child in content_host.get_children():
		content_host.remove_child(child)
	content.reparent(content_host)
	content.layout_mode = 2
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL

func show_window() -> void:
	visible = true
	is_minimized = false

func minimize_window() -> void:
	visible = false
	is_minimized = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		focus_requested.emit(self)

func _on_focus_button_pressed() -> void:
	focus_requested.emit(self)

func _on_close_button_pressed() -> void:
	close_requested.emit(self)

func _on_minimize_button_pressed() -> void:
	minimize_requested.emit(self)
