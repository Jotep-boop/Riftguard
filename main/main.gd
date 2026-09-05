extends Node2D

const BoardModelScript = preload("res://gameplay/board/board_model.gd")
const CombatModelScript = preload("res://gameplay/combat/combat_model.gd")

const BOARD_SIZE := Vector2i(13, 9)
const START_CELL := Vector2i(0, 4)
const GOAL_CELL := Vector2i(12, 4)
const BOARD_CENTER_X := 650.0
const BOARD_TOP_Y := 110.0
const BOARD_BOTTOM_Y := 610.0
const TOP_CELL_WIDTH := 60.0
const BOTTOM_CELL_WIDTH := 74.0
const BLOCK_HEIGHT := 20.0
const ENEMY_SPEED := 125.0
const ENEMY_ID := "scout"
const ENEMY_MAX_HEALTH := 100.0
const ENEMY_REWARD := 12
const RESPAWN_DELAY := 0.9

const COLOR_FLOOR_A := Color("#26384b")
const COLOR_FLOOR_B := Color("#2b4154")
const COLOR_GRID := Color("#7693a6")
const COLOR_ROUTE := Color("#59d8ee")
const COLOR_VALID := Color("#58e6ad")
const COLOR_INVALID := Color("#ff6b74")
const COLOR_RIFT := Color("#d852ff")
const COLOR_GATE := Color("#ffc85c")
const COLOR_TOWER := Color("#4f92a3")
const COLOR_PROJECTILE := Color("#fff3a8")

var board_model
var combat_model
var hovered_cell := Vector2i(-1, -1)
var show_route := true
var enemy_position := Vector2.ZERO
var enemy_route_index := 0
var enemy_segment_progress := 0.0
var enemy_respawn_timer := 0.0
var hit_flash_timer := 0.0
var death_burst_timer := 0.0
var status_label: Label
var route_label: Label
var gold_label: Label
var enemy_label: Label

func _ready() -> void:
    board_model = BoardModelScript.new(BOARD_SIZE, START_CELL, GOAL_CELL)
    combat_model = CombatModelScript.new()
    _build_interface()
    _spawn_enemy()
    queue_redraw()

func _process(delta: float) -> void:
    hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
    death_burst_timer = maxf(0.0, death_burst_timer - delta)
    if enemy_respawn_timer > 0.0:
        enemy_respawn_timer -= delta
        if enemy_respawn_timer <= 0.0:
            _spawn_enemy()
    elif _enemy_is_alive():
        _advance_enemy(delta)
        combat_model.update_enemy(ENEMY_ID, _enemy_grid_position(), _enemy_route_progress())
    combat_model.advance(delta)
    _handle_combat_events()
    _update_hud()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        hovered_cell = _cell_at_point(event.position)
        queue_redraw()
    elif event is InputEventMouseButton and event.pressed:
        hovered_cell = _cell_at_point(event.position)
        if event.button_index == MOUSE_BUTTON_LEFT:
            _place_hovered_tower()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            _remove_hovered_tower()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            board_model.clear_blockers()
            for cell in combat_model.towers.keys():
                combat_model.remove_tower(cell)
            _set_status("Maze cleared. The rift has a straight shot again.", COLOR_ROUTE)
            _reset_enemy_movement()
        elif event.keycode == KEY_D:
            show_route = not show_route
            route_label.text = "Route overlay: %s" % ("ON" if show_route else "OFF")
        queue_redraw()

func _draw() -> void:
    _draw_board()
    if show_route:
        _draw_route()
    _draw_endpoints()
    _draw_range_preview()
    _draw_towers()
    _draw_hover_preview()
    _draw_projectiles()
    _draw_enemy()

func _draw_board() -> void:
    for depth in range(BOARD_SIZE.y):
        for longitudinal in range(BOARD_SIZE.x):
            var cell := Vector2i(longitudinal, depth)
            var fill := COLOR_FLOOR_A if (longitudinal + depth) % 2 == 0 else COLOR_FLOOR_B
            var tile := _tile_polygon(cell, 1.0)
            draw_colored_polygon(tile, fill)
            draw_polyline(_close_polygon(tile), COLOR_GRID, 1.7, true)

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

func _draw_range_preview() -> void:
    if not combat_model.towers.has(hovered_cell):
        return
    var ring := PackedVector2Array()
    for step in range(49):
        var angle := TAU * float(step) / 48.0
        var point := Vector2(hovered_cell) + Vector2(cos(angle), sin(angle)) * CombatModelScript.TOWER_RANGE
        ring.append(_grid_position_to_world(point))
    draw_colored_polygon(ring, Color(COLOR_ROUTE, 0.055))
    draw_polyline(ring, Color(COLOR_ROUTE, 0.72), 2.0, true)

