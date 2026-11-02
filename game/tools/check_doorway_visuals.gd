extends SceneTree
func _initialize():call_deferred('run_checks')
func run_checks():
    var m=load('res://scripts/route_map.gd').new()
    m.initialize()
    m.load_map('corridor_1')
    var failures=0
    var stair_count=0
    for p in m.data['props']:
        if str(p['tile']).begins_with('stairs_down_e'):stair_count+=1
        if p['tile']=='fence_x':failures+=1
    if stair_count!=15:
        print('FAIL stairs do not cover full five-cell passage')
        failures+=1
    if m.data.get('doors',[]).size()<6:
        print('FAIL room entrances have no door leaves')
        failures+=1
    var corner=false
    for w in m.data['walls']:
        if w['x']==4 and w['y']==0 and w['tile']=='corner_back':corner=true
    if not corner:
        print('FAIL corridor corner has two unjoined wall ends')
        failures+=1
    m.load_map('entrance')
    corner=false
    for w in m.data['walls']:
        if w['x']==2 and w['y']==3 and w['tile']=='corner_back':corner=true
    if not corner:
        print('FAIL doorway has an unfilled wall joint')
        failures+=1
    print('VISUAL STRUCTURE FAILURES: ',failures)
    quit(1 if failures else 0)
