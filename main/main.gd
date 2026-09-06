extends Node2D
const Match = preload("res://gameplay/match/match_model.gd")
const Combat = preload("res://gameplay/combat/combat_model.gd")
const BOARD_SIZE := Vector2i(13, 9)
const BOARD_CENTER_X := 650.0
const BOARD_TOP_Y := 140.0
const BOARD_BOTTOM_Y := 610.0
const TOP_CELL_WIDTH := 60.0
const BOTTOM_CELL_WIDTH := 74.0
const BLOCK_HEIGHT := 20.0
const COLORS := {"arc": Color("72e9cd"), "nova": Color("ffb566"), "frost": Color("8abfff")}
var match_model = Match.new()
var board_model
var combat_model
var hovered_cell := Vector2i(-1, -1)
var selected_cell := Vector2i(-1, -1)
var selected_role := "arc"
var show_route := true
var paused := false
var speed := 1.0
var accumulator := 0.0
var clock := 0.0
var effects: Array[Dictionary] = []
var role_buttons: Array[Button] = []
var stats_label: Label
var info_label: Label
var status_label: Label
var phase_label: Label
var start_button: Button
var upgrade_button: Button
var sell_button: Button
var overlay: Panel
var outcome_label: Label
var audio_players: Array[AudioStreamPlayer] = []
var tones: Dictionary = {}
var muted := false
var preview_label: Label
var branch_panel: Panel
var branch_buttons: Array[Button] = []
var results_label: Label
const BRANCH_TEXT := {
    "lance": "LANCE / 35
Focused damage · shots land in 0.09s",
    "chain": "CHAIN / 35
60% damage · jumps once within 1.8",
    "blast": "BLAST / 35
Full damage · compact 1.3 splash",
    "wide": "WIDE / 35
70% damage · wide 2.2 splash",
    "deep": "DEEP / 35
Single target · 50% slow for 3.2s",
    "field": "COLDFRONT / 35
1.3 splash · 50% slow for 1.6s",
}

func _ready() -> void:
    board_model = match_model.board
    combat_model = match_model.combat
    _build_interface()
    _build_audio()
    _update_hud()

func _process(delta: float) -> void:
    clock += delta
    if not paused:
        accumulator += minf(delta, 0.2) * speed
        while accumulator >= 1.0 / 60.0:
            match_model.advance(1.0 / 60.0)
            accumulator -= 1.0 / 60.0
    for event in match_model.consume_events():
        if event.type in ["hit", "death", "leak"]:
            effects.append({"position": event.position, "life": 0.45, "type": event.type})
        elif event.type == "tower_destroyed":
            effects.append({"position": Vector2(event.tower_cell), "life": 0.45, "type": "leak"})
            _status("Tower breached! The swarm has opened a new route.")
        elif event.type == "build":
            _status("Wave cleared. +30 salvage. Rebuild, upgrade, then launch the next wave.")
        if event.type in tones:
            _sound(event.type)
    for effect in effects:
        effect.life -= delta
    effects = effects.filter(func(e: Dictionary) -> bool: return e.life > 0)
    _update_hud()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        hovered_cell = _cell_at_point(event.position)
    elif event is InputEventMouseButton and event.pressed:
        hovered_cell = _cell_at_point(event.position)
        if event.button_index == MOUSE_BUTTON_LEFT:
            _place_hovered_tower()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            selected_cell = hovered_cell
            _sell()
    elif event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1: _select_role("arc")
            KEY_2: _select_role("nova")
            KEY_3: _select_role("frost")
            KEY_SPACE: _start_wave()
            KEY_U: _upgrade()
            KEY_Q: _choose_branch(0)
            KEY_E: _choose_branch(1)
            KEY_ESCAPE: branch_panel.hide()
            KEY_X: _sell()
            KEY_D: show_route = not show_route
            KEY_P: paused = not paused
            KEY_F: speed = 2.0 if speed == 1 else 1.0
            KEY_M: muted = not muted
            KEY_R: _restart()

func _place_hovered_tower() -> void:
    branch_panel.hide()
    if combat_model.towers.has(hovered_cell):
        selected_cell = hovered_cell
    elif match_model.place(hovered_cell, selected_role):
        selected_cell = hovered_cell
        _status("%s deployed. Seal routes at your own risk: enemies attack blocking towers." % selected_role.capitalize())
        _sound("build")
    else:
        _status("Cannot build: check salvage, occupied cells, rift and gate.")

func _select_role(role: String) -> void:
    branch_panel.hide()
    selected_role = role
    selected_cell = Vector2i(-1, -1)

