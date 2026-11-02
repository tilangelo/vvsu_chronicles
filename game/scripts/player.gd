extends CharacterBody2D

const MOVE_SPEED := 220.0

var facing := Vector2.DOWN


func _ready() -> void:
	_install_controls()
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var controls := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Joystick directions follow the campus grid; grid axes project diagonally on screen.
	var direction := Vector2(controls.x - controls.y, (controls.x + controls.y) * 0.5)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	velocity = direction * MOVE_SPEED
	move_and_slide()

	if direction.length_squared() > 0.0:
		facing = direction
		queue_redraw()


func _draw() -> void:
	# Temporary geometric player placeholder; replace with pixel art later.
	draw_rect(Rect2(Vector2(-10.0, -12.0), Vector2(20.0, 24.0)), Color("#56a8e8"))
	draw_rect(Rect2(Vector2(-5.0, -8.0), Vector2(10.0, 5.0)), Color("#e9f3ff"))
	draw_line(Vector2.ZERO, facing.normalized() * 16.0, Color("#fff2a6"), 3.0)


func _install_controls() -> void:
	_add_action("move_left")
	_add_action("move_right")
	_add_action("move_up")
	_add_action("move_down")

	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("move_up", KEY_W)
	_add_key("move_up", KEY_UP)
	_add_key("move_down", KEY_S)
	_add_key("move_down", KEY_DOWN)

	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_button("move_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("move_down", JOY_BUTTON_DPAD_DOWN)


func _add_action(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)


func _add_key(action_name: String, key_code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key_code
	InputMap.action_add_event(action_name, event)


func _add_joy_axis(action_name: String, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action_name, event)


func _add_joy_button(action_name: String, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action_name, event)
