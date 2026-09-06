extends SceneTree

const GridPathfinder = preload("res://gameplay/board/grid_pathfinder.gd")
const BoardModel = preload("res://gameplay/board/board_model.gd")
const CombatModel = preload("res://gameplay/combat/combat_model.gd")

var failures := 0

func _init() -> void:
    _test_finds_a_direct_route()
    _test_routes_around_a_blocked_cell()
    _test_balances_an_unblocked_diagonal_route()
    _test_board_accepts_a_legal_blocker()
    _test_board_accepts_a_route_sealing_blocker_with_breach_plan()
    _test_board_builds_navigation_from_an_arbitrary_origin()
    _test_board_removes_a_blocker()
    _test_board_clears_all_blockers()
    _test_board_previews_a_legal_placement()
    _test_board_previews_a_route_sealing_placement()
    _test_combat_model_resource_exists()
    _test_tower_targets_enemy_furthest_along_route()
    _test_projectile_applies_damage_only_after_travel()
    _test_enemy_death_grants_reward_once()
    _test_enemy_position_update_changes_targetability()
    _test_removed_tower_stops_attacking()
    _test_combat_events_are_consumed_once()
    _test_respawn_discards_stale_projectiles()
    _test_tower_range_ends_at_three_cells()
    _test_enemy_attacks_breach_target_on_cooldown()
    _test_breach_attack_destroys_tower_and_emits_event()
    _test_towers_target_a_breaching_enemy()
    _test_entering_breach_preserves_incoming_hits()
    _test_incoming_lethal_hits_stop_breach_and_reward_once()
    if failures == 0:
        print("PASS: 24 tests")
        quit(0)
    else:
        push_error("FAIL: %d assertion(s)" % failures)
        quit(1)

func _test_finds_a_direct_route() -> void:
    var route: Array[Vector2i] = GridPathfinder.find_path(
        Vector2i(3, 1),
        Vector2i(0, 0),
        Vector2i(2, 0),
        {}
    )
    _expect(route.size() == 3, "direct route contains all three cells")
    _expect(route.front() == Vector2i(0, 0), "direct route starts at the rift")
    _expect(route.back() == Vector2i(2, 0), "direct route ends at the gate")

func _test_routes_around_a_blocked_cell() -> void:
    var blocked := {Vector2i(1, 0): true}
    var route: Array[Vector2i] = GridPathfinder.find_path(
        Vector2i(3, 2),
        Vector2i(0, 0),
        Vector2i(2, 0),
        blocked
    )
    _expect(not route.is_empty(), "an alternate route exists")
    _expect(not route.has(Vector2i(1, 0)), "route avoids blocked cells")
    _expect(route.size() == 5, "route takes the shortest detour")

func _test_balances_an_unblocked_diagonal_route() -> void:
    var route: Array[Vector2i] = GridPathfinder.find_path(
        Vector2i(4, 4),
        Vector2i(0, 0),
        Vector2i(3, 3),
        {}
    )
    var maximum_lateral_deviation := 0
    for cell in route:
        maximum_lateral_deviation = maxi(maximum_lateral_deviation, absi(cell.x - cell.y))
    _expect(maximum_lateral_deviation <= 1, "diagonal routes alternate axes to read as forward movement")

func _test_board_accepts_a_legal_blocker() -> void:
    var board = BoardModel.new(Vector2i(3, 2), Vector2i(0, 0), Vector2i(2, 0))
    var accepted: bool = board.try_place_blocker(Vector2i(1, 0))
    _expect(accepted, "board accepts a blocker when a detour remains")
    _expect(board.blocked.has(Vector2i(1, 0)), "accepted blocker is retained")

func _test_board_accepts_a_route_sealing_blocker_with_breach_plan() -> void:
    var board = BoardModel.new(Vector2i(3, 1), Vector2i(0, 0), Vector2i(2, 0))
    var accepted: bool = board.try_place_blocker(Vector2i(1, 0))
    _expect(accepted, "board accepts a blocker that seals the route")
    _expect(board.blocked.has(Vector2i(1, 0)), "route-sealing blocker is retained")
    _expect(board.route.is_empty(), "normal route is empty while the gate is sealed")
    _expect(board.breach_target == Vector2i(1, 0), "board selects the reachable sealing tower")
    _expect(board.breach_route == [Vector2i(0, 0)], "breach route ends beside the target tower")

