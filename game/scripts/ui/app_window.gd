extends PanelContainer
class_name AppWindow

signal focus_requested(window: PanelContainer)
signal close_requested(window: PanelContainer)
signal minimize_requested(window: PanelContainer)

const DRAG_THRESHOLD: float = 5.0

@onready var title_label: Label = %WindowTitle
@onready var content_host: MarginContainer = %WindowContent
@onready var header: Control = $VBox/Header

static var _drag_owner: AppWindow = null

var app_id: StringName = &""
var is_minimized: bool = false
var _is_drag_mouse_down: bool = false
var _is_dragging: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO

func configure(new_app_id: StringName, title: String, content: Control) -> void:
	app_id = new_app_id
	if title_label == null:
		push_error("AppWindow.configure failed: %WindowTitle is missing in app_window.tscn")
		return
	if content_host == null:
		push_error("AppWindow.configure failed: %WindowContent is missing in app_window.tscn")
		return
	if content == null:
		push_error("AppWindow.configure failed: content is null for app '%s'" % new_app_id)
		return

	title_label.text = title
	for child in content_host.get_children():
		content_host.remove_child(child)

	if content.get_parent() != null:
		content.reparent(content_host)
	else:
		content_host.add_child(content)

	content.layout_mode = 2
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL

func show_window() -> void:
	visible = true
	is_minimized = false

func minimize_window() -> void:
	_cancel_drag()
	visible = false
	is_minimized = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		focus_requested.emit(self)

	if is_minimized:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not _mouse_over_titlebar(event.global_position):
				return
			if _drag_owner != null and _drag_owner != self:
				return
			_is_drag_mouse_down = true
			_is_dragging = false
			_drag_start_mouse = event.global_position
			_drag_offset = event.global_position - global_position
			_drag_owner = self
			focus_requested.emit(self)
		else:
			_cancel_drag()
		return

	if event is InputEventMouseMotion and _is_drag_mouse_down and _drag_owner == self:
		if not _is_dragging:
			var distance: float = _drag_start_mouse.distance_to(event.global_position)
			if distance < DRAG_THRESHOLD:
				return
			_is_dragging = true
		focus_requested.emit(self)
		_update_drag_position(event.global_position)

func _mouse_over_titlebar(global_mouse: Vector2) -> bool:
	if header == null:
		return false
	var rect := Rect2(header.global_position, header.size)
	return rect.has_point(global_mouse)

func _update_drag_position(global_mouse: Vector2) -> void:
	var desktop := get_parent() as Control
	if desktop == null:
		global_position = global_mouse - _drag_offset
		return
	var new_local_pos: Vector2 = desktop.get_global_transform_with_canvas().affine_inverse() * (global_mouse - _drag_offset)
	var max_x: float = max(0.0, desktop.size.x - size.x)
	var max_y: float = max(0.0, desktop.size.y - header.size.y)
	new_local_pos.x = clamp(new_local_pos.x, 0.0, max_x)
	new_local_pos.y = clamp(new_local_pos.y, 0.0, max_y)
	position = new_local_pos

func _cancel_drag() -> void:
	_is_drag_mouse_down = false
	_is_dragging = false
	if _drag_owner == self:
		_drag_owner = null

func _on_focus_button_pressed() -> void:
	focus_requested.emit(self)

func _on_close_button_pressed() -> void:
	_cancel_drag()
	close_requested.emit(self)

func _on_minimize_button_pressed() -> void:
	minimize_requested.emit(self)
