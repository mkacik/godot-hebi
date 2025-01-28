extends Node

func _ready() -> void:
    pass

func _process(_delta: float) -> void:
    pass

func new_game():
    $Level.start()

func _on_level_game_over(final_score: int):
    $HUD.show_game_over_message(final_score)

func _on_level_kana_changed(new_hint: String, new_score: int) -> void:
    $HUD.set_hint(new_hint)
    $HUD.set_score(new_score)

func _on_level_game_paused() -> void:
    $HUD.show_pause_message()

func _on_level_game_unpaused() -> void:
    $HUD.hide_pause_message()
