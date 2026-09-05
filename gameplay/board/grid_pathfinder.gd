class_name GridPathfinder
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [
    Vector2i.RIGHT,
    Vector2i.DOWN,
    Vector2i.LEFT,
    Vector2i.UP,
]

static func find_path(
    board_size: Vector2i,
    start: Vector2i,
    goal: Vector2i,
    blocked: Dictionary
) -> Array[Vector2i]:
    if not _is_inside(start, board_size) or not _is_inside(goal, board_size):
        return []
    if blocked.has(start) or blocked.has(goal):
        return []

    var frontier: Array[Vector2i] = [start]
    var frontier_index := 0
    var came_from: Dictionary = {start: start}

    while frontier_index < frontier.size():
        var current := frontier[frontier_index]
        frontier_index += 1
        if current == goal:
            return _reconstruct_path(came_from, start, goal)

        var next_cells: Array[Vector2i] = []
        for direction in DIRECTIONS:
            next_cells.append(current + direction)
        next_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
            var a_deviation := _line_deviation(a, start, goal)
            var b_deviation := _line_deviation(b, start, goal)
            if a_deviation != b_deviation:
                return a_deviation < b_deviation
            var a_remaining := absi(goal.x - a.x) + absi(goal.y - a.y)
            var b_remaining := absi(goal.x - b.x) + absi(goal.y - b.y)
            if a_remaining != b_remaining:
                return a_remaining < b_remaining
            return DIRECTIONS.find(a - current) < DIRECTIONS.find(b - current)
        )

        for next in next_cells:
            if _is_inside(next, board_size) and not blocked.has(next) and not came_from.has(next):
                came_from[next] = current
                frontier.append(next)

    return []

static func _line_deviation(cell: Vector2i, start: Vector2i, goal: Vector2i) -> int:
    var route_delta := goal - start
    var cell_delta := cell - start
    return absi(cell_delta.x * route_delta.y - cell_delta.y * route_delta.x)

static func _is_inside(cell: Vector2i, board_size: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < board_size.x and cell.y < board_size.y

static func _reconstruct_path(
    came_from: Dictionary,
    start: Vector2i,
    goal: Vector2i
) -> Array[Vector2i]:
    var reversed_path: Array[Vector2i] = [goal]
    var current := goal
    while current != start:
        current = came_from[current]
        reversed_path.append(current)
    reversed_path.reverse()
    return reversed_path
