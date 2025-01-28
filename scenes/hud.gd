extends CanvasLayer

signal start_game

func _ready() -> void:
    $MenuBackground.show()
    $MenuBackground.start()

    $GameOverMessage.hide()
    $StartButton.show()

func _process(_delta: float) -> void:
    pass

func set_hint(text: String) -> void:
    $ScoreBar/Hint.text = "kana: " + text

func set_score(score: int) -> void:
    $ScoreBar/Score.text = "score: " + str(score)

func show_game_over_message(final_score: int):
    $ScoreBar.hide()

    $MenuBackground.show()
    $MenuBackground.start()

    $GameOverMessage.show()
    $StartButton.text = "RESTART"
    $FinalScore.text = "score: " + str(final_score)
    $FinalScore.show()
    await get_tree().create_timer(1.0).timeout

    $StartButton.show()

func show_pause_message() -> void:
    $PauseMessage.show()

func hide_pause_message() -> void:
    $PauseMessage.hide()

func _on_start_button_pressed() -> void:
    $GameOverMessage.hide()
    $FinalScore.hide()
    $StartButton.hide()

    $MenuBackground.hide()
    $MenuBackground.stop()

    $ScoreBar.show()
    start_game.emit()
