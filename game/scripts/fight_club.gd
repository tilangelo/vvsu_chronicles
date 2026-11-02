extends Node2D
## Local, reversible encounter. World movement still uses RouteMap collision checks.
const Tyler = preload("res://scripts/tyler_visual.gd")
const Person = preload("res://scripts/person.gd")
const MAX_HEALTH := 100
const PLAYER_DAMAGE := 25
const ENEMY_DAMAGE := 12
const PLAYER_REACH := 1.55
const ENEMY_REACH := 1.12
const PLAYER_COOLDOWN := 0.48
const ENEMY_COOLDOWN := 1.1
const ENEMY_WINDUP := 0.42
const ENEMY_SPEED := 1.8

var game
var tyler: Node2D
var opponent: Node2D
var enemy_pos := Vector2(2.5,3.5)
var player_health := MAX_HEALTH
var enemy_health := MAX_HEALTH
var player_cooldown := 0.0
var enemy_cooldown := 0.0
var windup := 0.0
var facing := Vector2.UP
var active := false
var joined := false
var intro_pending := false
var panel: CanvasLayer
var player_bar: ProgressBar
var enemy_bar: ProgressBar
var hint: Label
var strike: Line2D
var strike_time := 0.0

func setup(level) -> void:
	game = level
	panel = CanvasLayer.new()
	panel.layer = 4
	add_child(panel)
	var backdrop := ColorRect.new()
	backdrop.position = Vector2(22,88)
	backdrop.size = Vector2(530,91)
	backdrop.color = Color(0.05,0.08,0.13,0.92)
	panel.add_child(backdrop)
	player_bar = _bar(Vector2(35,116),Color("#6bcf89"))
	enemy_bar = _bar(Vector2(308,116),Color("#e47b6f"))
	for item: Array in [["ТЫ",35],["СОПЕРНИК",308]]:
		var title := Label.new()
		title.text = item[0]
		title.position = Vector2(item[1],91)
		title.add_theme_font_size_override("font_size",16)
		panel.add_child(title)
	hint = Label.new()
	hint.position = Vector2(35,147)
	hint.add_theme_font_size_override("font_size",15)
	hint.text = "F / пробел / X — удар   ·   Двигайся и держи дистанцию"
	panel.add_child(hint)
	panel.visible = false

func _bar(pos: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(225,20)
	bar.max_value = MAX_HEALTH
	bar.value = MAX_HEALTH
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill",fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#273443")
	bar.add_theme_stylebox_override("background",background)
	panel.add_child(bar)
	return bar

func enter(world: Node2D) -> void:
	active = false
	panel.visible = false
	intro_pending = not joined
	tyler = Tyler.new()
	tyler.name = "TylerDurden"
	tyler.position = game.to_screen(Vector2(0.65,2.75))
	world.add_child(tyler)
	if not joined:
		opponent = Person.new()
		opponent.name = "FightOpponent"
		opponent.setup("student_3")
		opponent.set_pose("idle","sw")
		enemy_pos = Vector2(2.5,3.5)
		opponent.place(game.to_screen(enemy_pos),0)
		world.add_child(opponent)
		call_deferred("_begin_intro")

func _begin_intro() -> void:
	if not intro_pending or not is_instance_valid(game) or str(game.model.data.get("id","")) != "toilet_m" or joined:
		return
	# A paused game or a different conversation must not be interrupted.
	if game.paused or game.dialog.is_open():
		return
	intro_pending = false
	game.conversation_phase = "fight_intro"
	game.dialog.show_line("tyler", "Я Тайлер Дёрден. Здесь наш бойцовский клуб. О клубе за пределами этой комнаты не рассказывают. Дерутся только двое, по одному бою за раз; бой заканчивается, когда один больше не может продолжать. Новичку предстоит выйти против студента. Двигайся и бей: F, пробел или кнопка X.")
	game.hero_sprite.stop()
	game.hud.visible = false

func start() -> void:
	if str(game.model.data.get("id","")) != "toilet_m" or joined or not is_instance_valid(opponent):
		return
	player_health = MAX_HEALTH
	enemy_health = MAX_HEALTH
	player_cooldown = 0.0
	enemy_cooldown = 0.8
	windup = 0.0
	active = true
	panel.visible = true
	_refresh()

