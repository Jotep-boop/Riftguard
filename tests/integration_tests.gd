extends SceneTree
const Match = preload("res://gameplay/match/match_model.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)
func test_stationary_breacher_target_priority() -> void:
    var game = Match.new()
    game.combat.gold = 2000
    for y in range(9):
        game.place(Vector2i(3, y), "arc")
    var approached: String = game.spawn_enemy("brute")
    game._move(approached, 3.0)
    check(game.combat.enemies[approached].cell == Vector2i(2, 4) and game.combat.enemies[approached].path.size() == 1, "priority fixture reaches stationary breach approach")
    for y in range(9):
        game.place(Vector2i(1, y), "arc")
    var fresh: String = game.spawn_enemy("brute")
    game._move(approached, 0.1)
    game._move(fresh, 0.1)
    check(game.combat.enemies[fresh].path.size() == 1 and game.combat.enemies[fresh].travelled == 0, "fresh adjacent breacher stays stationary")
    check(game.combat._find_target(Vector2(1, 4)) == approached, "stationary breacher with more travelled distance outranks fresh adjacent spawn")

func test_stationary_replanning_refreshes_priority() -> void:
    var game = Match.new()
    game.combat.gold = 2000
    var id: String = game.spawn_enemy("brute")
    game._move(id, 2.0 / game.combat.enemies[id].speed)
    var enemy: Dictionary = game.combat.enemies[id]
    check(enemy.cell == Vector2i(2, 4) and enemy.segment == 0, "replan fixture stops at cell boundary")
    var previous_priority: float = enemy.route_progress
    for y in range(9):
        game.place(Vector2i(3, y), "arc")
    game._plan(id)
    check(enemy.path.size() == 1 and enemy.breach_target == Vector2i(3, 4), "replan changes moving route into stationary breach")
    check(enemy.route_progress > previous_priority and is_equal_approx(enemy.route_progress, -1.0 + enemy.travelled * 0.00001), "stationary replan immediately replaces stale previous-route priority")
    for y in range(9):
        game.place(Vector2i(1, y), "arc")
    var fresh: String = game.spawn_enemy("brute")
    check(is_equal_approx(game.combat.enemies[fresh].route_progress, -1.0), "fresh stationary spawn has planned priority before movement")
    check(game.combat._find_target(Vector2(1, 4)) == id, "planned stationary priorities select travelled breacher before movement")

func _initialize() -> void:
    test_stationary_breacher_target_priority()
    test_stationary_replanning_refreshes_priority()
    var slow_game = Match.new()
    var slow_id: String = slow_game.spawn_enemy("scout")
    slow_game.combat.enemies[slow_id].slow_timer = 1.6
    slow_game.phase = "wave"
    slow_game.advance(0.1)
    var normal_game = Match.new()
    var normal_id: String = normal_game.spawn_enemy("scout")
    normal_game.phase = "wave"
    normal_game.advance(0.1)
    check(is_equal_approx(slow_game.combat.enemies[slow_id].position.x * 2, normal_game.combat.enemies[normal_id].position.x), "frost halves actual navigation speed")
    var upgrades = Match.new()
    upgrades.place(Vector2i(3, 3), "arc")
    check(upgrades.upgrade(Vector2i(3, 3)) and upgrades.upgrade(Vector2i(3, 3)), "two upgrade levels purchased")
    check(not upgrades.upgrade(Vector2i(3, 3)), "upgrade cap enforced")
    upgrades.combat.add_enemy("dummy", Vector2(3, 4), 0.5, 100, 10)
    upgrades.combat.advance(0)
    upgrades.combat.advance(0.18)
    check(is_equal_approx(upgrades.combat.enemies.dummy.health, 42.5), "level three increases actual projectile impact damage")
    check(upgrades.combat.ROLES.arc.range == 3.0, "upgrades preserve locked Arc range")
    var game = Match.new()
    var id: String = game.spawn_enemy("brute")
    game.phase = "wave"
    game.advance(0.3)
    var pos: Vector2 = game.combat.enemies[id].position
    check(not game.place(Vector2i(1, 4), "arc"), "cannot build on a reserved movement destination")
    check(game.place(Vector2i(2, 4), "arc"), "live placement away from enemy")
    check(game.revision > 0, "live placement invalidates per-enemy navigation")
    check(game.combat.enemies[id].position == pos, "placement does not teleport moving enemy")
    game.restart()
    game.combat.gold = 2000 # Breach fixture only; winning fixture below uses real budget.
    for x in [1, 3]:
        for y in range(9):
            game.place(Vector2i(x, y), "arc")
    id = game.spawn_enemy("brute")
    var other: String = game.spawn_enemy("scout")
    check(game.combat.enemies[id].breach_target == Vector2i(1, 4), "adjacent barrier spawn plans breach")
    check(game.combat.enemies[other].cell == Vector2i(0, 4), "multi-enemy canonical spawn")
    game.phase = "wave"
    game.combat.towers[Vector2i(1, 4)].health = 25
    game.advance(1.0 / 60)
    check(not game.board.blocked.has(Vector2i(1, 4)), "breach removes board occupancy")
    check(not game.combat.projectiles.is_empty(), "breach retains ordinary tower fire")
    game.advance(1.0 / 60)
    check(game.combat.enemies[id].position.x < 0.1, "replan maintains current origin")
    check(game.combat.enemies[id].breach_target == Vector2i(3, 4), "chained barrier selects next target")
    check(game.board.start == Vector2i(0, 4), "shared preview preserves canonical spawn")
    game.restart()
    for spec in [[Vector2i(3, 3), "arc"], [Vector2i(5, 5), "nova"], [Vector2i(5, 3), "frost"], [Vector2i(7, 3), "arc"]]:
        check(game.place(spec[0], spec[1]), "starting defense affordable")
    var peak := 0
    for wave in range(6):
        check(game.start_wave(), "finite wave starts")
        for tick in range(12000):
            game.advance(1.0 / 60)
            peak = maxi(peak, game.combat.enemies.size())
            game.consume_events()
            if game.phase != "wave":
                break
        print("Simulation wave %d: %s lives=%d gold=%d kills=%d" % [game.wave, game.phase, game.lives, game.combat.gold, game.kills])
        if game.phase == "lost":
            break
        for cell in game.combat.towers.keys():
            game.upgrade(cell)
        for spec in [[Vector2i(8, 5), "arc"], [Vector2i(9, 3), "nova"], [Vector2i(7, 5), "frost"]]:
            game.place(spec[0], spec[1])
    check(game.phase == "won" and game.wave == 6, "real-budget mixed defense wins all six waves")
    check(peak > 1, "wave simulation exercises simultaneous enemies")
    var gold: int = game.combat.gold
    game.advance(10)
    check(game.combat.gold == gold, "terminal state cannot pay repeatedly")
    check(not game.start_wave() and not game.place(Vector2i(10, 1), "arc"), "terminal state blocks match mutations")
    print("Integration failures: %d; peak concurrent enemies: %d" % [failures, peak])
    quit(1 if failures else 0)
