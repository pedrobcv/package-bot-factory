extends CanvasLayer

## Menú de pausa superpuesto al juego.
## Muestra un fondo semi-transparente oscuro con tres opciones:
## CONTINUAR, REINICIAR NIVEL y VOLVER AL MENÚ.

@onready var background: ColorRect = $Background
@onready var continue_button: Button = $Panel/ContinueButton
@onready var restart_button: Button = $Panel/RestartButton
@onready var menu_button: Button = $Panel/MenuButton
@onready var panel: Control = $Panel


func _ready() -> void:
	# Conectar señales de botones
	continue_button.pressed.connect(_on_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	# Configurar textos en español
	continue_button.text = "CONTINUAR"
	restart_button.text = "REINICIAR NIVEL"
	menu_button.text = "VOLVER AL MENÚ"

	# Animación de entrada con tween (usamos panel que sí tiene modulate)
	if panel:
		panel.modulate = Color.TRANSPARENT
		var tween: Tween = create_tween()
		tween.tween_property(panel, "modulate", Color.WHITE, 0.2)
		tween.play()

	# Pausar el juego
	get_tree().paused = true


func _on_continue_pressed() -> void:
	## Reanuda la partida

	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	# Despausar
	get_tree().paused = false

	# Notificar a SignalBus
	SignalBus.game_resumed.emit()

	# Remover este menú
	queue_free()


func _on_restart_pressed() -> void:
	## Reinicia el nivel actual

	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	# Despausar
	get_tree().paused = false

	# Reiniciar el nivel a través de GameManager
	if GameManager and GameManager.has_method("restart_level"):
		GameManager.restart_level()
	else:
		# Fallback: recargar la escena actual
		SignalBus.change_scene.emit(get_tree().current_scene.scene_file_path)

	queue_free()


func _on_menu_pressed() -> void:
	## Vuelve al menú principal

	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	# Despausar
	get_tree().paused = false

	# Ir al menú principal
	SignalBus.change_scene.emit("res://scenes/ui/StartMenu.tscn")

	queue_free()
