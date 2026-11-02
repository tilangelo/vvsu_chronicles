extends SceneTree
func _initialize():call_deferred('run_checks')
func run_checks():
    var s=load('res://scenes/main.tscn').instantiate()
    root.add_child(s)
    await process_frame
    s.paused=true
    var failures=0
    for id in ['corridor_1','corridor_4']:
        s.return_targets.clear()
        s.change_map(id)
        s.hero_pos=Vector2(11.5,2.5) if id=='corridor_1' else Vector2(3.5,1.5)
        if not s.use_exit() or s.model.data['id']!='ander':failures+=1
        s.hero_pos=Vector2(54.5,23.5)
        if not s.use_exit() or s.model.data['id']!=id:failures+=1
    print('STAIR RETURN FAILURES: ',failures)
    s.free()
    quit(1 if failures else 0)
