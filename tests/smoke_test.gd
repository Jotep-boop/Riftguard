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

    print("PASS: main scene smoke test")
    quit(0)
