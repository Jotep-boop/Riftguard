class_name BoardModel
extends RefCounted

const GridPathfinderScript = preload("res://gameplay/board/grid_pathfinder.gd")

var size: Vector2i
var start: Vector2i
var goal: Vector2i
var blocked: Dictionary = {}
var route: Array[Vector2i] = []

func _init(board_size: Vector2i, route_start: Vector2i, route_goal: Vector2i) -> void:
    size = board_size
    start = route_start
    goal = route_goal
    route = GridPathfinderScript.find_path(size, start, goal, blocked)

func can_place_blocker(cell: Vector2i) -> bool:
    if not _is_buildable(cell) or blocked.has(cell):
        return false
    var preview_blocked := blocked.duplicate()
    preview_blocked[cell] = true
    return not GridPathfinderScript.find_path(size, start, goal, preview_blocked).is_empty()

func try_place_blocker(cell: Vector2i) -> bool:
    if not can_place_blocker(cell):
        return false

    blocked[cell] = true
    route = GridPathfinderScript.find_path(size, start, goal, blocked)
    return true

func remove_blocker(cell: Vector2i) -> bool:
    if not blocked.erase(cell):
        return false
    route = GridPathfinderScript.find_path(size, start, goal, blocked)
    return true

func clear_blockers() -> void:
    blocked.clear()
    route = GridPathfinderScript.find_path(size, start, goal, blocked)

func _is_buildable(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y \
        and cell != start and cell != goal
