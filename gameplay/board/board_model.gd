class_name BoardModel
extends RefCounted

const GridPathfinderScript = preload("res://gameplay/board/grid_pathfinder.gd")
const NO_CELL := Vector2i(-1, -1)

var size: Vector2i
var start: Vector2i
var goal: Vector2i
var blocked: Dictionary = {}
var route: Array[Vector2i] = []
var breach_target := NO_CELL
var breach_route: Array[Vector2i] = []

func _init(board_size: Vector2i, route_start: Vector2i, route_goal: Vector2i) -> void:
    size = board_size
    start = route_start
    goal = route_goal
    _refresh_navigation(start)

func can_place_blocker(cell: Vector2i) -> bool:
    return _is_buildable(cell) and not blocked.has(cell)

func try_place_blocker(cell: Vector2i) -> bool:
    if not can_place_blocker(cell):
        return false
    blocked[cell] = true
    _refresh_navigation(start)
    return true

func remove_blocker(cell: Vector2i) -> bool:
    if not blocked.erase(cell):
        return false
    _refresh_navigation(start)
    return true

func clear_blockers() -> void:
    blocked.clear()
    _refresh_navigation(start)

func active_route() -> Array[Vector2i]:
    return route if not route.is_empty() else breach_route

func refresh_navigation_from(origin: Vector2i) -> void:
    _refresh_navigation(origin)

func _refresh_navigation(origin: Vector2i) -> void:
    route = GridPathfinderScript.find_path(size, origin, goal, blocked)
    breach_target = NO_CELL
    breach_route.clear()
    if route.is_empty() and not blocked.is_empty():
        _select_breach_plan(origin)

func _select_breach_plan(origin: Vector2i) -> void:
    var best_goal_distance := 1 << 30
    var best_route_length := 1 << 30
    var best_target := NO_CELL
    var best_route: Array[Vector2i] = []

    for candidate_variant in blocked.keys():
        var candidate: Vector2i = candidate_variant
        var passable := blocked.duplicate()
        passable.erase(candidate)
        var approach := GridPathfinderScript.find_path(size, origin, candidate, passable)
        if approach.size() < 2:
            continue
        approach.pop_back()
        var goal_distance := absi(goal.x - candidate.x) + absi(goal.y - candidate.y)
        var route_length := approach.size()
        if _is_better_breach_candidate(
            candidate,
            goal_distance,
            route_length,
            best_target,
            best_goal_distance,
            best_route_length
        ):
            best_target = candidate
            best_goal_distance = goal_distance
            best_route_length = route_length
            best_route = approach

    breach_target = best_target
    breach_route = best_route

func _is_better_breach_candidate(
    candidate: Vector2i,
    goal_distance: int,
    route_length: int,
    current: Vector2i,
    current_goal_distance: int,
    current_route_length: int
) -> bool:
    if current == NO_CELL or goal_distance != current_goal_distance:
        return current == NO_CELL or goal_distance < current_goal_distance
    if route_length != current_route_length:
        return route_length < current_route_length
    if candidate.x != current.x:
        return candidate.x < current.x
    return candidate.y < current.y

func _is_buildable(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y \
        and cell != start and cell != goal
