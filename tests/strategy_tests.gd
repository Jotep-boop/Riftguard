extends SceneTree
const Match = preload("res://gameplay/match/match_model.gd")
var failures := 0
var assertions := 0
func check(ok: bool, message: String) -> void:
    assertions += 1
    if not ok:
        failures += 1
        push_error(message)
func test_branch_impacts() -> void:
    for spec in [["arc", "lance"], ["arc", "chain"], ["nova", "blast"], ["nova", "wide"], ["frost", "deep"], ["frost", "field"]]:
        var game = Match.new()
        var cell := Vector2i(3, 3)
        game.place(cell, spec[0])
        game.choose_upgrade(cell, spec[1])
        game.combat.add_enemy("target", Vector2(3, 4), 3, 500, 5)
        game.combat.add_enemy("near", Vector2(3, 4.5), 2, 500, 5)
        game.combat.add_enemy("edge", Vector2(3, 6), 1, 500, 5)
        game.combat.advance(0)
        game.combat.advance(0.09)
        if spec[1] == "lance":
            check(game.combat.enemies.target.health < 500, "Lance halves projectile travel time")
            check(game.combat.enemies.near.health == 500, "Lance remains focused single target")
        game.combat.advance(0.09)
        if spec[1] == "chain":
            check(game.combat.enemies.near.health < 500 and game.combat.enemies.edge.health == 500, "Chain jumps once within 1.8 cells, not unlimited splash")
            check(is_equal_approx(game.combat.enemies.target.health, 475.25), "Chain trades focused damage for second hit")
        if spec[1] == "blast":
            check(game.combat.enemies.near.health < 500 and game.combat.enemies.edge.health == 500, "Blast retains compact full-damage splash")
        if spec[1] == "wide":
            check(game.combat.enemies.edge.health < 500, "Wide hits out to 2.2 cells")
            check(is_equal_approx(game.combat.enemies.target.health, 476.9), "Wide trades impact damage for coverage")
        if spec[1] == "deep":
            check(game.combat.enemies.target.slow_timer > 3 and game.combat.enemies.near.slow_timer == 0, "Deep doubles focused slow duration")
        if spec[1] == "field":
            check(game.combat.enemies.near.slow_timer > 0 and game.combat.enemies.edge.slow_timer == 0, "Field slows a finite cluster")

func test_wave_contract() -> void:
    var game = Match.new()
    check(game.has_method("wave_preview"), "authored tactical wave preview exists")
    if not game.has_method("wave_preview"):
        return
    var intervals := {}
    for index in range(6):
        var preview: Dictionary = game.wave_preview(index)
        check(preview.count == Match.WAVES[index].size() and not preview.hint.is_empty(), "preview agrees with actual wave and teaches response")
        intervals[preview.interval] = true
    check(intervals.size() >= 3, "waves vary spacing, not only health")
    check(Match.WAVES[5].count("warden") == 1, "final wave has exactly one Warden")
    game.wave = 5
    game.start_wave()
    game.advance(0.01)
    check(game.pending.size() == Match.WAVES[5].size() - 1, "authored wave really spawns")
    game.restart()
    var id: String = game.spawn_enemy("warden")
    var enemy: Dictionary = game.combat.enemies[id]
    enemy.slow_timer = 3
    game._move(id, 1)
    check(is_equal_approx(enemy.travelled, enemy.speed * 0.75), "Warden resists half of Frost slowdown without immunity")
    enemy.cell = game.board.goal
    enemy.path = [game.board.goal]
    enemy.segment = 0
    enemy.nav_revision = game.revision
    game._move(id, 0.1)
    check(game.lives == 8 and game.leaked == 1, "Warden escape costs four gate lives, counts one escape")
    game._move(id, 0.1)
    check(game.lives == 8, "dead Warden cannot leak twice")

