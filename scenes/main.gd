extends Node

func _ready() -> void:
    pass

func _process(_delta: float) -> void:
    pass

func new_game():
    $Level.start()

func game_over():
    $Level.stop()
    $HUD.show_game_over_message()

func _on_level_kana_changed(new_hint: String) -> void:
    $HUD.set_hint(new_hint)
    # Kana only changes if player picked correct character
    $HUD.bump_score()

func _on_level_pause_toggled(is_paused: bool) -> void:
    $HUD.pause(is_paused)
