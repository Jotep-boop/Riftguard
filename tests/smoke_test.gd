extends SceneTree
func _initialize() -> void:
    var scene = load("res://main/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    if scene.get("match_model") == null:
        push_error("Scene initializes complete match, not infinite scout prototype")
        quit(1)
        return
    assert(scene.board_model.size == Vector2i(13, 9))
    assert(scene.board_model.start == Vector2i(0, 4) and scene.board_model.goal == Vector2i(12, 4))
    var a: Vector2 = scene._cell_to_world(Vector2i(0, 4))
    var b: Vector2 = scene._cell_to_world(Vector2i(12, 4))
    assert(b.x > a.x and absf(b.y - a.y) < 1)
    var tile: PackedVector2Array = scene._tile_polygon(Vector2i(12, 4), 1.0)
    assert(absf(tile[3].y - tile[0].y) > absf(tile[1].x - tile[0].x) * 0.5)
    var back_tile: PackedVector2Array = scene._tile_polygon(Vector2i(1, 0), 0.82)
    assert(back_tile[0].y - scene.BLOCK_HEIGHT > scene.status_label.position.y + scene.status_label.size.y, "back-row tower silhouettes must clear the status text")
    assert(scene.role_buttons.size() == 3)
    assert(scene.role_buttons[0].has_theme_stylebox_override("normal"), "cohesive button theme must override engine defaults")
    assert(scene.tones.size() == 7 and scene.audio_players.size() == 8)
    for tone in scene.tones.values():
        assert(tone.mix_rate == 22050 and tone.data.size() > 4000)
    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_2
    scene._unhandled_input(key)
    assert(scene.selected_role == "nova")
    key.keycode = KEY_1
    scene._unhandled_input(key)
    scene.hovered_cell = Vector2i(3, 3)
    scene._place_hovered_tower()
    assert(scene.combat_model.towers.size() == 1)
    scene.match_model.start_wave()
    for tick in range(120):
        scene._process(1.0 / 60)
    assert(not scene.combat_model.enemies.is_empty())
    var enemy_id: String = scene.combat_model.enemies.keys()[0]
    var before_pause: Vector2 = scene.combat_model.enemies[enemy_id].position
    key.keycode = KEY_P
    scene._unhandled_input(key)
    scene._process(0.2)
    assert(scene.combat_model.enemies[enemy_id].position == before_pause)
    key.keycode = KEY_F
    scene._unhandled_input(key)
    assert(scene.speed == 2.0)
    scene.match_model.phase = "won"
    scene._update_hud()
    assert(scene.overlay.visible and "SECURED" in scene.outcome_label.text)
    scene.match_model.phase = "lost"
    scene._update_hud()
    assert(scene.overlay.visible and "FALLEN" in scene.outcome_label.text)
    scene._restart()
    assert(scene.match_model.wave == 0 and scene.combat_model.towers.is_empty())
    await create_timer(0.4).timeout
    scene.queue_free()
    await process_frame
    await process_frame
    print("PASS: match scene, camera, HUD, placement, active wave, restart")
    quit(0)
