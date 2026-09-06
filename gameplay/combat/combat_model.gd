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

const ROLES := {
    "arc": {"cost": 45, "damage": 25.0, "range": 3.0, "cadence": 0.65, "splash": 0.0, "slow": 0.0},
    "nova": {"cost": 65, "damage": 20.0, "range": 2.7, "cadence": 1.1, "splash": 1.3, "slow": 0.0},
    "frost": {"cost": 55, "damage": 8.0, "range": 3.0, "cadence": 0.85, "splash": 0.0, "slow": 1.6},
}

var towers: Dictionary = {}
var enemies: Dictionary = {}
var projectiles: Array[Dictionary] = []
var gold := 0
var events: Array[Dictionary] = []

func add_tower(cell: Vector2i, max_health: float = TOWER_MAX_HEALTH) -> void:
    towers[cell] = {
        "role": "arc", "level": 1, "invested": 45, "branch": "",
        "cooldown": 0.0,
        "health": max_health,
        "max_health": max_health,
    }

func configure_tower(cell: Vector2i, role: String) -> void:
    towers[cell].role = role
    towers[cell].invested = ROLES[role].cost

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
        "slow_timer": 0.0,
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

# Snapshot branch effects at fire time: selling/upgrading cannot alter in-flight shots.
func tower_stats(cell: Vector2i) -> Dictionary:
    var tower: Dictionary = towers[cell]
    var stats: Dictionary = ROLES[tower.role].duplicate()
    stats.damage *= 1.0 + 0.65 * (tower.level - 1)
    stats.duration = PROJECTILE_DURATION
    stats.chain = 0.0
    match tower.branch:
        "lance": stats.duration = 0.09
        "chain":
            stats.damage *= 0.6
            stats.chain = 1.8
        "wide":
            stats.damage *= 0.7
            stats.splash = 2.2
        "deep": stats.slow = 3.2
        "field": stats.splash = 1.3
    return stats

func advance(delta: float) -> void:
    for enemy in enemies.values():
        enemy.slow_timer = maxf(0.0, enemy.slow_timer - delta)
    _advance_projectiles(delta)
    _advance_breach_attacks(delta)
    for cell in towers:
        var tower: Dictionary = towers[cell]
        tower.cooldown = maxf(0.0, tower.cooldown - delta)
        if tower.cooldown > 0.0:
            continue
        var stats := tower_stats(cell)
        var target_id := _find_target(Vector2(cell), stats.range)
        if target_id.is_empty():
            continue
        projectiles.append({
            "origin": Vector2(cell),
            "role": tower.role,
            "damage": stats.damage, "chain": stats.chain,
            "splash": stats.splash, "slow": stats.slow,
            "target_id": target_id,
            "remaining": stats.duration,
            "duration": stats.duration,
        })
        tower.cooldown = stats.cadence
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
        var damage: float = enemy.get("breach_damage", ENEMY_BREACH_DAMAGE)
        tower.health = maxf(0.0, tower.health - damage)
        enemy.breach_cooldown = ENEMY_BREACH_COOLDOWN
        events.append({"type": "tower_hit", "tower_cell": target, "damage": damage})
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
        var center: Vector2 = enemies[target_id].position
        var secondary := ""
        var nearest: float = projectile.chain
        if nearest > 0:
            for id in enemies:
                var distance: float = enemies[id].position.distance_to(center)
                if id != target_id and enemies[id].alive and distance <= nearest:
                    if secondary == "" or distance < nearest:
                        secondary = id
                        nearest = distance
        for id in enemies:
            var enemy: Dictionary = enemies[id]
            if not enemy.alive or (id != target_id and id != secondary and (projectile.splash <= 0 or enemy.position.distance_to(center) > projectile.splash)):
                continue
            var dealt: float = minf(enemy.health, projectile.damage)
            enemy.health = maxf(0.0, enemy.health - dealt)
            enemy.slow_timer = maxf(enemy.slow_timer, projectile.slow)
            events.append({"type": "hit", "target_id": id, "position": enemy.position, "damage": dealt, "role": projectile.role})
            if enemy.health <= 0.0:
                enemy.alive = false
                gold += enemy.reward
                events.append({"type": "death", "target_id": id, "position": enemy.position, "reward": enemy.reward})

func _find_target(tower_position: Vector2, radius: float = TOWER_RANGE) -> String:
    var best_id := ""
    var best_progress := -INF
    for id in enemies:
        var enemy: Dictionary = enemies[id]
        if not enemy.alive:
            continue
        if tower_position.distance_to(enemy.position) > radius:
            continue
        if enemy.route_progress > best_progress:
            best_progress = enemy.route_progress
            best_id = id
    return best_id