func _test_board_builds_navigation_from_an_arbitrary_origin() -> void:
    var board = BoardModel.new(Vector2i(5, 3), Vector2i(0, 1), Vector2i(4, 1))
    for depth in range(3):
        board.try_place_blocker(Vector2i(3, depth))
    var current_cell := Vector2i(2, 1)
    _expect(board.has_method("refresh_navigation_from"), "board exposes navigation refresh from an arbitrary origin")
    if not board.has_method("refresh_navigation_from"):
        return
    board.refresh_navigation_from(current_cell)
    _expect(board.route.is_empty(), "arbitrary-origin navigation remains sealed by the next barrier")
    _expect(board.breach_target == Vector2i(3, 1), "arbitrary-origin navigation selects a reachable breach tower")
    _expect(board.breach_route.front() == current_cell, "arbitrary-origin breach route starts at the enemy cell")
    board.remove_blocker(Vector2i(3, 1))
    board.refresh_navigation_from(current_cell)
    _expect(board.route.front() == current_cell, "open navigation resumes at the enemy cell")
    _expect(board.route.back() == board.goal, "open navigation continues toward the canonical gate")
    _expect(board.start == Vector2i(0, 1), "navigation refresh preserves the canonical spawn cell")

func _test_board_removes_a_blocker() -> void:
    var board = BoardModel.new(Vector2i(3, 2), Vector2i(0, 0), Vector2i(2, 0))
    board.try_place_blocker(Vector2i(1, 0))
    board.remove_blocker(Vector2i(1, 0))
    _expect(not board.blocked.has(Vector2i(1, 0)), "removed blocker leaves the board")
    _expect(board.route.size() == 3, "route shortens after blocker removal")

func _test_board_clears_all_blockers() -> void:
    var board = BoardModel.new(Vector2i(4, 2), Vector2i(0, 0), Vector2i(3, 0))
    board.try_place_blocker(Vector2i(1, 0))
    board.try_place_blocker(Vector2i(2, 0))
    board.clear_blockers()
    _expect(board.blocked.is_empty(), "clear removes every blocker")

func _test_board_previews_a_legal_placement() -> void:
    var board = BoardModel.new(Vector2i(3, 2), Vector2i(0, 0), Vector2i(2, 0))
    _expect(board.has_method("can_place_blocker"), "board exposes placement preview")
    if board.has_method("can_place_blocker"):
        _expect(board.can_place_blocker(Vector2i(1, 0)), "preview accepts a legal detour")
        _expect(board.blocked.is_empty(), "preview does not mutate the board")

func _test_board_previews_a_route_sealing_placement() -> void:
    var board = BoardModel.new(Vector2i(3, 1), Vector2i(0, 0), Vector2i(2, 0))
    _expect(board.has_method("can_place_blocker"), "board exposes route-sealing preview")
    if board.has_method("can_place_blocker"):
        _expect(board.can_place_blocker(Vector2i(1, 0)), "preview accepts a sealed route once breach is supported")

func _test_combat_model_resource_exists() -> void:
    _expect(
        ResourceLoader.exists("res://gameplay/combat/combat_model.gd"),
        "combat model resource exists"
    )

func _test_tower_targets_enemy_furthest_along_route() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 1))
    combat.add_enemy("trailing", Vector2(2, 1), 0.2, 100.0, 5)
    combat.add_enemy("leading", Vector2(3, 1), 0.7, 100.0, 5)
    combat.advance(0.0)
    _expect(combat.projectiles.size() == 1, "tower fires one projectile when enemies are in range")
    if not combat.projectiles.is_empty():
        _expect(combat.projectiles[0].target_id == "leading", "tower targets the enemy furthest along the route")

func _test_projectile_applies_damage_only_after_travel() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 1))
    combat.add_enemy("enemy", Vector2(2, 1), 0.5, 100.0, 5)
    combat.advance(0.0)
    combat.advance(CombatModel.PROJECTILE_DURATION - 0.01)
    _expect(combat.enemies["enemy"].health == 100.0, "projectile does not damage before impact")
    combat.advance(0.01)
    _expect(combat.enemies["enemy"].health == 75.0, "projectile applies tower damage on impact")
    _expect(combat.projectiles.is_empty(), "resolved projectile is removed")

