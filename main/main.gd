extends Node2D

const BoardModelScript = preload("res://gameplay/board/board_model.gd")

const BOARD_SIZE := Vector2i(12, 8)
const START_CELL := Vector2i(0, 3)
const GOAL_CELL := Vector2i(11, 3)
const BOARD_CENTER_X := 650.0
const BOARD_TOP_Y := 126.0
const BOARD_BOTTOM_Y := 590.0
const TOP_CELL_WIDTH := 52.0
const BOTTOM_CELL_WIDTH := 90.0
const BLOCK_HEIGHT := 34.0
const ENEMY_SPEED := 125.0

const COLOR_FLOOR_A := Color("#26384b")
const COLOR_FLOOR_B := Color("#2b4154")
const COLOR_GRID := Color("#587084")
const COLOR_ROUTE := Color("#59d8ee")
const COLOR_VALID := Color("#58e6ad")
const COLOR_INVALID := Color("#ff6b74")
const COLOR_RIFT := Color("#d852ff")
const COLOR_GATE := Color("#ffc85c")

var board_model
var hovered_cell := Vector2i(-1, -1)
var show_route := true
var enemy_position := Vector2.ZERO
var enemy_route_index := 0
var enemy_segment_progress := 0.0
var status_label: Label
var route_label: Label

func _ready() -> void:
    board_model = BoardModelScript.new(BOARD_SIZE, START_CELL, GOAL_CELL)
    _build_interface()
    _reset_enemy()
    queue_redraw()

func _process(delta: float) -> void:
    _advance_enemy(delta)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        hovered_cell = _cell_at_point(event.position)
        queue_redraw()
    elif event is InputEventMouseButton and event.pressed:
        hovered_cell = _cell_at_point(event.position)
        if event.button_index == MOUSE_BUTTON_LEFT:
            _place_hovered_blocker()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            _remove_hovered_blocker()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            board_model.clear_blockers()
            _set_status("Maze cleared. The rift has a straight shot again.", COLOR_ROUTE)
            _reset_enemy()
        elif event.keycode == KEY_D:
            show_route = not show_route
            route_label.text = "Route overlay: %s" % ("ON" if show_route else "OFF")
        queue_redraw()

func _draw() -> void:
    _draw_board()
    if show_route:
        _draw_route()
    _draw_endpoints()
    _draw_blockers()
    _draw_hover_preview()
    _draw_enemy()

func _draw_board() -> void:
    for depth in range(BOARD_SIZE.x):
        for lateral in range(BOARD_SIZE.y):
            var cell := Vector2i(depth, lateral)
            var fill := COLOR_FLOOR_A if (depth + lateral) % 2 == 0 else COLOR_FLOOR_B
            var tile := _tile_polygon(cell, 1.0)
            draw_colored_polygon(tile, fill)
            draw_polyline(_close_polygon(tile), COLOR_GRID, 1.2, true)

func _draw_route() -> void:
    if board_model.route.size() < 2:
        return
    var points := PackedVector2Array()
    for cell in board_model.route:
        points.append(_cell_to_world(cell) - Vector2(0.0, 7.0))
    draw_polyline(points, Color(0.08, 0.18, 0.24, 0.9), 10.0, true)
    draw_polyline(points, Color(COLOR_ROUTE, 0.9), 3.0, true)
    for point in points:
        draw_circle(point, 3.5, Color.WHITE)

func _draw_endpoints() -> void:
    var rift_center := _cell_to_world(START_CELL) - Vector2(0.0, 7.0)
    draw_circle(rift_center, 25.0, Color(COLOR_RIFT, 0.13))
    draw_circle(rift_center, 16.0, Color("#6e238f"))
    draw_arc(rift_center, 19.0, 0.0, TAU, 32, COLOR_RIFT, 3.0, true)

    var gate_center := _cell_to_world(GOAL_CELL)
    var gate_tile := _scaled_polygon(_tile_polygon(GOAL_CELL, 1.0), gate_center, 0.53)
    draw_colored_polygon(gate_tile, Color("#6b5126"))
    draw_polyline(_close_polygon(gate_tile), COLOR_GATE, 3.0, true)

func _draw_blockers() -> void:
    for depth in range(BOARD_SIZE.x):
        for cell in board_model.blocked.keys():
            if cell.x == depth:
                _draw_prism(cell, Color("#4f92a3"), 1.0)

func _draw_hover_preview() -> void:
    if not _inside_board(hovered_cell) or board_model.blocked.has(hovered_cell):
        return
    var allowed: bool = board_model.can_place_blocker(hovered_cell)
    _draw_prism(
        hovered_cell,
        Color(COLOR_VALID if allowed else COLOR_INVALID, 0.62),
        0.88
    )

func _draw_prism(cell: Vector2i, color: Color, scale_factor: float) -> void:
    var base := _tile_polygon(cell, scale_factor)
    var top := PackedVector2Array()
    for point in base:
        top.append(point - Vector2(0.0, BLOCK_HEIGHT))
    var front_side := PackedVector2Array([top[3], top[2], base[2], base[3]])
    var right_side := PackedVector2Array([top[1], base[1], base[2], top[2]])
    draw_colored_polygon(front_side, color.darkened(0.42))
    draw_colored_polygon(right_side, color.darkened(0.25))
    draw_colored_polygon(top, color.lightened(0.12))
    draw_polyline(_close_polygon(top), color.lightened(0.35), 1.6, true)
    draw_line(top[2], base[2], color.darkened(0.5), 1.5, true)

