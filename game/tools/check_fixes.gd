extends SceneTree
func _initialize():
    call_deferred("run_checks")
func run_checks():
    var scene = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    scene.paused = true
    var failures = 0
    if not scene.model.blocked(Vector2(16.5, 3.7)):
        print("FAIL: hero can enter wardrobe counter between columns")
        failures += 1
    if scene.level_root.find_child("Surfaces", true, false) == null:
        print("FAIL: raised floor shares depth sorting with hero and furniture")
        failures += 1
    if not scene.model.MAP_IDS.has("corridor_1"):
        print("FAIL: first-floor corridor unavailable")
        failures += 1
    scene.hero_sprite.advance(0.1, 0.2, Vector2.RIGHT)
    if not scene.hero_sprite.walking or scene.hero_sprite.phase <= 0:
        print("FAIL: walk cycle did not advance")
        failures += 1
    scene.hero_sprite.advance(0.1, 0, Vector2.ZERO)
    if scene.hero_sprite.walking:
        print("FAIL: walk cycle did not stop")
        failures += 1
    scene.free()
    print("REGRESSIONS: ", failures)
    quit(1 if failures else 0)