func _test_enemy_death_grants_reward_once() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 1))
    combat.add_enemy("enemy", Vector2(2, 1), 0.5, 25.0, 7)
    combat.advance(0.0)
    combat.advance(CombatModel.PROJECTILE_DURATION)
    _expect(not combat.enemies["enemy"].alive, "enemy dies when health reaches zero")
    _expect(combat.gold == 7, "enemy death grants its reward")
    combat.advance(CombatModel.TOWER_COOLDOWN * 2.0)
    _expect(combat.gold == 7, "dead enemy cannot grant its reward twice")

func _test_enemy_position_update_changes_targetability() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 1))
    combat.add_enemy("enemy", Vector2(8, 1), 0.1, 100.0, 5)
    combat.advance(0.0)
    _expect(combat.projectiles.is_empty(), "tower ignores enemies outside its range")
    combat.update_enemy("enemy", Vector2(2, 1), 0.5)
    combat.advance(0.0)
    _expect(combat.projectiles.size() == 1, "tower acquires an enemy after it enters range")

func _test_removed_tower_stops_attacking() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 1))
    combat.add_enemy("enemy", Vector2(2, 1), 0.5, 100.0, 5)
    combat.remove_tower(Vector2i(1, 1))
    combat.advance(0.0)
    _expect(combat.projectiles.is_empty(), "removed tower cannot fire")

func _test_combat_events_are_consumed_once() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 1))
    combat.add_enemy("enemy", Vector2(2, 1), 0.5, 100.0, 5)
    combat.advance(0.0)
    var emitted: Array[Dictionary] = combat.consume_events()
    _expect(emitted.size() == 1 and emitted[0].type == "shot", "combat emits a shot event")
    _expect(combat.consume_events().is_empty(), "combat events are delivered only once")

func _test_respawn_discards_stale_projectiles() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 1))
    combat.add_enemy("enemy", Vector2(2, 1), 0.5, 100.0, 5)
    combat.advance(0.0)
    combat.add_enemy("enemy", Vector2(0, 0), 0.0, 100.0, 5)
    combat.advance(CombatModel.PROJECTILE_DURATION)
    _expect(combat.enemies["enemy"].health == 100.0, "projectiles from a prior life cannot hit a respawned enemy")

func _test_tower_range_ends_at_three_cells() -> void:
    var boundary_combat = CombatModel.new()
    boundary_combat.add_tower(Vector2i(1, 1))
    boundary_combat.add_enemy("boundary", Vector2(4, 1), 0.5, 100.0, 5)
    boundary_combat.advance(0.0)
    _expect(boundary_combat.projectiles.size() == 1, "tower reaches an enemy exactly three cells away")

    var outside_combat = CombatModel.new()
    outside_combat.add_tower(Vector2i(1, 1))
    outside_combat.add_enemy("outside", Vector2(4.01, 1), 0.5, 100.0, 5)
    outside_combat.advance(0.0)
    _expect(outside_combat.projectiles.is_empty(), "tower ignores an enemy beyond three cells")

func _test_enemy_attacks_breach_target_on_cooldown() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 0))
    combat.add_enemy("enemy", Vector2(0, 0), 0.0, 100.0, 5)
    combat.set_enemy_breach_target("enemy", Vector2i(1, 0))
    combat.advance(0.0)
    _expect(combat.towers[Vector2i(1, 0)].health == 75.0, "breaching enemy damages an adjacent tower")
    combat.advance(CombatModel.ENEMY_BREACH_COOLDOWN - 0.01)
    _expect(combat.towers[Vector2i(1, 0)].health == 75.0, "breach attack waits for its cooldown")
    combat.advance(0.01)
    _expect(combat.towers[Vector2i(1, 0)].health == 50.0, "breach attack repeats after its cooldown")

func _test_breach_attack_destroys_tower_and_emits_event() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 0), 25.0)
    combat.add_enemy("enemy", Vector2(0, 0), 0.0, 100.0, 5)
    combat.set_enemy_breach_target("enemy", Vector2i(1, 0))
    combat.advance(0.0)
    _expect(not combat.towers.has(Vector2i(1, 0)), "lethal breach attack removes the destroyed tower")
    var emitted := combat.consume_events()
    _expect(emitted.any(func(event: Dictionary) -> bool: return event.type == "tower_destroyed"), "tower destruction emits a navigation event")

