extends SceneTree
const CampusDay = preload("res://scripts/campus_day.gd")
var failures: Array[String] = []

func _initialize():
	call_deferred("run_checks")

func check(value: bool, message: String):
	if not value:
		failures.append(message)

func finish_line(game):
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	game.dialog._unhandled_input(event)
	game.dialog._unhandled_input(event)

func choose(game, action: String):
	finish_line(game)
	var index := -1
	for i in game.conversation_options.size():
		if game.conversation_options[i]["action"] == action:
			index = i
	check(index >= 0, "Missing conversation action: " + action)
	if index >= 0:
		game.dialog._on_choice(index)

func talk_to(game, who: String):
	for npc in game.people.active:
		if npc["spec"]["who"] == who:
			game.begin_talk(npc)
			return
	check(false, "NPC missing: " + who)

func run_checks():
	# Every independent order works. No quest consumes another quest's prerequisite.
	for order in [["jacket","badge","class"],["jacket","class","badge"],["badge","jacket","class"],["badge","class","jacket"],["class","jacket","badge"],["class","badge","jacket"]]:
		var day = CampusDay.new()
		check(day.clock_text() == "12:40" and day.money == 500, "Wrong start time or wallet")
		day.act("pay_badge","ander")
		check(not day.badge_paid and day.money == 500, "Payment allowed before mentor")
		for task in order:
			match task:
				"jacket": day.act("store_jacket","entrance")
				"badge":
					day.act("badge_info","corridor_1")
					day.act("pay_badge","ander")
				"class": day.act("wait_class","class_1421")
		check(day.jacket_stored and day.badge_paid and day.class_attended and not day.class_late, "Order failed: " + str(order))
		day.act("pay_badge","ander")
		check(day.money == 350, "Repeated payment charged again")
		check(day.tasks("entrance").all(func(task): return task["done"]), "Completed tasks lost")
	var late = CampusDay.new()
	late.check_attendance("class_1421")
	check(not late.class_attended, "Early room entry completes class immediately")
	late.advance(301.0,"ander")
	check(not late.class_attended, "Outside classroom attendance counted")
	late.check_attendance("class_1421")
	check(late.class_attended and late.class_late, "Late arrival not recorded")
	var present = CampusDay.new()
	present.time_seconds = CampusDay.CLASS_TIME - 0.5
	present.advance(0.2,"class_1421")
	check(present.class_attended and not present.class_late, "Clock crossing mislabels punctual arrival")
	var poor = CampusDay.new()
	poor.mentor_met = true
	poor.money = 100
	poor.act("pay_badge","ander")
	check(not poor.badge_paid and poor.money == 100, "Failed payment changed wallet or quest")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.paused = true
	var before: float = game.day.time_seconds
	game._physics_process(12.0)
	check(game.day.time_seconds == before, "Pause advances clock")
	game.paused = false
	game._physics_process(6.0)
	check(game.day.clock_text() == "12:41", "Clock is not 10x real time")
	check(game.quest_tracker.rows.size() == 3 and game.quest_tracker.clock.text == "12:41", "Task HUD missing")
	talk_to(game,"wardrobe")
	before = game.day.time_seconds
	game._physics_process(12.0)
	check(game.day.time_seconds == before, "Dialogue advances clock")
	check(not game.day.jacket_stored, "Greeting completes jacket without confirmation")
	choose(game,"store_jacket")
	check(game.day.jacket_stored and "№27" in game.dialog.text_label.text, "Jacket not stored through dialogue")
	check("✓" in game.quest_tracker.rows[0].text, "Jacket completion missing from HUD")
	game._close_dialog()
	game.change_map("corridor_1")
	talk_to(game,"mentor")
	check(game.day.mentor_met and "150" in game.dialog.text_label.text, "Mentor did not unlock/explain badge")
	game._close_dialog()
	game.change_map("ander")
	game.hero_pos = Vector2(18.5,5.5)
	game._place_hero()
	game._update_portal_hint()
	check(not game.model.blocked(game.hero_pos), "ATM interaction position is blocked")
	check(not game._nearby_atm().is_empty() and "банкомат" in game.portal_label.text, "ATM hint or interaction missing")
	game.exit_cooldown = 0.0
	Input.action_press("interact")
	await physics_frame
	await process_frame
	Input.action_release("interact")
	check(game.dialog.is_open() and game.conversation.get("spec",{}).get("who","") == "atm", "E did not open ATM")
	choose(game,"pay_badge")
	check(game.day.badge_paid and game.day.money == 350, "ATM payment did not update task and wallet")
	game._close_dialog()
	game.change_map("class_1421")
	check(game.day.jacket_stored and game.day.badge_paid and not game.day.class_attended, "Map transition loses progress or completes class early")
	talk_to(game,"teacher_m")
	choose(game,"wait_class")
	check(game.day.clock_text() == "13:30" and game.day.class_attended and not game.day.class_late, "Waiting for class failed")
	game._close_dialog()
	game.change_map("entrance")
	check(game.day.tasks("entrance").all(func(task): return task["done"]), "Tasks lost after class")
	talk_to(game,"guard")
	var greeting: String = game.dialog.text_label.text
	choose(game,"topic")
	check(game.dialog.text_label.text != greeting, "Role topic repeats greeting")
	game._close_dialog()
	talk_to(game,"guard")
	check(game.dialog.text_label.text != greeting, "Repeated greeting has no variation")
	game._close_dialog()
	# A new run resets all progress, not just the map.
	game.free()
	var fresh = load("res://scenes/main.tscn").instantiate()
	root.add_child(fresh)
	current_scene = fresh
	check(fresh.day.clock_text() == "12:40" and fresh.day.money == 500 and not fresh.day.jacket_stored, "New game did not reset the day")
	fresh.paused = true
	# Long role topics page inside the panel, and choices wait for the last page.
	fresh.dialog.show_line("mentor", "Совет наставника. ".repeat(60))
	check(not fresh.dialog.pending_pages.is_empty(), "Long dialogue has no pages")
	var page_count: int = fresh.dialog.pending_pages.size() + 1
	for i in range(page_count):
		var label: Label = fresh.dialog.text_label
		var font := label.get_theme_font("font")
		check(font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,label.size.x,26).y <= fresh.dialog.TEXT_HEIGHT, "Dialogue page exceeds available height")
		finish_line(fresh)
	check(not fresh.dialog.is_open(), "Long dialogue did not close after all pages")
	if failures.is_empty():
		print("PASS day: 6 quest orders, payments, clock/deadline, pause/dialogue, E at ATM, teacher waiting, task HUD, new run")
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)