func _draw_enemy() -> void:
    draw_set_transform(enemy_position + Vector2(0.0, 8.0), 0.0, Vector2(1.3, 0.48))
    draw_circle(Vector2.ZERO, 13.0, Color(0.0, 0.0, 0.0, 0.32))
    draw_set_transform(Vector2.ZERO)
    var body := enemy_position - Vector2(0.0, 17.0)
    draw_circle(body, 12.5, Color("#f05fd2"))
    draw_circle(body - Vector2(3.5, 3.5), 4.0, Color("#ffd7f6"))
    draw_arc(body, 14.5, 0.0, TAU, 24, Color("#6f235e"), 2.0, true)

func _place_hovered_blocker() -> void:
    if board_model.try_place_blocker(hovered_cell):
        _set_status("Barricade placed — route recalculated.", COLOR_VALID)
        _reset_enemy()
    else:
        _set_status("Placement rejected — the rift must retain a route.", COLOR_INVALID)
    queue_redraw()

func _remove_hovered_blocker() -> void:
    if board_model.remove_blocker(hovered_cell):
        _set_status("Barricade removed.", COLOR_ROUTE)
        _reset_enemy()
        queue_redraw()

func _reset_enemy() -> void:
    enemy_route_index = 0
    enemy_segment_progress = 0.0
    if not board_model.route.is_empty():
        enemy_position = _cell_to_world(board_model.route.front())

func _advance_enemy(delta: float) -> void:
    if board_model.route.size() < 2:
        return
    var remaining := ENEMY_SPEED * delta
    while remaining > 0.0:
        var from := _cell_to_world(board_model.route[enemy_route_index])
        var next_index := enemy_route_index + 1
        if next_index >= board_model.route.size():
            _reset_enemy()
            return
        var to := _cell_to_world(board_model.route[next_index])
        var segment_length := from.distance_to(to)
        var distance_left := segment_length * (1.0 - enemy_segment_progress)
        if remaining < distance_left:
            enemy_segment_progress += remaining / segment_length
            enemy_position = from.lerp(to, enemy_segment_progress)
            return
        remaining -= distance_left
        enemy_route_index = next_index
        enemy_segment_progress = 0.0
        enemy_position = to

func _cell_to_world(cell: Vector2i) -> Vector2:
    var tile := _tile_polygon(cell, 1.0)
    var center := Vector2.ZERO
    for point in tile:
        center += point
    return center / tile.size()

func _cell_at_point(point: Vector2) -> Vector2i:
    for depth in range(BOARD_SIZE.x):
        for lateral in range(BOARD_SIZE.y):
            var cell := Vector2i(depth, lateral)
            if Geometry2D.is_point_in_polygon(point, _tile_polygon(cell, 1.0)):
                return cell
    return Vector2i(-1, -1)

func _inside_board(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < BOARD_SIZE.x and cell.y < BOARD_SIZE.y

func _tile_polygon(cell: Vector2i, scale_factor: float) -> PackedVector2Array:
    var corners := PackedVector2Array([
        _grid_point(cell.x, cell.y),
        _grid_point(cell.x, cell.y + 1),
        _grid_point(cell.x + 1, cell.y + 1),
        _grid_point(cell.x + 1, cell.y),
    ])
    return _scaled_polygon(corners, _polygon_center(corners), scale_factor)

func _grid_point(depth_boundary: int, lateral_boundary: int) -> Vector2:
    var depth_ratio := float(depth_boundary) / BOARD_SIZE.x
    var row_width := lerpf(TOP_CELL_WIDTH, BOTTOM_CELL_WIDTH, depth_ratio)
    return Vector2(
        BOARD_CENTER_X + (lateral_boundary - 3.5) * row_width,
        lerpf(BOARD_TOP_Y, BOARD_BOTTOM_Y, depth_ratio)
    )

func _polygon_center(points: PackedVector2Array) -> Vector2:
    var center := Vector2.ZERO
    for point in points:
        center += point
    return center / points.size()

func _scaled_polygon(
    points: PackedVector2Array,
    center: Vector2,
    scale_factor: float
) -> PackedVector2Array:
    var scaled := PackedVector2Array()
    for point in points:
        scaled.append(center + (point - center) * scale_factor)
    return scaled

func _close_polygon(points: PackedVector2Array) -> PackedVector2Array:
    var closed := points.duplicate()
    closed.append(points[0])
    return closed

func _build_interface() -> void:
    var title := _make_label("RIFTGUARD", Vector2(28, 22), 32, Color("#e5f4ff"))
    title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 3)

    _make_label("MAZE PROTOTYPE  ·  M1", Vector2(31, 63), 13, Color("#77bed4"))
    _make_label("LMB  Place barricade\nRMB  Remove barricade\nR      Clear maze\nD      Toggle route", Vector2(28, 112), 17, Color("#c5d9e5"))
    _make_label("RIFT", Vector2(627, 90), 14, COLOR_RIFT)
    _make_label("GATE", Vector2(623, 610), 14, COLOR_GATE)

    route_label = _make_label("Route overlay: ON", Vector2(1020, 26), 15, COLOR_ROUTE)
    status_label = _make_label("Shape their descent toward the gate.", Vector2(28, 665), 18, COLOR_ROUTE)

func _make_label(text: String, position: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    return label

func _set_status(text: String, color: Color) -> void:
    status_label.text = text
    status_label.add_theme_color_override("font_color", color)
