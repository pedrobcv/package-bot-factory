extends CanvasLayer

## Pantalla de derrota al perder un nivel.
## Muestra la causa de la derrota y permite
## reintentar el nivel o volver al menú principal.

@onready var title_label: Label = $Panel/TitleLabel
@onready var cause_label: Label = $Panel/CauseLabel
@onready var retry_button: Button = $Panel/RetryButton
@onready var menu_button: Button = $Panel/MenuButton
@onready var panel: Control = $Panel

## Nivel que se perdió
var _failed_level: int = 1


func _ready() -> void:
	# Conectar señales de botones
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	# Configurar textos
	title_label.text = "DERROTA"

	# Escuchar datos de derrota desde SignalBus
	if SignalBus.level_failed.is_connected(_on_level_failed):
		SignalBus.level_failed.disconnect(_on_level_failed)
	SignalBus.level_failed.connect(_on_level_failed)

	# Si ya hay datos disponibles, mostrarlos
	if GameManager and GameManager.has_method("get_last_fail_data"):
		var fail_data: Dictionary = GameManager.get_last_fail_data()
		_display_fail_info(fail_data)

	# Animación de entrada
	modulate = Color.TRANSPARENT
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.play()


func _on_level_failed(data: Dictionary) -> void:
	## Recibe los datos de la derrota desde SignalBus
	_display_fail_info(data)


func _display_fail_info(data: Dictionary) -> void:
	## Muestra la causa de la derrota

	_failed_level = data.get("level", 1)
	var cause: String = data.get("cause", "unknown")

	match cause:
		"no_lives":
			cause_label.text = "Sin vidas"
		"max_saturation":
			cause_label.text = "Saturación máxima"
		_:
			cause_label.text = "Has perdido"


func _on_retry_pressed() -> void:
	## Reintenta el nivel actual

	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

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

	SignalBus.change_scene.emit("res://scenes/ui/StartMenu.tscn")

	queue_free()
