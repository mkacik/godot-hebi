extends Node2D

const Letters = preload("res://lib/letters.gd")

const CELL_SIZE: int = 48
const MOVE_INTERVAL: float = 0.3

signal game_over(final_score: int)
signal kana_changed(new_hint: String, score: int)
signal game_paused
signal game_unpaused

@export var wall_scene: PackedScene
@export var tail_scene: PackedScene
@export var apple_scene: PackedScene

var grid_size: Vector2
var cells: Cells
var score: int

var next_direction: Vector2
var player_cell: Vector2

var tail_segments: Array = []
var decoys: Array = []

var is_paused: bool

func _ready() -> void:
    $MoveTimer.wait_time = MOVE_INTERVAL
    grid_size = $Background.size / CELL_SIZE
    cells = Cells.new(grid_size)

func _process(_delta: float) -> void:
    if is_paused:
        return

    if Input.is_action_pressed("move_right"):
        if can_move(Vector2.RIGHT):
            next_direction = Vector2.RIGHT
    elif Input.is_action_pressed("move_left"):
        if can_move(Vector2.LEFT):
            next_direction = Vector2.LEFT
    elif Input.is_action_pressed("move_down"):
        if can_move(Vector2.DOWN):
            next_direction = Vector2.DOWN
    elif Input.is_action_pressed("move_up"):
        if can_move(Vector2.UP):
            next_direction = Vector2.UP

func _input(event):
    if !visible:
        return

    if event.is_action_pressed("ui_cancel"):
        if is_paused:
            unpause()
        else:
            pause()

func can_move(maybe_next_direction: Vector2) -> bool:
    return (next_direction + maybe_next_direction) != Vector2.ZERO

func spawn_wall(cell: Vector2, new_name: String) -> void:
    var wall = wall_scene.instantiate()
    wall.name = new_name
    wall.position = cell * CELL_SIZE
    add_child(wall)
    cells.mark_occupied(cell)

func spawn_walls() -> void:
    for x in range(0, grid_size.x):
        spawn_wall(Vector2(x, 0), "WallNorth" + str(x))
        spawn_wall(Vector2(x, grid_size.y - 1), "WallSouth" + str(x))

    # skipping first and last rows because they were covered by loop above
    for y in range(1, grid_size.y - 1):
        spawn_wall(Vector2(0, y), "WallWest" + str(y))
        spawn_wall(Vector2(grid_size.x - 1, y), "WallEast" + str(y))

func spawn_apple(text: String) -> void:
    # no need to mark previous cell free: this function is only called on start
    # and when apple is eaten. In latter case, that means snake head is now
    # occupying the position
    var cell = cells.get_random_free_cell()
    $Apple.position = cell * CELL_SIZE
    $Apple.set_text(text)
    cells.mark_occupied(cell)

func spawn_decoy(text: String) -> void:
    var cell = cells.get_random_free_cell()
    var decoy = apple_scene.instantiate()
    decoy.name = "Decoy" + str(decoys.size())
    decoy.position = cell * CELL_SIZE
    decoy.set_text(text)
    $Background.call_deferred("add_sibling", decoy)
    decoys.append(decoy)
    cells.mark_occupied(cell)

func spawn_apples() -> void:
    # clear previous decoys first
    while decoys.size() > 0:
        var decoy = decoys.pop_front()
        var cell = decoy.position / CELL_SIZE
        decoy.hide()
        decoy.queue_free()
        cells.mark_free(cell)

    var random_kana = Letters.pick_random()
    var english = random_kana["english"]
    var kana = random_kana["kana"]

    kana_changed.emit(english, score)
    spawn_apple(kana)
    var new_decoys = Letters.get_two_others(kana)

    for decoy in new_decoys:
        spawn_decoy(decoy)

func spawn_tail_segment(cell: Vector2) -> void:
    var tail_segment = tail_scene.instantiate()
    tail_segment.name = "TailSegment" + str(tail_segments.size())
    tail_segment.position = cell * CELL_SIZE
    tail_segments.push_back(tail_segment)
    call_deferred("add_child", tail_segment)
    cells.mark_occupied(cell)

func spawn_player(cell: Vector2) -> void:
    player_cell = cell
    $Player.start(cell * CELL_SIZE)
    cells.mark_occupied(cell)

func spawn_snake() -> void:
    var cell = Vector2(8, 5)
    spawn_player(cell)

    var tail_segment_relative_positions = [Vector2.LEFT, Vector2.LEFT, Vector2.DOWN, Vector2.DOWN, Vector2.DOWN]
    for direction in tail_segment_relative_positions:
        cell += direction
        spawn_tail_segment(cell)

    # Pick staring direction. Can go in one of 3 directions
    var valid_directions = [Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT, Vector2.UP]
    valid_directions.erase(tail_segment_relative_positions[0])
    next_direction = valid_directions.pick_random()

func start() -> void:
    cells.initialize()
    spawn_snake()
    spawn_walls()
    spawn_apples()
    score = 0
    show()
    $MoveTimer.start()

func stop() -> void:
    $MoveTimer.stop()
    hide()
    $Player.reset()
    get_tree().call_group("walls", "queue_free")
    get_tree().call_group("tail", "queue_free")
    tail_segments.clear()

func pause() -> void:
    $MoveTimer.stop()
    is_paused = true
    game_paused.emit()

func unpause() -> void:
    game_unpaused.emit()
    is_paused = false
    $MoveTimer.start()

func tick() -> void:
    # 1. Move the player.
    var previous_player_cell = player_cell
    player_cell = player_cell + next_direction
    $Player.position = player_cell * CELL_SIZE
    cells.mark_occupied(player_cell)

    # 2. Move the body: pick the last tail segment and mark it's position
    # in the cell greed as free. Then put that segment right where player
    # just was.
    var last_segment = tail_segments.pop_back()
    cells.mark_free(last_segment.position / CELL_SIZE)
    last_segment.position = previous_player_cell * CELL_SIZE
    tail_segments.push_front(last_segment)

func _on_player_apple_eaten() -> void:
    score += 1
    var tail_end_cell = tail_segments[-1].position / CELL_SIZE
    spawn_tail_segment(tail_end_cell)
    spawn_apples()

func _on_player_wall_hit() -> void:
    stop()
    game_over.emit(score)

func _on_move_timer_timeout() -> void:
    tick()

# This class is used to keep track of free cells to spawn the apples on. When
# picking position at random, there is a risk of selecting cell that snake is
# currently on (or a wall with more complex levels). The longer the snake is,
# the higher risk of not being able to find a free cell randomly in reasonable
# time, so I chose to track the free cells instead, marking them occupied
# when snake enters, and marking them free when tail end leaves.
class Cells extends Node:
    # GDScript does not have sets, but hashmap with null values will do
    var free_cells = {}
    var grid_size

    func _init(new_grid_size: Vector2) -> void:
        grid_size = new_grid_size

    func initialize():
        free_cells.clear()
        for x in range(0, grid_size.x):
            for y in range(0, grid_size.y):
                var cell = Vector2(x, y)
                free_cells[cell] = null

    func mark_free(cell: Vector2) -> void:
        free_cells[cell] = null

    func mark_occupied(cell: Vector2) -> void:
        free_cells.erase(cell)

    func get_random_free_cell() -> Vector2:
        return free_cells.keys().pick_random()