func _upgrade() -> void:
    if combat_model.towers.has(selected_cell) and combat_model.towers[selected_cell].level == 1:
        branch_panel.visible = not branch_panel.visible
        _update_hud()
    elif match_model.upgrade(selected_cell):
        _status("Branch reinforced and repaired. Range unchanged; maximum level 3.")
        _sound("build")
    else:
        _status("Select a tower. Choose a branch for 35, then reinforce for 70.")

func _choose_branch(index: int) -> void:
    if not branch_panel.visible or not combat_model.towers.has(selected_cell):
        return
    var role: String = combat_model.towers[selected_cell].role
    if match_model.choose_upgrade(selected_cell, Match.BRANCHES[role][index]):
        branch_panel.hide()
        _status("Branch locked in and tower repaired. U reinforces this choice; sell to rebuild differently.")
        _sound("build")
    _update_hud()

func _sell() -> void:
    branch_panel.hide()
    if match_model.sell(selected_cell):
        _status("Tower sold for 70% of its total investment.")
        selected_cell = Vector2i(-1, -1)
        _sound("build")

func _start_wave() -> void:
    branch_panel.hide()
    if match_model.start_wave():
        paused = false
        _status("Defend the gate. You can build, upgrade and sell during the wave.")

func _restart() -> void:
    branch_panel.hide()
    match_model.restart()
    board_model = match_model.board
    combat_model = match_model.combat
    selected_cell = Vector2i(-1, -1)
    effects.clear()
    paused = false
    speed = 1
    accumulator = 0
    _status("New defense. Build near the route, combine tower roles, then press SPACE.")
    _update_hud()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("101925"))
    draw_rect(Rect2(0, 0, 1280, 98), Color("192938"))
    draw_rect(Rect2(0, 622, 1280, 98), Color("192938"))
    for y in range(BOARD_SIZE.y):
        for x in range(BOARD_SIZE.x):
            var tile := _tile_polygon(Vector2i(x, y), 0.97)
            draw_colored_polygon(tile, Color("293e50") if (x+y)%2 else Color("26394b"))
            draw_polyline(_close_polygon(tile), Color("587284"), 1.0, true)
    if show_route:
        var route := PackedVector2Array()
        for cell in board_model.active_route():
            route.append(_cell_to_world(cell))
        if route.size() > 1:
            draw_polyline(route, Color(0.35, 0.85, 0.88, 0.4), 4, true)
    for endpoint in [board_model.start, board_model.goal]:
        var pos := _cell_to_world(endpoint)
        var color := Color("d77cfa") if endpoint == board_model.start else Color("ffd07c")
        draw_circle(pos, 27, Color(color, 0.12))
        draw_arc(pos, 20 + sin(clock * 2) * 2, 0, TAU, 40, color, 3, true)
        draw_arc(pos, 13, clock, clock + PI * 1.5, 32, color, 2, true)
    var focus := hovered_cell if _inside_board(hovered_cell) else selected_cell
    if _inside_board(focus):
        var role: String = combat_model.towers[focus].role if combat_model.towers.has(focus) else selected_role
        var ring := PackedVector2Array()
        for step in range(65):
            var angle := TAU * step / 64.0
            ring.append(_grid_position_to_world(Vector2(focus) + Vector2(cos(angle), sin(angle)) * Combat.ROLES[role].range))
        draw_colored_polygon(ring, Color(COLORS[role], 0.05))
        draw_polyline(ring, Color(COLORS[role], 0.55), 2, true)
    # Row-based painter order keeps creatures and towers readable in dense mazes.
    for y in range(BOARD_SIZE.y):
        for cell in combat_model.towers:
            if cell.y != y:
                continue
            var tower: Dictionary = combat_model.towers[cell]
            var color: Color = COLORS[tower.role]
            _draw_prism(cell, color.darkened(0.35), 0.82)
            var pos := _cell_to_world(cell) - Vector2(0, 27)
            if tower.role == "arc":
                draw_line(pos + Vector2(-7, 3), pos + Vector2(7, -7), color, 6, true)
            elif tower.role == "nova":
                draw_circle(pos, 10, color)
                draw_circle(pos, 5, Color("293040"))
            else:
                draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-13),pos+Vector2(9,0),pos+Vector2(0,10),pos+Vector2(-9,0)]),color)
            if tower.branch != "":
                var mark: String = "COLD" if tower.branch == "field" else tower.branch.to_upper()
                draw_string(ThemeDB.fallback_font, pos + Vector2(-17, -16), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
            for level in range(tower.level):
                draw_circle(pos + Vector2(-8 + level * 8, 15), 2, Color.WHITE)
            if cell == selected_cell:
                draw_polyline(_close_polygon(_tile_polygon(cell, 0.9)), Color.WHITE, 2, true)
            if tower.health < tower.max_health:
                _health_bar(pos + Vector2(-17, -22), tower.health / tower.max_health, Color("ff986e"))
        for enemy in combat_model.enemies.values():
            if clampi(roundi(enemy.position.y), 0, 8) == y:
                _draw_creature(enemy)
    if _inside_board(hovered_cell) and not combat_model.towers.has(hovered_cell):
        _draw_prism(hovered_cell, Color(Color("72e9cd") if match_model.can_place(hovered_cell, selected_role) else Color("ff6d85"), 0.45), 0.82)
    for shot in combat_model.projectiles:
        if not combat_model.enemies.has(shot.target_id):
            continue
        var from := _grid_position_to_world(shot.origin) - Vector2(0, 27)
        var to := _grid_position_to_world(combat_model.enemies[shot.target_id].position) - Vector2(0, 15)
        var pos := from.lerp(to, 1 - shot.remaining / shot.duration)
        draw_line(from, pos, Color(COLORS[shot.role], 0.35), 2, true)
        draw_circle(pos, 5, COLORS[shot.role])
    for effect in effects:
        var pos := _grid_position_to_world(effect.position) - Vector2(0, 15)
        var color := Color("ffb566") if effect.type == "leak" else Color("e5b4fa")
        var radius: float = (1 - effect.life / 0.45) * (32 if effect.type == "death" else 18)
        draw_arc(pos, maxf(1, radius), 0, TAU, 24, Color(color, effect.life / 0.45), 2, true)
        if effect.type == "death":
            for n in range(6):
                var angle := n * TAU / 6
                draw_circle(pos + Vector2(cos(angle), sin(angle)) * radius, 3, Color(color, effect.life / 0.45))

func _draw_creature(enemy: Dictionary) -> void:
    var pos := _grid_position_to_world(enemy.position)
    draw_set_transform(pos + Vector2(0, 5), 0, Vector2(1.4, 0.45))
    draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.3))
    draw_set_transform(Vector2.ZERO)
    pos.y -= 16 + sin(clock * 8 + enemy.travelled) * 2
    var color := Color("df80e7")
    if enemy.kind == "warden":
        color = Color("ffce78")
        draw_colored_polygon(PackedVector2Array([pos+Vector2(-24,-10),pos+Vector2(-15,-27),pos+Vector2(0,-16),pos+Vector2(15,-27),pos+Vector2(24,-10),pos+Vector2(16,19),pos+Vector2(-16,19)]), color)
        draw_circle(pos, 12, Color("713b75"))
        draw_arc(pos, 31, clock, clock + TAU * 0.8, 40, color, 2, true)
        draw_string(ThemeDB.fallback_font, pos + Vector2(-26, -42), "WARDEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
    elif enemy.kind == "brute":
        color = Color("f18786")
        draw_colored_polygon(PackedVector2Array([pos+Vector2(-14,-10),pos+Vector2(8,-15),pos+Vector2(16,5),pos+Vector2(0,14),pos+Vector2(-14,8)]),color)
    elif enemy.kind == "runner":
        color = Color("f5d083")
        draw_colored_polygon(PackedVector2Array([pos+Vector2(-12,-9),pos+Vector2(15,0),pos+Vector2(-12,9),pos+Vector2(-5,0)]),color)
    else:
        draw_circle(pos, 11, color)
        draw_arc(pos, 14, 0, TAU, 24, color.darkened(0.4), 2, true)
    draw_circle(pos + Vector2(5, -3), 3, Color("fff5e7"))
    if enemy.slow_timer > 0:
        draw_arc(pos, 18, 0, TAU, 24, COLORS.frost, 2, true)
    _health_bar(pos + Vector2(-17, -25), enemy.health / enemy.max_health, color)
    if enemy.breach_target != Vector2i(-1, -1) and enemy.position.distance_to(Vector2(enemy.breach_target)) <= 1.01:
        draw_line(pos, _cell_to_world(enemy.breach_target) - Vector2(0, 25), Color(1, 0.5, 0.3, 0.5), 2, true)

func _health_bar(pos: Vector2, ratio: float, color: Color) -> void:
    draw_rect(Rect2(pos, Vector2(34, 4)), Color("101925"))
    draw_rect(Rect2(pos, Vector2(34 * ratio, 4)), color)

func _build_interface() -> void:
    _label("RIFTGUARD", Vector2(24, 13), 29, Color("edf6ff"))
    _label("THE LAST CROSSING  /  MAZE DEFENSE", Vector2(26, 50), 11, Color("91adbf"))
    stats_label = _label("", Vector2(350, 18), 22, Color("ffd07c"))
    phase_label = _label("", Vector2(350, 52), 14, Color("afc6d7"))
    start_button = _button("SPACE  /  Launch wave", Vector2(995, 20), Vector2(260, 48), _start_wave)
    var titles := ["1  ARC  /  45", "2  NOVA  /  65", "3  FROST  /  55"]
    var roles := ["arc", "nova", "frost"]
    for i in range(3):
        var button := _button(titles[i], Vector2(24 + i * 183, 631), Vector2(174, 38), _select_role.bind(roles[i]))
        button.modulate = COLORS[roles[i]]
        role_buttons.append(button)
    upgrade_button = _button("U  Upgrade", Vector2(582, 631), Vector2(185, 38), _upgrade)
    sell_button = _button("X  Sell", Vector2(779, 631), Vector2(155, 38), _sell)
    _button("P  Pause", Vector2(946, 631), Vector2(145, 38), func(): paused = not paused)
    _button("F  Speed", Vector2(1103, 631), Vector2(150, 38), func(): speed = 2.0 if speed == 1 else 1.0)
    info_label = _label("", Vector2(24, 674), 13, Color("c5d9e5"))
    status_label = _label("Build near the route. Combine tower roles, then launch the first wave.", Vector2(24, 699), 12, Color("a4c7d8"))
    preview_label = _label("", Vector2(24, 78), 12, Color("d4c5e8"))
    branch_panel = Panel.new()
    branch_panel.position = Vector2(320, 463)
    branch_panel.size = Vector2(640, 150)
    add_child(branch_panel)
    var choice_title := _label("CHOOSE ONCE  /  Both repair +35 HP  /  Range unchanged  /  ESC cancel", Vector2.ZERO, 13, Color("edf6ff"))
    choice_title.reparent(branch_panel)
    choice_title.position = Vector2(16, 12)
    for i in range(2):
        var choice := _button("", Vector2.ZERO, Vector2(298, 89), _choose_branch.bind(i))
        choice.reparent(branch_panel)
        choice.position = Vector2(16 + i * 312, 43)
        choice.add_theme_font_size_override("font_size", 13)
        branch_buttons.append(choice)
    branch_panel.hide()
    _label("RIFT", Vector2(205, 386), 12, Color("d77cfa"))
    _label("GATE", Vector2(1060, 386), 12, Color("ffd07c"))
    overlay = Panel.new()
    overlay.position = Vector2(325, 160)
    overlay.size = Vector2(630, 450)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("172a3a")
    panel_style.border_color = Color("72e9cd")
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(10)
    overlay.add_theme_stylebox_override("panel", panel_style)
    branch_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
    add_child(overlay)
    outcome_label = Label.new()
    outcome_label.position = Vector2(25, 22)
    outcome_label.add_theme_font_size_override("font_size", 23)
    overlay.add_child(outcome_label)
    results_label = Label.new()
    results_label.position = Vector2(25, 100)
    results_label.add_theme_font_size_override("font_size", 16)
    overlay.add_child(results_label)
    var restart := Button.new()
    restart.text = "R  /  Defend again"
    restart.position = Vector2(195, 382)
    restart.size = Vector2(240, 48)
    restart.pressed.connect(_restart)
    overlay.add_child(restart)

func _label(text: String, pos: Vector2, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.position = pos
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    return label

func _button(text: String, pos: Vector2, size: Vector2, action: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.position = pos
    button.size = size
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 15)
    for state in ["normal", "hover", "pressed", "disabled"]:
        var style := StyleBoxFlat.new()
        style.bg_color = Color("233d50") if state == "normal" else Color("35566c")
        if state == "disabled":
            style.bg_color = Color("1a2936")
        style.border_color = Color("547c92")
        style.set_border_width_all(1)
        style.set_corner_radius_all(5)
        button.add_theme_stylebox_override(state, style)
    button.add_theme_color_override("font_color", Color("edf6ff"))
    button.add_theme_color_override("font_disabled_color", Color("6e8799"))
    button.pressed.connect(action)
    add_child(button)
    return button

func _status(text: String) -> void:
    status_label.text = text

func _update_hud() -> void:
    stats_label.text = "SALVAGE  %d     GATE  %d / 12     WAVE  %d / 6" % [combat_model.gold, match_model.lives, match_model.wave]
    phase_label.text = "%s  |  %d active  /  %d incoming  |  %dx%s" % [match_model.phase.to_upper(), combat_model.enemies.size(), match_model.pending.size(), int(speed), "  PAUSED" if paused else ""]
    start_button.disabled = match_model.phase != "build"
    start_button.text = "SPACE  /  Launch wave %d" % mini(6, match_model.wave + 1)
    for i in range(3):
        role_buttons[i].text = (["1  ARC  /  45", "2  NOVA  /  65", "3  FROST  /  55"][i]) + ("  ◀" if ["arc", "nova", "frost"][i] == selected_role else "")
    var selected: bool = combat_model.towers.has(selected_cell)
    upgrade_button.disabled = not selected
    if not selected or match_model.phase in ["won", "lost"]:
        branch_panel.hide()
    sell_button.disabled = not selected
    if selected:
        var tower: Dictionary = combat_model.towers[selected_cell]
        info_label.text = "%s %s L%d | HP %d/%d | Range %.1f | LMB select · RMB sell · D route · M mute · R restart" % [tower.role.to_upper(), tower.branch.to_upper(), tower.level, tower.health, tower.max_health, Combat.ROLES[tower.role].range]
        upgrade_button.text = "MAX LEVEL" if tower.level == 3 else ("U  Choose / 35" if tower.level == 1 else "U  Reinforce / 70")
        for i in range(2):
            branch_buttons[i].text = ("Q  " if i == 0 else "E  ") + BRANCH_TEXT[Match.BRANCHES[tower.role][i]]
            branch_buttons[i].disabled = combat_model.gold < 35 or tower.level != 1
        upgrade_button.disabled = tower.level == 3 or combat_model.gold < match_model.upgrade_cost(selected_cell)
        sell_button.text = "X  Sell / %d" % match_model.sell_value(selected_cell)
    else:
        info_label.text = "ARC: focused damage  |  NOVA: splash radius 1.3  |  FROST: 50% slow  |  D route · M mute · R restart"
        upgrade_button.text = "U  Upgrade"
        sell_button.text = "X  Sell"
    overlay.visible = match_model.phase in ["won", "lost"]
    if overlay.visible:
        upgrade_button.disabled = true
        sell_button.disabled = true
    var preview: Dictionary = match_model.wave_preview(match_model.wave - 1 if match_model.phase != "build" else -1)
    var parts: PackedStringArray = []
    for kind in preview.composition:
        parts.append("%d %s" % [preview.composition[kind], kind.capitalize()])
    preview_label.text = "%s  /  %s  /  %.2fs spacing\n%s" % [preview.name, " + ".join(parts), preview.interval, preview.hint]
    outcome_label.text = "%s\n%d shattered · %d escaped · Gate %d/12" % ["CROSSING SECURED" if match_model.phase == "won" else "THE GATE HAS FALLEN", match_model.kills, match_model.leaked, match_model.lives]
    if overlay.visible:
        var report: Dictionary = match_model.results()
        results_label.text = "Combat time %.1fs  |  Towers breached %d\nSpent %d · Refunded %d · Salvage left %d\nDamage dealt: Arc %.0f · Nova %.0f · Frost %.0f\n" % [report.combat_seconds, report.towers_lost, report.spent, report.refunded, report.salvage, report.damage.arc, report.damage.nova, report.damage.frost]
        for record in report.waves:
            results_label.text += "Wave %d: %d shattered / %d escaped / %.1fs%s\n" % [record.wave, record.kills, record.escaped, record.seconds, "" if record.cleared else " / gate fell"]
        results_label.text += "Replay: try the other branches against the same authored waves."

func _build_audio() -> void:
    # Original synthesized mono PCM cues; no external assets or dependencies.
    var frequencies := {"shot": 620.0, "death": 210.0, "build": 440.0, "wave": 330.0, "leak": 110.0, "won": 880.0, "lost": 90.0}
    for kind in frequencies:
        var data := PackedByteArray()
        var count := 2205 if kind == "shot" else 6615
        for i in range(count):
            var t := float(i) / 22050.0
            var envelope := pow(1.0 - float(i) / count, 2)
            var sample := int(sin(TAU * frequencies[kind] * t * (1.0 - t)) * envelope * 6500)
            data.append(sample & 255)
            data.append((sample >> 8) & 255)
        var stream := AudioStreamWAV.new()
        stream.format = AudioStreamWAV.FORMAT_16_BITS
        stream.mix_rate = 22050
        stream.data = data
        tones[kind] = stream
    for i in range(8):
        var player := AudioStreamPlayer.new()
        player.volume_db = -15
        add_child(player)
        audio_players.append(player)

func _sound(kind: String) -> void:
    if muted:
        return
    for player in audio_players:
        if not player.playing:
            player.stream = tones[kind]
            player.play()
            return

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
