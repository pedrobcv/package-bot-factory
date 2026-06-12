extends Control

## Pantalla de inicio del juego.
## Muestra el título del juego y tres botones principales:
## JUGAR, SELECCIONAR NIVEL y SALIR.

@onready var title_label: Label = $TitleLabel
@onready var play_button: Button = $PlayButton
@onready var level_select_button: Button = $LevelSelectButton
@onready var quit_button: Button = $QuitButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _fade_in_duration: float = 0.5


func _ready() -> void:
	# Conectar señales de botones
	play_button.pressed.connect(_on_play_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Conectar con SignalBus para notificar que se abrió el menú
	SignalBus.menu_opened.emit("start")

	# Configurar el texto del título
	title_label.text = "Package Bot Factory"

	# Iniciar animación de fade-in si existe AnimationPlayer
	if animation_player and animation_player.has_animation("fade_in"):
		animation_player.play("fade_in")
	else:
		# Fade-in manual por si no hay AnimationPlayer
		modulate = Color.TRANSPARENT
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, _fade_in_duration)
		tween.play()


func _on_play_pressed() -> void:
	# Reproducir sonido de clic
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	# Obtener el último nivel desbloqueado desde SaveManager
	var last_level: int = 1
	if SaveManager and SaveManager.has_method("get_last_unlocked_level"):
		last_level = SaveManager.get_last_unlocked_level()

	# Iniciar el nivel
	if GameManager and GameManager.has_method("start_level"):
		GameManager.start_level(last_level)


func _on_level_select_pressed() -> void:
	# Reproducir sonido de clic
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	# Cambiar a la pantalla de selección de niveles
	SignalBus.change_scene.emit("res://scenes/ui/LevelSelect.tscn")


func _on_quit_pressed() -> void:
	# Reproducir sonido de clic
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	# Salir del juego
	get_tree().quit()
