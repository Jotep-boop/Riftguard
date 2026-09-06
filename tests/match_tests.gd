extends SceneTree
var failures := 0
var assertions := 0
func check(ok: bool, text: String) -> void:
    assertions += 1
    if not ok:
        failures += 1
        push_error(text)
func _initialize() -> void:
    var combat = load("res://gameplay/combat/combat_model.gd").new()
    check(combat.has_method("configure_tower"), "three tower roles must be configurable")
    if combat.has_method("configure_tower"):
        combat.add_tower(Vector2i.ZERO)
        combat.configure_tower(Vector2i.ZERO, "nova")
        combat.add_enemy("a", Vector2(1, 0), 0.5, 100, 5)
        combat.add_enemy("b", Vector2(1, 0.5), 0.4, 100, 5)
        combat.add_enemy("far", Vector2(9, 9), 0.1, 100, 5)
        combat.advance(0)
        combat.advance(0.18)
        check(combat.enemies.far.health == 100, "splash has a finite radius")
        check(combat.enemies.a.health < 100 and combat.enemies.b.health < 100, "nova damages clustered enemies on impact")
        combat.configure_tower(Vector2i.ZERO, "frost")
        combat.towers[Vector2i.ZERO].cooldown = 0
        combat.advance(0)
        combat.advance(0.18)
        check(combat.enemies.a.slow_timer > 0, "frost applies timed slow on impact")
        combat.remove_tower(Vector2i.ZERO)
        combat.advance(2.0)
        check(combat.enemies.a.slow_timer == 0, "slow expires without permanent stacking")
    check(ResourceLoader.exists("res://gameplay/match/match_model.gd"), "match economy model exists")
    if ResourceLoader.exists("res://gameplay/match/match_model.gd"):
        var match_model = load("res://gameplay/match/match_model.gd").new()
        check(match_model.combat.gold == 240 and match_model.lives == 12, "starting budget and lives")
        check(match_model.place(Vector2i(3, 3), "arc"), "buy tower")
        check(match_model.combat.gold == 195, "purchase deducts cost")
        check(match_model.upgrade(Vector2i(3, 3)), "upgrade bought")
        check(match_model.combat.towers[Vector2i(3, 3)].level == 2, "upgrade increases level")
        check(match_model.sell(Vector2i(3, 3)), "sell tower")
        check(match_model.combat.gold == 216 and match_model.board.blocked.is_empty(), "sell refunds 70 percent invested")
        check(not match_model.place(Vector2i(0, 4), "arc"), "spawn cannot be built on")
        var before: int = match_model.combat.gold
        check(not match_model.place(Vector2i(-1, 4), "arc") and not match_model.place(Vector2i(2, 2), "unknown"), "invalid purchases rejected")
        check(match_model.combat.gold == before, "rejected purchase never charges")
        match_model.combat.gold = 0
        check(not match_model.place(Vector2i(2, 2), "arc"), "insufficient budget rejected")
        match_model.combat.gold = before
        check(match_model.has_method("start_wave"), "finite wave lifecycle exists")
        if match_model.has_method("start_wave"):
            check(match_model.start_wave(), "start first wave")
            check(not match_model.start_wave(), "cannot overlap waves")
            for tick in range(3000):
                match_model.advance(0.05)
            check(match_model.phase == "build" and match_model.lives < 12, "undefended wave leaks and returns to build")
            while match_model.phase == "build":
                match_model.start_wave()
                for tick in range(3000):
                    match_model.advance(0.05)
            check(match_model.phase == "lost", "undefended match loses")
            match_model.restart()
            check(match_model.wave == 0 and match_model.lives == 12 and match_model.combat.enemies.is_empty() and match_model.combat.gold == 240, "restart resets complete match")
    print("Match assertions failed: ", failures, "; assertions executed: ", assertions)
    quit(1 if failures else 0)
