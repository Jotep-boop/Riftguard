class_name CombatModel
extends RefCounted

const TOWER_RANGE := 4.0
const TOWER_DAMAGE := 25.0
const TOWER_COOLDOWN := 0.65
const PROJECTILE_DURATION := 0.18

var towers: Dictionary = {}
var enemies: Dictionary = {}
var projectiles: Array[Dictionary] = []
var gold := 0
var events: Array[Dictionary] = []

func add_tower(cell: Vector2i) -> void:
    towers[cell] = {"cooldown": 0.0}

func remove_tower(cell: Vector2i) -> void:
    towers.erase(cell)

func add_enemy(id: String, position: Vector2, route_progress: float, max_health: float, reward: int) -> void:
    for index in range(projectiles.size() - 1, -1, -1):
        if projectiles[index].target_id == id:
            projectiles.remove_at(index)
    enemies[id] = {
        "position": position,
        "route_progress": route_progress,
        "health": max_health,
        "max_health": max_health,
        "reward": reward,
        "alive": true,
    }

func update_enemy(id: String, position: Vector2, route_progress: float) -> void:
    if not enemies.has(id):
        return
    enemies[id].position = position
    enemies[id].route_progress = route_progress

func consume_events() -> Array[Dictionary]:
    var emitted := events.duplicate(true)
    events.clear()
    return emitted

func advance(delta: float) -> void:
    _advance_projectiles(delta)
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
