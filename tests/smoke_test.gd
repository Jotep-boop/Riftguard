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
    assert(back_tile[0].y - scene.BLOCK_HEIGHT > scene.preview_label.position.y + scene.preview_label.size.y, "back-row tower silhouettes must clear the status text")
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
    assert(scene.get("branch_panel") != null, "branch chooser is available in the actual scene")
    var budget: int = scene.combat_model.gold
    key.keycode = KEY_U
    scene._unhandled_input(key)
    assert(scene.branch_panel.visible and scene.combat_model.gold == budget, "U previews choices without spending")
    key.keycode = KEY_E
    scene._unhandled_input(key)
    assert(scene.combat_model.towers[Vector2i(3, 3)].branch == "chain", "E chooses alternate branch through input")
    assert(not scene.branch_panel.visible)
    key.keycode = KEY_U
    scene._unhandled_input(key)
    assert(scene.combat_model.towers[Vector2i(3, 3)].level == 3, "U reinforces locked branch")
    assert("First contact" in scene.preview_label.text and "6 Scout" in scene.preview_label.text, "HUD previews actual composition")
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
    assert("Damage dealt" in scene.results_label.text and "Combat time" in scene.results_label.text, "results panel shows measured strategy feedback")
    scene.match_model.phase = "lost"
    scene._update_hud()
    assert(scene.overlay.visible and "FALLEN" in scene.outcome_label.text)
    assert("First contact" in scene.preview_label.text, "terminal preview refers to wave that ended, not an unplayed next wave")
    assert(scene.upgrade_button.disabled and scene.sell_button.disabled, "terminal economy controls visibly disabled")
    scene._restart()
    scene.muted = true
    for spec in [[Vector2i(3, 3), "arc"], [Vector2i(5, 5), "nova"], [Vector2i(5, 3), "frost"], [Vector2i(7, 3), "arc"]]:
        assert(scene.match_model.place(spec[0], spec[1]))
    for wave in range(6):
        assert(scene.match_model.start_wave())
        for tick in range(18000):
            scene.match_model.advance(1.0 / 60)
            scene.match_model.consume_events()
            if scene.match_model.phase != "wave":
                break
        for cell in scene.combat_model.towers.keys():
            scene.match_model.upgrade(cell)
        for spec in [[Vector2i(8, 5), "arc"], [Vector2i(9, 3), "nova"], [Vector2i(7, 5), "frost"]]:
            scene.match_model.place(spec[0], spec[1])
    scene._update_hud()
    await process_frame
    assert(scene.match_model.phase == "won")
    assert(scene.results_label.position.y + scene.results_label.size.y < 382, "complete six-wave results must clear retry button")
    scene._restart()
    assert(scene.match_model.wave == 0 and scene.combat_model.towers.is_empty())
    await create_timer(0.4).timeout
    scene.queue_free()
    await process_frame
    await process_frame
    print("PASS: match scene, camera, HUD, placement, active wave, restart")
    quit(0)
