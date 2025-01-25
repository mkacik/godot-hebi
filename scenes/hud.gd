extends CanvasLayer

signal start_game

var score = 0

func _ready() -> void:
    $GameOverMessage.hide()
    $StartButton.show()

func _process(_delta: float) -> void:
    pass

func set_hint(text: String) -> void:
    $Hint.text = "kana: " + text

func bump_score() -> void:
    score += 1
    $Score.text = "score: " + str(score)

func show_game_over_message():
    $Hint.hide()
    $Score.hide()

    $GameOverMessage.show()
    $FinalScore.text = str(score)
    $FinalScore.show()
    await get_tree().create_timer(3.0).timeout


    $StartButton.show()

func _on_start_button_pressed() -> void:
    $GameOverMessage.hide()
    $FinalScore.hide()
    $StartButton.hide()

    score = -1
    $Hint.show()
    $Score.show()
    start_game.emit()

func pause(pause: bool) -> void:
    if pause:
        $PauseMessage.show()
    else:
        $PauseMessage.hide()