func _draw_towers() -> void:
    for depth in range(BOARD_SIZE.y):
        for cell in board_model.blocked.keys():
            if cell.y != depth:
                continue
            _draw_prism(cell, COLOR_TOWER, 1.0)
            var turret := _cell_to_world(cell) - Vector2(0.0, BLOCK_HEIGHT + 7.0)
            draw_circle(turret, 8.0, Color("#b7edf3"))
            draw_circle(turret, 4.0, COLOR_PROJECTILE)
            draw_arc(turret, 9.5, 0.0, TAU, 18, Color("#24566a"), 2.0, true)

func _draw_hover_preview() -> void:
    if not _inside_board(hovered_cell) or board_model.blocked.has(hovered_cell):
        return
    var allowed: bool = board_model.can_place_blocker(hovered_cell)
    _draw_prism(hovered_cell, Color(COLOR_VALID if allowed else COLOR_INVALID, 0.62), 0.88)

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

func _draw_projectiles() -> void:
    for projectile in combat_model.projectiles:
        if not combat_model.enemies.has(projectile.target_id):
            continue
        var origin_cell := Vector2i(projectile.origin)
        var origin := _cell_to_world(origin_cell) - Vector2(0.0, BLOCK_HEIGHT + 8.0)
        var target := enemy_position - Vector2(0.0, 17.0)
        var progress: float = 1.0 - projectile.remaining / projectile.duration
        var position := origin.lerp(target, clampf(progress, 0.0, 1.0))
        draw_line(origin, position, Color(COLOR_PROJECTILE, 0.22), 2.0, true)
        draw_circle(position, 5.0, COLOR_PROJECTILE)
        draw_circle(position, 9.0, Color(COLOR_PROJECTILE, 0.16))

func _draw_enemy() -> void:
    if death_burst_timer > 0.0:
        var burst_radius := 18.0 + (0.5 - death_burst_timer) * 45.0
        draw_circle(enemy_position - Vector2(0.0, 17.0), burst_radius, Color(COLOR_RIFT, death_burst_timer * 0.45))
    if not _enemy_is_alive():
        return
    draw_set_transform(enemy_position + Vector2(0.0, 8.0), 0.0, Vector2(1.3, 0.48))
    draw_circle(Vector2.ZERO, 13.0, Color(0.0, 0.0, 0.0, 0.32))
    draw_set_transform(Vector2.ZERO)
    var body := enemy_position - Vector2(0.0, 17.0)
    var body_color := Color.WHITE if hit_flash_timer > 0.0 else Color("#f05fd2")
    draw_circle(body, 12.5, body_color)
    draw_circle(body - Vector2(3.5, 3.5), 4.0, Color("#ffd7f6"))
    draw_arc(body, 14.5, 0.0, TAU, 24, Color("#6f235e"), 2.0, true)
    var enemy: Dictionary = combat_model.enemies[ENEMY_ID]
    var health_ratio: float = enemy.health / enemy.max_health
    var bar_position := body + Vector2(-18.0, -24.0)
    draw_rect(Rect2(bar_position, Vector2(36.0, 5.0)), Color("#321f32"))
    draw_rect(Rect2(bar_position, Vector2(36.0 * health_ratio, 5.0)), COLOR_VALID)

func _place_hovered_tower() -> void:
    if board_model.try_place_blocker(hovered_cell):
        combat_model.add_tower(hovered_cell)
        _set_status("Arc tower placed — tracking targets.", COLOR_VALID)
        _reset_enemy_movement()
    else:
        _set_status("Placement rejected — breach attacks arrive in the next slice.", COLOR_INVALID)
    queue_redraw()

func _remove_hovered_tower() -> void:
    if board_model.remove_blocker(hovered_cell):
        combat_model.remove_tower(hovered_cell)
        _set_status("Arc tower removed.", COLOR_ROUTE)
        _reset_enemy_movement()
        queue_redraw()

func _spawn_enemy() -> void:
    enemy_respawn_timer = 0.0
    _reset_enemy_movement()
    combat_model.add_enemy(ENEMY_ID, _enemy_grid_position(), 0.0, ENEMY_MAX_HEALTH, ENEMY_REWARD)
    _set_status("A rift scout enters the crossing.", COLOR_ROUTE)

func _reset_enemy_movement() -> void:
    enemy_route_index = 0
    enemy_segment_progress = 0.0
    if not board_model.route.is_empty():
        enemy_position = _cell_to_world(board_model.route.front())
    if combat_model != null and combat_model.enemies.has(ENEMY_ID):
        combat_model.update_enemy(ENEMY_ID, _enemy_grid_position(), 0.0)

func _advance_enemy(delta: float) -> void:
    if board_model.route.size() < 2:
        return
    var remaining := ENEMY_SPEED * delta
    while remaining > 0.0:
        var from := _cell_to_world(board_model.route[enemy_route_index])
        var next_index := enemy_route_index + 1
        if next_index >= board_model.route.size():
            _set_status("Scout reached the gate — lives arrive with M3.", COLOR_GATE)
            _spawn_enemy()
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

