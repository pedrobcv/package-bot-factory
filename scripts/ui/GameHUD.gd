extends CanvasLayer

## HUD principal durante la partida.
## Muestra nivel actual, puntaje, vidas, combo, barra de saturación
## y botón de pausa. También puede mostrar textos flotantes.

@onready var level_label: Label = $TopBar/LevelLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var combo_label: Label = $ComboLabel
@onready var saturation_bar: TextureProgressBar = $SaturationBar
@onready var pause_button: Button = $PauseButton
@onready var floating_text_container: Control = $FloatingTextContainer


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_pressed)

	# Configurar valores iniciales
	level_label.text = "NIVEL 1"
	score_label.text = "PUNTOS: 0"
	lives_label.text = "❤❤❤"
	combo_label.visible = false
	saturation_bar.value = 0.0
	saturation_bar.max_value = Constants.MAX_SATURATION if Constants.has_method("MAX_SATURATION") else 100.0


func update_score(score: int) -> void:
	## Actualiza el texto del puntaje
	score_label.text = "PUNTOS: %d" % score


func update_lives(lives: int) -> void:
	## Actualiza la visualización de vidas como corazones
	var hearts: String = ""
	for i in range(lives):
		hearts += "❤"
	lives_label.text = hearts


func update_combo(combo: int, multiplier: int) -> void:
	## Actualiza el texto del combo activo
	if combo >= 2:
		combo_label.text = "COMBO x%d" % multiplier
		combo_label.visible = true
	else:
		combo_label.visible = false


func update_saturation(saturation: float, max_saturation: float) -> void:
	## Actualiza la barra de saturación
	## saturation: valor actual
	## max_saturation: valor máximo (normalmente Constants.MAX_SATURATION)
	saturation_bar.max_value = max_saturation
	saturation_bar.value = saturation

	# Cambiar color según la saturación (verde -> amarillo -> rojo)
	var ratio: float = saturation / max_saturation if max_saturation > 0 else 0.0
	if ratio < 0.5:
		saturation_bar.modulate = Color(0.15, 0.70, 0.15)  # Verde
	elif ratio < 0.8:
		saturation_bar.modulate = Color(1.0, 0.8, 0.0)  # Amarillo
	else:
		saturation_bar.modulate = Color(0.85, 0.15, 0.15)  # Rojo


func update_level(level_num: int) -> void:
	## Actualiza el texto del nivel actual
	level_label.text = "NIVEL %d" % level_num


func show_combo_text(text: String) -> void:
	## Muestra un texto emergente de combo (ej: "¡COMBO x10!")
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	label.add_theme_font_size_override("font_size", 48)
	label.position = Vector2(
		get_viewport().get_visible_rect().size.x / 2 - 100,
		get_viewport().get_visible_rect().size.y / 2
	)

	floating_text_container.add_child(label)

	# Animación de desvanecimiento
	var tween: Tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 100, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


func show_floating_text(text: String, position: Vector2, color: Color) -> void:
	## Muestra un texto flotante en una posición específica del mundo
	## Útil para mostrar puntuaciones que aparecen sobre los paquetes

	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 24)
	label.position = position - Vector2(50, 0)

	floating_text_container.add_child(label)

	# Animación: flotar hacia arriba y desvanecerse
	var tween: Tween = create_tween()
	tween.tween_property(label, "position:y", position.y - 60, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)


func _on_pause_pressed() -> void:
	## Maneja la pulsación del botón de pausa

	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	SignalBus.pause_requested.emit()
