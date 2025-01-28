# When resizing player, remember that the collision shape should be smaller
# than the cell size to avoid collisions with walls/tail when moving parallel
# right next to either.

extends Area2D

signal wall_hit
signal apple_eaten

func _ready():
    pass

func _process(_delta: float):
    pass

func start(new_position: Vector2) -> void:
    position = new_position
    $CollisionShape2D.set_deferred("disabled", false)

func reset() -> void:
    $CollisionShape2D.set_deferred("disabled", true)
    position = Vector2.ZERO

func _on_body_entered(body: Node2D) -> void:
    if (body.name == "Apple"):
        apple_eaten.emit()
    else:
        wall_hit.emit()