func _enemy_grid_position() -> Vector2:
    if board_model.route.is_empty():
        return Vector2(START_CELL)
    var current := Vector2(board_model.route[enemy_route_index])
    var next_index := mini(enemy_route_index + 1, board_model.route.size() - 1)
    return current.lerp(Vector2(board_model.route[next_index]), enemy_segment_progress)

func _enemy_route_progress() -> float:
    if board_model.route.size() < 2:
        return 0.0
    return (float(enemy_route_index) + enemy_segment_progress) / float(board_model.route.size() - 1)

func _enemy_is_alive() -> bool:
    return combat_model != null and combat_model.enemies.has(ENEMY_ID) and combat_model.enemies[ENEMY_ID].alive

func _handle_combat_events() -> void:
    for event in combat_model.consume_events():
        if event.type == "hit":
            hit_flash_timer = 0.12
        elif event.type == "death":
            death_burst_timer = 0.5
            enemy_respawn_timer = RESPAWN_DELAY
            _set_status("Rift scout shattered. +%d gold." % event.reward, COLOR_GATE)

func _update_hud() -> void:
    gold_label.text = "Gold  %d" % combat_model.gold
    if _enemy_is_alive():
        var enemy: Dictionary = combat_model.enemies[ENEMY_ID]
        enemy_label.text = "Scout  %d / %d HP" % [ceili(enemy.health), ceili(enemy.max_health)]
    else:
        enemy_label.text = "Scout  respawning..."

func _cell_to_world(cell: Vector2i) -> Vector2:
    return _grid_position_to_world(Vector2(cell))

func _grid_position_to_world(position: Vector2) -> Vector2:
    var depth_ratio := (position.y + 0.5) / BOARD_SIZE.y
    var row_width := lerpf(TOP_CELL_WIDTH, BOTTOM_CELL_WIDTH, depth_ratio)
    return Vector2(
        BOARD_CENTER_X + (position.x + 0.5 - BOARD_SIZE.x * 0.5) * row_width,
        lerpf(BOARD_TOP_Y, BOARD_BOTTOM_Y, depth_ratio)
    )

func _cell_at_point(point: Vector2) -> Vector2i:
    for depth in range(BOARD_SIZE.y):
        for longitudinal in range(BOARD_SIZE.x):
            var cell := Vector2i(longitudinal, depth)
            if Geometry2D.is_point_in_polygon(point, _tile_polygon(cell, 1.0)):
                return cell
    return Vector2i(-1, -1)

func _inside_board(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < BOARD_SIZE.x and cell.y < BOARD_SIZE.y

func _tile_polygon(cell: Vector2i, scale_factor: float) -> PackedVector2Array:
    var corners := PackedVector2Array([
        _grid_point(cell.x, cell.y),
        _grid_point(cell.x + 1, cell.y),
        _grid_point(cell.x + 1, cell.y + 1),
        _grid_point(cell.x, cell.y + 1),
    ])
    return _scaled_polygon(corners, _polygon_center(corners), scale_factor)

func _grid_point(longitudinal_boundary: int, depth_boundary: int) -> Vector2:
    var depth_ratio := float(depth_boundary) / BOARD_SIZE.y
    var row_width := lerpf(TOP_CELL_WIDTH, BOTTOM_CELL_WIDTH, depth_ratio)
    return Vector2(
        BOARD_CENTER_X + (longitudinal_boundary - BOARD_SIZE.x * 0.5) * row_width,
        lerpf(BOARD_TOP_Y, BOARD_BOTTOM_Y, depth_ratio)
    )

func _polygon_center(points: PackedVector2Array) -> Vector2:
    var center := Vector2.ZERO
    for point in points:
        center += point
    return center / points.size()

func _scaled_polygon(points: PackedVector2Array, center: Vector2, scale_factor: float) -> PackedVector2Array:
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

    _make_label("COMBAT SLICE  ·  M2", Vector2(31, 63), 13, Color("#77bed4"))
    _make_label("LMB  Place arc tower\nRMB  Remove tower\nR      Clear maze\nD      Toggle route", Vector2(28, 112), 17, Color("#c5d9e5"))
    _make_label("RIFT", Vector2(220, 340), 14, COLOR_RIFT)
    _make_label("GATE", Vector2(1058, 340), 14, COLOR_GATE)

    route_label = _make_label("Route overlay: ON", Vector2(1020, 26), 15, COLOR_ROUTE)
    gold_label = _make_label("Gold  0", Vector2(1030, 58), 20, COLOR_GATE)
    enemy_label = _make_label("Scout  100 / 100 HP", Vector2(1000, 88), 16, Color("#ffd7f6"))
    status_label = _make_label("Build an arc tower and let it hunt.", Vector2(28, 665), 18, COLOR_ROUTE)

func _make_label(text: String, position: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    return label

func _set_status(text: String, color: Color) -> void:
    if status_label == null:
        return
    status_label.text = text
    status_label.add_theme_color_override("font_color", color)