func test_measured_results() -> void:
    var game = Match.new()
    check(game.has_method("results"), "measured match results exist")
    if not game.has_method("results"):
        return
    game.place(Vector2i(3, 3), "arc")
    game.start_wave()
    for tick in range(12000):
        game.advance(1.0 / 60)
        game.consume_events()
        if game.phase != "wave":
            break
    var report: Dictionary = game.results()
    check(report.waves.size() == 1 and report.waves[0].kills == game.kills and report.waves[0].escaped == game.leaked, "wave ledger uses actual deaths and escapes")
    check(report.damage.arc > 0 and report.damage.nova == 0 and report.damage.frost == 0, "damage attributed to actual firing role")
    check(report.damage.arc <= 450, "damage cannot exceed total spawned health")
    var combat = load("res://gameplay/combat/combat_model.gd").new()
    combat.add_tower(Vector2i.ZERO)
    combat.add_enemy("fragile", Vector2(1, 0), 1, 5, 10)
    combat.advance(0)
    combat.advance(0.18)
    for event in combat.consume_events():
        if event.type == "hit":
            check(event.damage == 5, "impact damage event excludes overkill")
    check(report.combat_seconds > 0 and report.spent == 45, "results track combat time and real spending")
    report.waves.clear()
    check(game.results().waves.size() == 1, "result snapshots cannot mutate ledger")
    game.restart()
    check(game.results().waves.is_empty() and game.results().damage.arc == 0 and game.results().combat_seconds == 0 and game.results().spent == 0, "restart resets statistics")

func test_full_replays() -> void:
    for alternate in [false, true]:
        var game = Match.new()
        for spec in [[Vector2i(3, 3), "arc"], [Vector2i(5, 5), "nova"], [Vector2i(5, 3), "frost"], [Vector2i(7, 3), "arc"]]:
            check(game.place(spec[0], spec[1]), "real-budget replay starting defense")
        var peak := 0
        for index in range(6):
            check(game.start_wave(), "replay wave launch")
            for tick in range(18000):
                game.advance(1.0 / 60)
                game.consume_events()
                peak = maxi(peak, game.combat.enemies.size())
                check(game.combat.gold >= 0, "replay never borrows salvage")
                if game.phase != "wave":
                    break
            print("Replay %s wave %d: %s lives=%d gold=%d kills=%d escapes=%d" % ["alternate" if alternate else "primary", game.wave, game.phase, game.lives, game.combat.gold, game.kills, game.leaked])
            if game.phase in ["lost", "won"]:
                break
            for cell in game.combat.towers.keys():
                var tower: Dictionary = game.combat.towers[cell]
                if tower.level == 1:
                    game.choose_upgrade(cell, Match.BRANCHES[tower.role][1 if alternate else 0])
                else:
                    game.upgrade(cell)
            for spec in [[Vector2i(8, 5), "arc"], [Vector2i(9, 3), "nova"], [Vector2i(7, 5), "frost"]]:
                game.place(spec[0], spec[1])
        check(game.phase == "won" and game.wave_records.size() == 6 and peak > 1, "both branch sets complete concurrent full matches")
        var report: Dictionary = game.results()
        var counted_kills := 0
        var counted_escapes := 0
        for record in report.waves:
            counted_kills += record.kills
            counted_escapes += record.escaped
        check(counted_kills == game.kills and counted_escapes == game.leaked, "full ledger reconciles to match totals")
        game.advance(20)
        check(game.results() == report, "terminal results immutable over additional simulation")
        print("REPLAY_RESULT ", JSON.stringify({"alternate": alternate, "peak": peak, "results": report}))
        check(not game.choose_upgrade(Vector2i(3, 3), "chain") and not game.sell(Vector2i(3, 3)), "terminal upgrades and refunds blocked")
        game.restart()
        check(game.results().waves.is_empty() and game.combat.gold == 240 and game.lives == 12 and game.combat.projectiles.is_empty(), "win restart clears economy and pending shots")
    var loss = Match.new()
    for index in range(6):
        if loss.phase != "build":
            break
        loss.start_wave()
        for tick in range(18000):
            loss.advance(1.0 / 60)
            loss.consume_events()
            if loss.phase != "wave":
                break
    check(loss.phase == "lost" and not loss.wave_records[-1].cleared, "loss records partial last wave honestly")
    print("LOSS_RESULT ", JSON.stringify(loss.results()))
    loss.restart()
    check(loss.results().damage.arc == 0 and loss.wave == 0 and loss.phase == "build", "loss retry is fresh")

