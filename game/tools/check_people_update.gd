extends SceneTree
var failures: Array[String]=[]
func _initialize():call_deferred('run_checks')
func check(value: bool,message: String):
    if not value:failures.append(message)
func run_checks():
    var menu=load('res://scenes/menu.tscn').instantiate()
    root.add_child(menu)
    current_scene=menu
    await process_frame
    var start=menu.find_child('StartGame',true,false)
    check(start!=null,'start menu button missing')
    if start!=null:start.pressed.emit()
    await process_frame
    await process_frame
    var game=current_scene
    check(game.has_method('begin_talk'),'start did not load game')
    game.paused=true
    check(game.hero_sprite.sprite.hframes==5 and game.hero_sprite.sprite.vframes==10,'hero sheet layout wrong')
    for direction in [Vector2.DOWN,Vector2(1,1),Vector2.RIGHT,Vector2(1,-1),Vector2.UP,Vector2(-1,-1),Vector2.LEFT,Vector2(-1,1)]:
        game.hero_sprite.advance(0.2,0.2,direction)
        check(game.hero_sprite.sprite.frame_coords.x>=1,'walk frame missing')
    game.hero_sprite.stop()
    check(game.hero_sprite.sprite.frame_coords.x==0,'idle frame missing')
    game.hero_sprite.advance(0.1,0.0,Vector2.UP)
    check(game.hero_sprite.facing=='n' and game.hero_sprite.pose=='idle','blocked hero did not turn in place')
    var event_count=InputMap.action_get_events('interact').size()
    game._install_controls()
    check(InputMap.action_get_events('interact').size()==event_count,'reopening the game duplicates controls')
    check(game.tileset.has_source(1),'animated tile source missing')
    check(game.tileset.get_source(1).get_tile_animation_frames_count(Vector2i(0,0))==16,'aquarium frames missing')
    check(game.environment_animation.gates.size()>0,'turnstile animation missing')
    var gate=game.environment_animation.gates[0]
    game.environment_animation.tick(1.0,Vector2(gate['cell'])+Vector2(0.5,0.5))
    check(roundi(gate['frame'])==3,'gate did not open')
    game.environment_animation.tick(1.0,Vector2(-100,-100))
    check(roundi(gate['frame'])==0,'gate did not close')
    check(game.people.active.size()==game.model.data['npcs'].size(),'NPC count wrong')
    for npc in game.people.active:
        if npc['points'].size()>1:
            var before_walk: Vector2=npc['pos']
            game.people.tick(0.2,game.model,game.to_screen,Vector2(-100,-100))
            check(npc['pos'].distance_to(before_walk)>0.01,'walking NPC did not move')
            break
    var guard={}
    for npc in game.people.active:
        if npc['spec']['who']=='guard':guard=npc
    check(not guard.is_empty(),'guard missing')
    if not guard.is_empty():
        game.begin_talk(guard)
        check(game.dialog.is_open() and game.dialog.portrait.texture!=null,'dialog or portrait missing')
        var before=game.hero_pos
        game.paused=false
        Input.action_press('move_up')
        for i in range(4):await physics_frame
        Input.action_release('move_up')
        check(game.hero_pos==before,'player moved during dialogue')
        var event=InputEventAction.new();event.action='interact';event.pressed=true
        game.dialog._unhandled_input(event)
        check(game.dialog.text_label.visible_ratio==1.0,'text skip failed')
        game.dialog._unhandled_input(event)
        check(game.conversation_phase=='choices','dialog choices missing')
        game.dialog._on_choice(0)
        check(game.conversation_phase=='answer','choice did not open answer')
        game.dialog._unhandled_input(event)
        game.dialog._unhandled_input(event)
        check(not game.dialog.is_open(),'dialog did not finish')
        check(game.exit_cooldown>0.0,'closing dialogue can immediately reopen interaction')
    game.paused=true
    for map_id in game.model.MAP_IDS:
        game.change_map(map_id)
        for npc in game.people.active:
            if npc['points'].size()>1:
                var points=npc['points']
                for i in points.size():
                    var a: Vector2=points[i];var b: Vector2=points[(i+1)%points.size()]
                    for n in range(21):check(not game.model.blocked(a.lerp(b,n/20.0)),map_id+': blocked NPC path')
    game.change_map('corridor_4')
    var leaf=game.door_nodes[0]
    leaf.set_open(true);leaf._process(0.5)
    check(leaf.frame_position==3.0,'door did not open')
    leaf.set_open(false);leaf._process(0.5)
    check(leaf.frame_position==0.0,'door did not close')
    if failures.is_empty():print('PASS update: menu, 8-way hero, 16 aquarium frames, gates, people, dialogue, NPC paths')
    for failure in failures:push_error(failure)
    quit(0 if failures.is_empty() else 1)
