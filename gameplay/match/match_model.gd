class_name MatchModel
extends RefCounted
const Board = preload("res://gameplay/board/board_model.gd")
const Combat = preload("res://gameplay/combat/combat_model.gd")
var board = Board.new(Vector2i(13, 9), Vector2i(0, 4), Vector2i(12, 4))
var combat = Combat.new()
var lives := 12
var phase := "build"
var wave := 0
var events: Array[Dictionary] = []
const ENEMIES := {
    "scout": {"health": 75.0, "speed": 1.35, "reward": 10},
    "runner": {"health": 55.0, "speed": 2.1, "reward": 10},
    "brute": {"health": 230.0, "speed": 0.85, "reward": 22},
}
const WAVES := [
    ["scout", "scout", "scout", "scout", "scout", "scout"],
    ["runner", "runner", "scout", "runner", "runner", "scout", "runner", "runner"],
    ["brute", "scout", "scout", "brute", "scout", "scout", "brute"],
    ["runner", "runner", "runner", "runner", "brute", "runner", "runner", "runner", "runner", "brute"],
    ["brute", "scout", "runner", "brute", "scout", "runner", "brute", "runner", "brute", "runner"],
    ["brute", "brute", "runner", "runner", "scout", "brute", "brute", "runner", "runner", "brute", "brute", "brute"],
]
var pending: Array = []
var spawn_timer := 0.0
var serial := 0
var kills := 0
var leaked := 0
var revision := 0

func restart() -> void:
    board = Board.new(Vector2i(13, 9), Vector2i(0, 4), Vector2i(12, 4))
    combat = Combat.new()
    combat.gold = 240
    lives = 12
    phase = "build"
    wave = 0
    pending.clear()
    events.clear()
    serial = 0
    kills = 0
    leaked = 0
    revision = 0
    spawn_timer = 0

func start_wave() -> bool:
    if phase != "build" or wave >= WAVES.size():
        return false
    pending = WAVES[wave].duplicate()
    wave += 1
    spawn_timer = 0
    phase = "wave"
    events.append({"type": "wave"})
    return true

func spawn_enemy(kind: String) -> String:
    serial += 1
    var id := "enemy_%d" % serial
    var stats: Dictionary = ENEMIES[kind]
    combat.add_enemy(id, Vector2(board.start), 0.0, stats.health * (1.0 + 0.12 * maxi(0, wave - 1)), stats.reward)
    var enemy: Dictionary = combat.enemies[id]
    enemy.kind = kind
    enemy.speed = stats.speed
    enemy.cell = board.start
    enemy.next = board.start
    enemy.segment = 0.0
    enemy.travelled = 0.0
    enemy.nav_revision = -1
    enemy.path = []
    _plan(id)
    return id

func _plan(id: String) -> void:
    var enemy: Dictionary = combat.enemies[id]
    board.refresh_navigation_from(enemy.cell)
    enemy.path = board.active_route().duplicate()
    enemy.route_progress = -float(enemy.path.size()) + enemy.segment + enemy.travelled * 0.00001
    enemy.nav_revision = revision
    combat.set_enemy_breach_target(id, board.breach_target)
    board.refresh_navigation_from(board.start)

func _move(id: String, delta: float) -> void:
    var enemy: Dictionary = combat.enemies[id]
    var remaining: float = enemy.speed * delta * (0.5 if enemy.slow_timer > 0 else 1.0)
    while remaining > 0 and enemy.alive:
        if enemy.segment == 0.0:
            if enemy.nav_revision != revision:
                _plan(id)
            if enemy.path.size() <= 1:
                enemy.route_progress = -float(enemy.path.size()) + enemy.segment + enemy.travelled * 0.00001
                if enemy.cell == board.goal:
                    enemy.alive = false
                    lives = maxi(0, lives - 1)
                    leaked += 1
                    events.append({"type": "leak", "position": enemy.position})
                return
            enemy.next = enemy.path[1]
        var step := minf(remaining, 1.0 - enemy.segment)
        enemy.segment += step
        enemy.travelled += step
        remaining -= step
        enemy.position = Vector2(enemy.cell).lerp(Vector2(enemy.next), enemy.segment)
        # Smaller remaining route wins priority; travelled breaks equal-distance ties.
        enemy.route_progress = -float(enemy.path.size()) + enemy.segment + enemy.travelled * 0.00001
        if enemy.segment >= 0.99999:
            enemy.cell = enemy.next
            enemy.segment = 0.0
            enemy.path.pop_front()

func advance(delta: float) -> void:
    if phase != "wave":
        return
    # Fixed-step caller; cap pathological frame stalls rather than skipping combat.
    spawn_timer -= delta
    if not pending.is_empty() and spawn_timer <= 0:
        spawn_enemy(pending.pop_front())
        spawn_timer += 0.72
    for id in combat.enemies:
        if combat.enemies[id].alive:
            _move(id, delta)
    combat.advance(delta)
    for event in combat.consume_events():
        if event.type == "tower_destroyed":
            board.remove_blocker(event.tower_cell)
            revision += 1
        elif event.type == "death":
            kills += 1
        events.append(event)
    for id in combat.enemies.keys():
        if not combat.enemies[id].alive:
            combat.enemies.erase(id)
    if lives <= 0:
        phase = "lost"
        combat.projectiles.clear()
        events.append({"type": "lost"})
    elif pending.is_empty() and combat.enemies.is_empty():
        combat.gold += 30
        combat.projectiles.clear()
        phase = "won" if wave == WAVES.size() else "build"
        events.append({"type": phase})

func consume_events() -> Array[Dictionary]:
    var result := events.duplicate(true)
    events.clear()
    return result

func _init() -> void:
    combat.gold = 240

func can_place(cell: Vector2i, role: String) -> bool:
    if phase in ["won", "lost"] or not Combat.ROLES.has(role):
        return false
    if not board.can_place_blocker(cell) or combat.gold < Combat.ROLES[role].cost:
        return false
    for enemy in combat.enemies.values():
        if enemy.alive and (enemy.position.distance_to(Vector2(cell)) < 0.8 or (enemy.get("segment", 0.0) > 0 and enemy.get("next") == cell)):
            return false
    return true

func place(cell: Vector2i, role: String) -> bool:
    if not can_place(cell, role):
        return false
    board.try_place_blocker(cell)
    revision += 1
    combat.add_tower(cell)
    combat.configure_tower(cell, role)
    combat.gold -= Combat.ROLES[role].cost
    return true

func upgrade_cost(cell: Vector2i) -> int:
    if not combat.towers.has(cell):
        return 0
    return 35 * combat.towers[cell].level

func upgrade(cell: Vector2i) -> bool:
    if phase in ["won", "lost"] or not combat.towers.has(cell):
        return false
    var tower: Dictionary = combat.towers[cell]
    var cost := upgrade_cost(cell)
    if tower.level >= 3 or combat.gold < cost:
        return false
    combat.gold -= cost
    tower.invested += cost
    tower.level += 1
    tower.max_health += 35
    tower.health = tower.max_health
    return true

func sell_value(cell: Vector2i) -> int:
    return floori(combat.towers[cell].invested * 0.7) if combat.towers.has(cell) else 0

func sell(cell: Vector2i) -> bool:
    if phase in ["won", "lost"] or not combat.towers.has(cell):
        return false
    combat.gold += sell_value(cell)
    combat.remove_tower(cell)
    board.remove_blocker(cell)
    revision += 1
    return true
