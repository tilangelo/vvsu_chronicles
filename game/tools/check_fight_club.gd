extends SceneTree
var failures: Array[String] = []
func _initialize(): call_deferred("run_checks")
func check(value: bool, message: String):
	if not value: failures.append(message)
func run_checks():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.set_physics_process(false)
	game.change_map("toilet_f")
	await process_frame
	check(not game.fight.active and not game.dialog.is_open(), "Fight appeared in women's toilet")
	game.change_map("toilet_m")
	await process_frame
	await process_frame
	check(game.dialog.is_open() and game.conversation_phase == "fight_intro", "Tyler did not greet the player")
	check(is_instance_valid(game.fight.tyler) and is_instance_valid(game.fight.opponent), "Combatants missing")
	game._close_dialog()
	check(game.fight.active and game.fight.panel.visible, "Fight did not start")
	var clock: float = game.day.time_seconds
	var before_move: Vector2 = game.hero_pos
	Input.action_press("move_left")
	game._physics_process(0.1)
	Input.action_release("move_left")
	check(game.hero_pos.distance_to(before_move) > 0.05, "Player cannot move during combat")
	game.hero_pos = Vector2(2.5,6.5)
	game.fight.enemy_pos = Vector2(2.5,3.5)
	for i in range(40):
		game.fight.tick(0.1,Vector2.ZERO)
	check(game.fight.enemy_pos.distance_to(Vector2(2.5,3.5)) > 0.5, "Opponent did not approach")
	check(game.fight.player_health < 100, "Opponent did not strike")
	var before_dodge: int = game.fight.player_health
	game.hero_pos = Vector2(2.5,6.5)
	game.fight.enemy_pos = Vector2(2.5,3.5)
	game.fight.windup = 0.05
	game.fight.tick(0.1,Vector2.ZERO)
	check(game.fight.player_health == before_dodge, "Enemy attack hit after player moved out of range")
	game.fight.enemy_pos = Vector2(2.5,3.5)
	game.fight.windup = 0.0
	game.hero_pos = Vector2(2.5,7.2)
	check(not game.use_exit(), "Exit is usable during the fight")
	game.hero_pos = Vector2(2.5,4.6)
	game._place_hero()
	game.fight.facing = (game.to_screen(game.fight.enemy_pos)-game.to_screen(game.hero_pos)).normalized()
	Input.action_press("fight_attack")
	game._physics_process(0.016)
	Input.action_release("fight_attack")
	check(game.fight.enemy_health == 75, "Attack input did not damage nearby opponent")
	check(game.day.time_seconds == clock, "Class clock advanced during fight")
	game.fight.punch()
	check(game.fight.enemy_health == 75, "Attack cooldown failed")
	game.fight.player_cooldown = 0
	game.fight.facing *= -1
	game.fight.punch()
	check(game.fight.enemy_health == 75, "Attack hit behind player")
	game.fight.facing *= -1
	for i in range(3):
		game.fight.player_cooldown = 0
		game.fight.punch()
	check(game.fight.joined and not game.fight.active, "Victory did not grant club membership")
	check(game.dialog.is_open() and game.conversation_phase == "fight_victory", "Tyler did not congratulate player")
	game._close_dialog()
	game.hero_pos = Vector2(2.5,7.2)
	check(game.use_exit() and game.model.data["id"] == "corridor_1", "Player could not leave after victory")
	game.change_map("toilet_m")
	await process_frame
	check(not game.fight.active and not game.dialog.is_open(), "Completed fight restarted on return")
	game.fight.joined = false
	game.change_map("toilet_m")
	await process_frame
	await process_frame
	game._close_dialog()
	game.fight.player_health = 12
	game.fight.enemy_pos = game.hero_pos + Vector2(0,-0.9)
	game.fight.windup = 0.01
	game.fight.tick(0.02,Vector2.ZERO)
	check(game.model.data["id"] == "winter_garden", "Defeat did not move player to winter garden")
	check(not game.fight.active and game.dialog.is_open(), "Defeat did not finish fight and inform player")
	check(not game.model.blocked(game.hero_pos), "Defeat spawn is blocked")
	game._close_dialog()
	check(not game.fight.joined, "Defeat granted membership")
	if failures.is_empty(): print("PASS fight: toilet scope, intro, movement, opponent attack/dodge, input, aim, cooldown, victory, exit, defeat and respawn")
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
