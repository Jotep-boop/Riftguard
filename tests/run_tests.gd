extends SceneTree

const GridPathfinder = preload("res://gameplay/board/grid_pathfinder.gd")
const BoardModel = preload("res://gameplay/board/board_model.gd")

var failures := 0

func _init() -> void:
    _test_finds_a_direct_route()
    _test_routes_around_a_blocked_cell()
    _test_board_accepts_a_legal_blocker()
    _test_board_rejects_a_route_sealing_blocker()
    _test_board_removes_a_blocker()
    _test_board_clears_all_blockers()
    _test_board_previews_a_legal_placement()
    _test_board_previews_a_route_sealing_placement()
    if failures == 0:
        print("PASS: 8 tests")
        quit(0)
    else:
        push_error("FAIL: %d assertion(s)" % failures)
        quit(1)

func _test_finds_a_direct_route() -> void:
    var route: Array[Vector2i] = GridPathfinder.find_path(
        Vector2i(3, 1),
        Vector2i(0, 0),
        Vector2i(2, 0),
        {}
    )
    _expect(route.size() == 3, "direct route contains all three cells")
    _expect(route.front() == Vector2i(0, 0), "direct route starts at the rift")
    _expect(route.back() == Vector2i(2, 0), "direct route ends at the gate")

func _test_routes_around_a_blocked_cell() -> void:
    var blocked := {Vector2i(1, 0): true}
    var route: Array[Vector2i] = GridPathfinder.find_path(
        Vector2i(3, 2),
        Vector2i(0, 0),
        Vector2i(2, 0),
        blocked
    )
    _expect(not route.is_empty(), "an alternate route exists")
    _expect(not route.has(Vector2i(1, 0)), "route avoids blocked cells")
    _expect(route.size() == 5, "route takes the shortest detour")

func _test_board_accepts_a_legal_blocker() -> void:
    var board = BoardModel.new(Vector2i(3, 2), Vector2i(0, 0), Vector2i(2, 0))
    var accepted: bool = board.try_place_blocker(Vector2i(1, 0))
    _expect(accepted, "board accepts a blocker when a detour remains")
    _expect(board.blocked.has(Vector2i(1, 0)), "accepted blocker is retained")

func _test_board_rejects_a_route_sealing_blocker() -> void:
    var board = BoardModel.new(Vector2i(3, 1), Vector2i(0, 0), Vector2i(2, 0))
    var accepted: bool = board.try_place_blocker(Vector2i(1, 0))
    _expect(not accepted, "board rejects a blocker that seals the route")
    _expect(not board.blocked.has(Vector2i(1, 0)), "rejected blocker is rolled back")
    _expect(not board.route.is_empty(), "existing route survives a rejected placement")

func _test_board_removes_a_blocker() -> void:
    var board = BoardModel.new(Vector2i(3, 2), Vector2i(0, 0), Vector2i(2, 0))
    board.try_place_blocker(Vector2i(1, 0))
    board.remove_blocker(Vector2i(1, 0))
    _expect(not board.blocked.has(Vector2i(1, 0)), "removed blocker leaves the board")
    _expect(board.route.size() == 3, "route shortens after blocker removal")

func _test_board_clears_all_blockers() -> void:
    var board = BoardModel.new(Vector2i(4, 2), Vector2i(0, 0), Vector2i(3, 0))
    board.try_place_blocker(Vector2i(1, 0))
    board.try_place_blocker(Vector2i(2, 0))
    board.clear_blockers()
    _expect(board.blocked.is_empty(), "clear removes every blocker")

func _test_board_previews_a_legal_placement() -> void:
    var board = BoardModel.new(Vector2i(3, 2), Vector2i(0, 0), Vector2i(2, 0))
    _expect(board.has_method("can_place_blocker"), "board exposes placement preview")
    if board.has_method("can_place_blocker"):
        _expect(board.can_place_blocker(Vector2i(1, 0)), "preview accepts a legal detour")
        _expect(board.blocked.is_empty(), "preview does not mutate the board")

func _test_board_previews_a_route_sealing_placement() -> void:
    var board = BoardModel.new(Vector2i(3, 1), Vector2i(0, 0), Vector2i(2, 0))
    _expect(board.has_method("can_place_blocker"), "board exposes route-sealing preview")
    if board.has_method("can_place_blocker"):
        _expect(not board.can_place_blocker(Vector2i(1, 0)), "preview rejects a sealed route")

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("Assertion failed: " + message)
