extends SceneTree
func _initialize():call_deferred("run_checks")
func run_checks():
    var m=load("res://scripts/route_map.gd").new()
    m.initialize()
    m.load_map('corridor_1')
    var failures=0
    var targets=[]
    for e in m.data['exits']:targets.append(e['to'])
    for target in ['class_1_a','class_1_b','class_1_c','toilet_m','toilet_f','lounge_1','winter_garden']:
        if target not in targets:
            print('FAIL missing room/stair transition: ',target)
            failures+=1
    if not m.blocked(Vector2(15.5,2.5)):
        print('FAIL accessible behind stair 2')
        failures+=1
    m.load_map('entrance')
    if m.data.get('portal_markers',[]).is_empty():
        print('FAIL entrance passage has no readable doorway marker')
        failures+=1
    print('ROOM FAILURES: ',failures)
    quit(1 if failures else 0)
