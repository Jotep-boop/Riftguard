extends SceneTree

func _initialize() -> void:
    var packed_scene := load("res://main/main.tscn") as PackedScene
    if packed_scene == null:
        push_error("Main scene could not be loaded")
        quit(1)
        return

    var instance := packed_scene.instantiate()
    root.add_child(instance)
    await process_frame
    await process_frame

    if instance.get("board_model") == null:
        push_error("Main scene did not initialize its board model")
        quit(1)
        return

    if instance.get("combat_model") == null:
        push_error("Main scene did not initialize its combat model")
        quit(1)
        return
    if not instance.combat_model.enemies.has("scout"):
        push_error("Main scene must spawn the combat slice enemy")
        quit(1)
        return

    if instance.board_model.size != Vector2i(13, 9):
        push_error("The playfield must be 13 cells long and 9 cells wide")
        quit(1)
        return
    if instance.board_model.start.x != 0 or instance.board_model.goal.x != 12:
        push_error("Rift and gate must remain on opposite short sides")
        quit(1)
        return
    if instance.board_model.start.y != 4 or instance.board_model.goal.y != 4:
        push_error("Rift and gate must be centered on the 9-cell short sides")
        quit(1)
        return

    var start_world: Vector2 = instance.call("_cell_to_world", instance.board_model.start)
    var goal_world: Vector2 = instance.call("_cell_to_world", instance.board_model.goal)
    if goal_world.x <= start_world.x:
        push_error("Enemy flow must cross the screen toward the guarded exit")
        quit(1)
        return
    if absf(goal_world.y - start_world.y) > 1.0:
        push_error("The long-side camera must read the route as lateral movement")
        quit(1)
        return

    var near_tile: PackedVector2Array = instance.call(
        "_tile_polygon", instance.board_model.goal, 1.0
    )
    var near_cell_depth := absf(near_tile[3].y - near_tile[0].y)
    var near_cell_width := absf(near_tile[1].x - near_tile[0].x)
    if near_cell_depth < near_cell_width * 0.5:
        push_error("Camera angle is too low for readable cells behind walls")
        quit(1)
        return

    print("PASS: main scene smoke test")
    quit(0)
