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

    if instance.board_model.size != Vector2i(12, 8):
        push_error("The playfield must retain its rectangular 12x8 layout")
        quit(1)
        return
    if instance.board_model.start.x != 0 or instance.board_model.goal.x != 11:
        push_error("Rift and gate must remain on opposite short sides")
        quit(1)
        return
    if instance.board_model.start.y != instance.board_model.goal.y \
        or instance.board_model.start.y not in [3, 4]:
        push_error("Rift and gate must be centered on the short sides")
        quit(1)
        return

    var start_world: Vector2 = instance.call("_cell_to_world", instance.board_model.start)
    var goal_world: Vector2 = instance.call("_cell_to_world", instance.board_model.goal)
    if goal_world.y <= start_world.y:
        push_error("The guarded exit must be closer to the camera than the rift")
        quit(1)
        return
    if absf(goal_world.x - start_world.x) > 1.0:
        push_error("The main enemy flow must read as downward on screen")
        quit(1)
        return

    print("PASS: main scene smoke test")
    quit(0)
