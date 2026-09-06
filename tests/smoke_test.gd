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

    for barrier_x in [1, 3]:
        for depth in range(9):
            instance.hovered_cell = Vector2i(barrier_x, depth)
            instance.call("_place_hovered_tower")
    await process_frame
    if not instance.board_model.route.is_empty():
        push_error("Two complete tower walls must seal the normal route")
        quit(1)
        return
    if instance.board_model.breach_target == Vector2i(-1, -1) or instance.board_model.breach_route.is_empty():
        push_error("A sealed board must expose a reachable breach plan")
        quit(1)
        return
    if instance.combat_model.towers.size() != 18:
        push_error("Route-sealing placement must keep board and combat towers synchronized")
        quit(1)
        return

    instance.call("_reset_enemy_movement")
    var target: Vector2i = instance.board_model.breach_target
    if instance.combat_model.enemies["scout"].breach_target != target:
        push_error("Blocked enemy must target the board's breach tower")
        quit(1)
        return
    instance.combat_model.towers[target].health = 25.0
    instance.combat_model.enemies["scout"].breach_cooldown = 0.0
    var attack_cell: Vector2i = instance.board_model.breach_route.back()
    instance.combat_model.update_enemy("scout", Vector2(attack_cell), 0.0)
    instance.combat_model.projectiles.clear()
    instance.combat_model.consume_events()
    for cell in instance.combat_model.towers:
        instance.combat_model.towers[cell].cooldown = 0.0
    instance.combat_model.advance(0.0)
    if not _verify_ordinary_tower_fire(instance, "Chained breach destruction"):
        return
    instance.call("_handle_combat_events")
    if instance.board_model.blocked.has(target) or instance.combat_model.towers.has(target):
        push_error("Destroyed breach tower must leave both board and combat state")
        quit(1)
        return
    if Vector2i(instance.call("_enemy_grid_position").round()) != attack_cell:
        push_error("Chained breach replanning must preserve the enemy's current cell")
        quit(1)
        return
    var next_target: Vector2i = instance.board_model.breach_target
    if not instance.board_model.route.is_empty() or next_target == Vector2i(-1, -1) or next_target == target:
        push_error("Chained breach replanning must select the next barrier target")
        quit(1)
        return
    if instance.combat_model.enemies["scout"].breach_target != next_target:
        push_error("Chained breach replanning must synchronize the next combat target")
        quit(1)
        return

    var advanced_cell := Vector2i(2, 4)
    instance.call("_resume_navigation_from", advanced_cell)
    for cell in instance.combat_model.towers:
        instance.combat_model.towers[cell].cooldown = 0.0
    instance.combat_model.projectiles.clear()
    instance.combat_model.consume_events()
    instance.call("_spawn_enemy")
    if instance.board_model.active_route().front() != instance.board_model.start:
        push_error("A newly spawned enemy must restore navigation from the canonical start")
        quit(1)
        return
    var spawn_target: Vector2i = instance.board_model.breach_target
    if spawn_target == Vector2i(-1, -1) or instance.combat_model.enemies["scout"].breach_target != spawn_target:
        push_error("A sealed-board respawn must enter breach mode before combat advances")
        quit(1)
        return
    instance.combat_model.advance(0.0)
    if not _verify_ordinary_tower_fire(instance, "Sealed-board respawn"):
        return

    print("PASS: main scene smoke test")
    quit(0)

func _verify_ordinary_tower_fire(instance: Node, context: String) -> bool:
    var combat = instance.combat_model
    var expected_shots := 0
    for cell in combat.towers:
        var in_range: bool = Vector2(cell).distance_to(combat.enemies["scout"].position) <= combat.TOWER_RANGE
        var expected_cooldown: float = combat.TOWER_COOLDOWN if in_range else 0.0
        if in_range:
            expected_shots += 1
        if not is_equal_approx(combat.towers[cell].cooldown, expected_cooldown):
            push_error(context + ": only in-range towers must consume normal firing cooldowns")
            quit(1)
            return false
    var shots: Array = combat.events.filter(func(event: Dictionary) -> bool: return event.type == "shot")
    if expected_shots == 0 or combat.projectiles.size() != expected_shots or shots.size() != expected_shots:
        push_error(context + ": every in-range tower must emit a shot and projectile")
        quit(1)
        return false
    if not shots.all(func(event: Dictionary) -> bool: return event.target_id == "scout"):
        push_error(context + ": towers must target the breaching scout")
        quit(1)
        return false
    return true