func test_branch_safety() -> void:
    var game = Match.new()
    var cell := Vector2i(3, 3)
    game.place(cell, "arc")
    game.combat.gold = 34
    check(not game.choose_upgrade(cell, "chain") and game.combat.towers[cell].branch == "" and game.combat.gold == 34, "unaffordable branch never locks or charges")
    game.combat.gold = 35
    game.choose_upgrade(cell, "chain")
    game.combat.add_enemy("a", Vector2(3, 4), 3, 20, 7)
    game.combat.add_enemy("b", Vector2(3, 4.5), 2, 20, 7)
    game.combat.add_enemy("c", Vector2(3, 4.8), 1, 20, 7)
    game.combat.advance(0)
    game.combat.set_enemy_breach_target("a", cell)
    game.combat.advance(0.18)
    check(not game.combat.enemies.a.alive and not game.combat.enemies.b.alive and game.combat.enemies.c.alive, "Chain remains targetable during breach and hits only one neighbor")
    game.combat.remove_tower(cell)
    game.combat.advance(2)
    check(game.combat.gold == 14, "Chain kills pay exactly once, dead enemies stop demolition")
    game = Match.new()
    game.place(cell, "frost")
    game.choose_upgrade(cell, "field")
    game.combat.add_enemy("a", Vector2(3, 4), 3, 100, 5)
    game.combat.add_enemy("b", Vector2(3, 4.5), 2, 100, 5)
    game.combat.advance(0)
    game.combat.enemies.a.alive = false
    game.combat.advance(0.18)
    check(game.combat.enemies.b.health == 100 and game.combat.enemies.b.slow_timer == 0, "Coldfront fizzles when primary target dies before impact")

    var siege = Match.new()
    siege.place(Vector2i(1, 4), "arc")
    var warden: String = siege.spawn_enemy("warden")
    siege.combat.set_enemy_breach_target(warden, Vector2i(1, 4))
    siege.combat.advance(0)
    check(siege.combat.towers[Vector2i(1, 4)].health == 50, "Warden deals its advertised 50 breach damage")
    check(siege.combat.projectiles.size() == 1, "Warden remains an ordinary target during demolition")
    siege.combat.enemies[warden].health = 1
    siege.combat.advance(0.18)
    check(not siege.combat.enemies[warden].alive and siege.combat.gold == 275, "Warden impact kill pays actual 80 reward")
    siege.combat.advance(2)
    check(siege.combat.gold == 275 and siege.combat.towers[Vector2i(1, 4)].health == 50, "dead Warden cannot attack or reward again")
    var old_spent: int = siege.spent
    var refund: int = siege.sell_value(Vector2i(1, 4))
    siege.sell(Vector2i(1, 4))
    check(siege.results().refunded == refund and siege.results().spent == old_spent, "selling records refund separately from gross spending")

func _initialize() -> void:
    test_full_replays()
    test_branch_safety()
    test_measured_results()
    test_branch_impacts()
    test_wave_contract()
    var game = Match.new()
    var cell := Vector2i(3, 3)
    game.place(cell, "arc")
    check(game.has_method("choose_upgrade"), "explicit mutually exclusive upgrade branches exist")
    if game.has_method("choose_upgrade"):
        var before: int = game.combat.gold
        check(not game.choose_upgrade(cell, "invalid") and game.combat.gold == before, "invalid branch is free")
        game.combat.towers[cell].health = 1
        check(game.choose_upgrade(cell, "chain"), "buy Chain branch")
        check(game.combat.towers[cell].branch == "chain" and game.combat.towers[cell].health == 135, "branch records choice and repairs")
        before = game.combat.gold
        check(not game.choose_upgrade(cell, "lance") and game.combat.gold == before, "cannot switch branches or pay on rejection")
        check(game.upgrade(cell) and game.combat.towers[cell].branch == "chain", "reinforcement preserves chosen branch")
        check(not game.upgrade(cell), "branch reinforcement capped at level three")
        check(game.sell_value(cell) == 105, "refund includes both investments")
    print("Strategy failures: %d; assertions: %d" % [failures, assertions])
    quit(1 if failures else 0)