func _test_towers_target_a_breaching_enemy() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 0))
    combat.add_tower(Vector2i(2, 0))
    combat.add_enemy("enemy", Vector2(0, 0), 0.5, 100.0, 5)
    combat.add_enemy("trailing", Vector2(0, 0), 0.1, 100.0, 5)
    combat.set_enemy_breach_target("enemy", Vector2i(2, 0))
    combat.advance(0.0)
    _expect(combat.projectiles.size() == 2, "towers fire during breach approach")
    _expect(combat.projectiles.all(func(shot: Dictionary) -> bool: return shot.target_id == "enemy"), "breach approach uses ordinary route-progress targeting")
    _expect(combat.towers[Vector2i(2, 0)].health == 100.0, "approaching enemy cannot attack before reaching the tower")
    combat.update_enemy("enemy", Vector2(1, 0), 0.7)
    combat.advance(CombatModel.TOWER_COOLDOWN)
    _expect(combat.towers[Vector2i(2, 0)].health == 75.0, "enemy attacks after arriving beside breach target")
    _expect(combat.enemies["enemy"].health == 50.0, "breaching enemy takes normal projectile damage")
    _expect(combat.projectiles.size() == 2, "towers fire again while enemy attacks a tower")
    _expect(combat.projectiles.all(func(shot: Dictionary) -> bool: return shot.target_id == "enemy"), "attacking breacher keeps ordinary targeting priority")

func _test_entering_breach_preserves_incoming_hits() -> void:
    var combat = CombatModel.new()
    combat.add_tower(Vector2i(1, 0))
    combat.add_enemy("enemy", Vector2(2, 0), 0.5, 100.0, 5)
    combat.advance(0.0)
    _expect(combat.projectiles.size() == 1, "tower fires before the route becomes sealed")
    combat.advance(CombatModel.PROJECTILE_DURATION - 0.01)
    combat.set_enemy_breach_target("enemy", Vector2i(1, 0))
    combat.set_enemy_breach_target("enemy", Vector2i(1, 0))
    _expect(combat.projectiles.size() == 1, "entering and synchronizing breach preserves incoming projectiles")
    _expect(combat.enemies["enemy"].health == 100.0, "breach transition does not apply damage before impact")
    combat.advance(0.01)
    _expect(combat.enemies["enemy"].health == 75.0, "incoming projectile hits on its original schedule after breach entry")
    _expect(combat.projectiles.is_empty(), "incoming hit resolves normally during breach")

func _test_incoming_lethal_hits_stop_breach_and_reward_once() -> void:
    var combat = CombatModel.new()
    var target := Vector2i(1, 0)
    combat.add_tower(target)
    combat.add_tower(Vector2i(0, 1))
    combat.add_enemy("enemy", Vector2.ZERO, 0.5, 25.0, 7)
    combat.advance(0.0)
    _expect(combat.projectiles.size() == 2, "multiple lethal projectiles are incoming before breach entry")
    combat.consume_events()
    combat.set_enemy_breach_target("enemy", target)
    combat.advance(CombatModel.PROJECTILE_DURATION)
    _expect(not combat.enemies["enemy"].alive and combat.enemies["enemy"].health == 0.0, "incoming lethal hit kills a breaching enemy")
    _expect(combat.gold == 7, "multiple incoming hits pay the breacher reward exactly once")
    _expect(combat.towers[target].health == 100.0, "enemy killed on impact cannot attack its breach tower in the same step")
    var emitted := combat.consume_events()
    _expect(emitted.filter(func(event: Dictionary) -> bool: return event.type == "death" and event.reward == 7).size() == 1, "breacher emits exactly one normal death and reward event")
    _expect(emitted.filter(func(event: Dictionary) -> bool: return event.type == "hit").size() == 1, "extra projectiles do not hit the dead breacher")
    _expect(combat.consume_events().is_empty(), "breacher death events are consumed once")
    combat.advance(CombatModel.ENEMY_BREACH_COOLDOWN * 2.0)
    _expect(combat.gold == 7, "dead breacher cannot grant later rewards")
    _expect(combat.towers[target].health == 100.0, "dead breacher cannot attack on later cooldowns")
    _expect(combat.projectiles.is_empty() and combat.consume_events().is_empty(), "dead breacher produces no further shots or combat events")

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("Assertion failed: " + message)
