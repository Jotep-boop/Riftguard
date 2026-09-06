class_name CombatModel
extends RefCounted

const TOWER_RANGE := 3.0
const TOWER_DAMAGE := 25.0
const TOWER_COOLDOWN := 0.65
const PROJECTILE_DURATION := 0.18
const TOWER_MAX_HEALTH := 100.0
const ENEMY_BREACH_DAMAGE := 25.0
const ENEMY_BREACH_COOLDOWN := 0.75
const BREACH_ATTACK_RANGE := 1.01
const NO_CELL := Vector2i(-1, -1)

var towers: Dictionary = {}
var enemies: Dictionary = {}
var projectiles: Array[Dictionary] = []
var gold := 0
var events: Array[Dictionary] = []

func add_tower(cell: Vector2i, max_health: float = TOWER_MAX_HEALTH) -> void:
    towers[cell] = {
        "cooldown": 0.0,
        "health": max_health,
        "max_health": max_health,
    }

func remove_tower(cell: Vector2i) -> void:
    towers.erase(cell)

func add_enemy(id: String, position: Vector2, route_progress: float, max_health: float, reward: int) -> void:
    _discard_projectiles_for(id)
    enemies[id] = {
        "position": position,
        "route_progress": route_progress,
        "health": max_health,
        "max_health": max_health,
        "reward": reward,
        "alive": true,
        "breach_target": NO_CELL,
        "breach_cooldown": 0.0,
    }

func update_enemy(id: String, position: Vector2, route_progress: float) -> void:
    if not enemies.has(id):
        return
    enemies[id].position = position
    enemies[id].route_progress = route_progress

func set_enemy_breach_target(id: String, target: Vector2i) -> void:
    if not enemies.has(id):
        return
    var enemy: Dictionary = enemies[id]
    if enemy.breach_target != target:
        enemy.breach_cooldown = 0.0
    enemy.breach_target = target

func _discard_projectiles_for(id: String) -> void:
    for index in range(projectiles.size() - 1, -1, -1):
        if projectiles[index].target_id == id:
            projectiles.remove_at(index)

func consume_events() -> Array[Dictionary]:
    var emitted := events.duplicate(true)
    events.clear()
    return emitted

func advance(delta: float) -> void:
    _advance_projectiles(delta)
    _advance_breach_attacks(delta)
    for cell in towers:
        var tower: Dictionary = towers[cell]
        tower.cooldown = maxf(0.0, tower.cooldown - delta)
        if tower.cooldown > 0.0:
            continue
        var target_id := _find_target(Vector2(cell))
        if target_id.is_empty():
            continue
        projectiles.append({
            "origin": Vector2(cell),
            "target_id": target_id,
            "remaining": PROJECTILE_DURATION,
            "duration": PROJECTILE_DURATION,
        })
        tower.cooldown = TOWER_COOLDOWN
        events.append({"type": "shot", "tower_cell": cell, "target_id": target_id})

func _advance_breach_attacks(delta: float) -> void:
    for id in enemies:
        var enemy: Dictionary = enemies[id]
        if not enemy.alive or enemy.breach_target == NO_CELL:
            continue
        var target: Vector2i = enemy.breach_target
        if not towers.has(target):
            enemy.breach_target = NO_CELL
            continue
        if enemy.position.distance_to(Vector2(target)) > BREACH_ATTACK_RANGE:
            continue
        enemy.breach_cooldown = maxf(0.0, enemy.breach_cooldown - delta)
        if enemy.breach_cooldown > 0.0001:
            continue
        var tower: Dictionary = towers[target]
        tower.health = maxf(0.0, tower.health - ENEMY_BREACH_DAMAGE)
        enemy.breach_cooldown = ENEMY_BREACH_COOLDOWN
        events.append({"type": "tower_hit", "tower_cell": target, "damage": ENEMY_BREACH_DAMAGE})
        if tower.health <= 0.0:
            towers.erase(target)
            events.append({"type": "tower_destroyed", "tower_cell": target})

func _advance_projectiles(delta: float) -> void:
    for index in range(projectiles.size() - 1, -1, -1):
        var projectile: Dictionary = projectiles[index]
        projectile.remaining -= delta
        if projectile.remaining > 0.0001:
            continue
        projectiles.remove_at(index)
        var target_id: String = projectile.target_id
        if not enemies.has(target_id) or not enemies[target_id].alive:
            continue
        var enemy: Dictionary = enemies[target_id]
        enemy.health = maxf(0.0, enemy.health - TOWER_DAMAGE)
        events.append({"type": "hit", "target_id": target_id, "damage": TOWER_DAMAGE})
        if enemy.health <= 0.0:
            enemy.alive = false
            gold += enemy.reward
            events.append({"type": "death", "target_id": target_id, "reward": enemy.reward})

func _find_target(tower_position: Vector2) -> String:
    var best_id := ""
    var best_progress := -INF
    for id in enemies:
        var enemy: Dictionary = enemies[id]
        if not enemy.alive:
            continue
        if tower_position.distance_to(enemy.position) > TOWER_RANGE:
            continue
        if enemy.route_progress > best_progress:
            best_progress = enemy.route_progress
            best_id = id
    return best_id
