extends SceneTree
func _initialize():call_deferred('run_checks')
func run_checks():
    var s=load('res://scenes/main.tscn').instantiate()
    root.add_child(s)
    await process_frame
    s.paused=true
    var failures=0
    if not s.model.data.get('doors',[]).is_empty():failures+=1
    if s.level_root.find_child('Archway',true,false)==null:failures+=1
    s.change_map('winter_garden')
    if s.level_root.find_child('ATM',true,false)==null:failures+=1
    if not s.model.blocked(Vector2(18.5,4.5)):failures+=1
    if s.model.data.get('atms',[]).size()!=1:failures+=1
    print('ARCH / ATM FAILURES: ',failures)
    s.free()
    quit(1 if failures else 0)
