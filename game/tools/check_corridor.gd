extends SceneTree
func _initialize():call_deferred('run_checks')
func run_checks():
    var m=load('res://scripts/route_map.gd').new()
    m.initialize()
    m.load_map('corridor_1')
    # Check architectural obstacles here; crowd-aware reachability is checked by check_route.
    m.npc_cells.clear()
    var failures=0
    for y in range(4,24):
        for half_x in range(9,20):
            if m.blocked(Vector2(half_x*0.5,y+0.5)):failures+=1
    for p in m.data['props']:
        if str(p['tile']).begins_with('stairs') and (int(p['x'])<12 or not str(p['tile']).begins_with('stairs_down_e')):failures+=1
    if not m.blocked(Vector2(15.5,2.5)):failures+=1
    if not m.blocked(Vector2(1.5,7.5)):failures+=1
    for id in ['class_1_a','class_1_b','class_1_c']:
        m.load_map(id)
        var furniture=0
        for p in m.data['props']:
            if str(p['tile']).begins_with('class_'):furniture+=1
        if furniture<8:failures+=1
    print('CORRIDOR FAILURES: ',failures)
    quit(1 if failures else 0)
