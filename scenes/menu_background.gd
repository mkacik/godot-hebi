extends Node2D

const Letters = preload("res://lib/letters.gd")

const SPAWN_POSITION_Y = -64

@export var falling_letter: PackedScene

var screen_width: int

func _ready() -> void:
    screen_width = $Background.size.x

func _process(_delta: float) -> void:
    pass

func start() -> void:
    $LetterSpawnTimer.start()

func stop() -> void:
    $LetterSpawnTimer.stop()
    get_tree().call_group("falling_letters", "queue_free")

func _on_letter_spawn_timer_timeout() -> void:
    var new_falling_letter = falling_letter.instantiate()

    var spawn_position_x = randi_range(0, screen_width)
    var letter_spawn_position = Vector2(spawn_position_x, SPAWN_POSITION_Y)
    new_falling_letter.position = letter_spawn_position

    var kana = Letters.pick_random().get("kana")
    new_falling_letter.set_text(kana)

    add_child(new_falling_letter)
    new_falling_letter.show()