func tick(delta: float, direction: Vector2) -> void:
	if not active:
		return
	if not direction.is_zero_approx():
		facing = direction.normalized()
	player_cooldown = maxf(0.0,player_cooldown-delta)
	enemy_cooldown = maxf(0.0,enemy_cooldown-delta)
	strike_time = maxf(0.0,strike_time-delta)
	if is_instance_valid(strike) and strike_time <= 0:
		strike.queue_free()
		strike = null
	if Input.is_action_just_pressed("fight_attack"):
		punch()
	if not active:
		return
	if windup > 0.0:
		windup -= delta
		hint.text = "Соперник замахивается — отойди!"
		if windup <= 0.0:
			_swing(opponent,-1)
			if enemy_pos.distance_to(game.hero_pos) <= ENEMY_REACH + 0.15:
				player_health = maxi(0,player_health-ENEMY_DAMAGE)
				_flash(game.hero_sprite)
				_refresh()
				if player_health <= 0:
					_lose()
					return
			enemy_cooldown = ENEMY_COOLDOWN
		return
	hint.text = "F / пробел / X — удар   ·   Двигайся и держи дистанцию"
	var distance: float = enemy_pos.distance_to(game.hero_pos)
	if distance <= ENEMY_REACH:
		opponent.stop()
		if enemy_cooldown <= 0.0:
			windup = ENEMY_WINDUP
		return
	var step: Vector2 = (game.hero_pos-enemy_pos).normalized()*ENEMY_SPEED*delta
	var old := enemy_pos
	var x_next := enemy_pos + Vector2(step.x,0)
	if not game.model.blocked(x_next) and x_next.distance_to(game.hero_pos) > 0.62:
		enemy_pos.x = x_next.x
	var y_next := enemy_pos + Vector2(0,step.y)
	if not game.model.blocked(y_next) and y_next.distance_to(game.hero_pos) > 0.62:
		enemy_pos.y = y_next.y
	if enemy_pos.distance_to(old)>0.0001:
		opponent.walk(game.to_screen(enemy_pos)-game.to_screen(old),delta)
		opponent.place(game.to_screen(enemy_pos),0)
	else:
		opponent.stop()

func blocks_player(pos: Vector2) -> bool:
	return active and pos.distance_to(enemy_pos) < 0.62

func punch() -> void:
	if not active or player_cooldown > 0.0:
		return
	player_cooldown = PLAYER_COOLDOWN
	_swing(game.hero_sprite,1)
	_show_strike()
	var screen_direction: Vector2 = (game.to_screen(enemy_pos)-game.to_screen(game.hero_pos)).normalized()
	if enemy_pos.distance_to(game.hero_pos) <= PLAYER_REACH and facing.dot(screen_direction) > 0.05:
		enemy_health = maxi(0,enemy_health-PLAYER_DAMAGE)
		_flash(opponent)
		_refresh()
		if enemy_health <= 0:
			_win()

func _swing(actor: Node2D, side: int) -> void:
	var tween := create_tween()
	tween.tween_property(actor,"rotation",0.20*side,0.09)
	tween.tween_property(actor,"rotation",0.0,0.16)

func _flash(actor: Node2D) -> void:
	actor.modulate = Color("#ff8a80")
	var tween := create_tween()
	tween.tween_property(actor,"modulate",Color.WHITE,0.22)

func _show_strike() -> void:
	if is_instance_valid(strike):
		strike.queue_free()
	strike = Line2D.new()
	strike.width = 3
	strike.default_color = Color("#ffe5aa")
	var center: Vector2 = game.hero.position + Vector2(0,-35) + facing*20
	strike.points = PackedVector2Array([center+facing.rotated(-0.8)*8,center+facing*16,center+facing.rotated(0.8)*8])
	game.hero.get_parent().add_child(strike)
	strike.z_index = 25
	strike_time = 0.14

func _refresh() -> void:
	player_bar.value = player_health
	enemy_bar.value = enemy_health

func _win() -> void:
	active = false
	joined = true
	panel.visible = false
	opponent.stop()
	opponent.rotation = 0.55
	opponent.modulate = Color("#adadad")
	game.hero_sprite.stop()
	game.conversation_phase = "fight_victory"
	game.dialog.show_line("tyler", "Хороший бой. Ты выдержал испытание — теперь ты в бойцовском клубе. На сегодня всё, можешь выходить.")

func _lose() -> void:
	active = false
	panel.visible = false
	game.hero_sprite.rotation = 0.0
	game.hero_sprite.modulate = Color.WHITE
	game.change_map("winter_garden")
	game.conversation_phase = "fight_defeat"
	game.dialog.show_line("fight_result", "Соперник оказался сильнее. Ты очнулся в зимнем саду. Отдохни и возвращайся, если захочешь попробовать снова.")
