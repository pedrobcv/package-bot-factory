extends CanvasLayer

## Pantalla de victoria al completar un nivel.
## Muestra estadísticas del nivel completado y permite
## continuar al siguiente nivel o volver al menú principal.

@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var score_label: Label = $Panel/ScoreLabel
@onready var packages_label: Label = $Panel/PackagesLabel
@onready var errors_label: Label = $Panel/ErrorsLabel
@onready var max_combo_label: Label = $Panel/MaxComboLabel
@onready var stars_container: Control = $Panel/StarsContainer
@onready var next_button: Button = $Panel/NextButton
@onready var menu_button: Button = $Panel/MenuButton

## Nivel que se acaba de completar
var _completed_level: int = 1

## Puntaje obtenido
var _total_score: int = 0

## Total de niveles del juego
const TOTAL_LEVELS: int = 10


func _ready() -> void:
	# Conectar señales de botones
	next_button.pressed.connect(_on_next_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	# Configurar textos base
	title_label.text = "¡NIVEL COMPLETADO!"

	# Escuchar datos de victoria desde SignalBus
	if SignalBus.level_completed.is_connected(_on_level_completed):
		SignalBus.level_completed.disconnect(_on_level_completed)
	SignalBus.level_completed.connect(_on_level_completed)

	# Si ya hay datos disponibles, mostrarlos
	if GameManager and GameManager.has_method("get_last_level_result"):
		var result: Dictionary = GameManager.get_last_level_result()
		_display_results(result)

	# Animación de entrada (usamos panel que sí tiene modulate al ser CanvasItem)
	if panel:
		panel.modulate = Color.TRANSPARENT
		var tween: Tween = create_tween()
		tween.tween_property(panel, "modulate", Color.WHITE, 0.3)
		tween.play()


func _on_level_completed(data: Dictionary) -> void:
	## Recibe los datos del nivel completado desde SignalBus
	_display_results(data)


func _display_results(data: Dictionary) -> void:
	## Muestra las estadísticas del nivel completado

	_completed_level = data.get("level", 1)
	_total_score = data.get("score", 0)

	var correct_packages: int = data.get("correct_packages", 0)
	var target_packages: int = data.get("target_packages", 1)
	var errors: int = data.get("errors", 0)
	var max_combo: int = data.get("max_combo", 0)

	# Mostrar puntaje
	score_label.text = "PUNTAJE: %d" % _total_score

	# Mostrar paquetes correctos / objetivo
	packages_label.text = "PAQUETES: %d / %d" % [correct_packages, target_packages]

	# Mostrar errores
	errors_label.text = "ERRORES: %d" % errors

	# Mostrar combo máximo
	if max_combo > 0:
		max_combo_label.text = "COMBO MÁXIMO: x%d" % max_combo
	else:
		max_combo_label.text = ""

	# Calcular y mostrar estrellas (1-3 según rendimiento)
	var stars: int = _calculate_stars(data)
	_display_stars(stars)

	# Configurar botón "SIGUIENTE NIVEL"
	var next_level: int = _completed_level + 1
	if next_level > TOTAL_LEVELS:
		next_button.visible = false
	else:
		next_button.visible = true
		next_button.text = "SIGUIENTE NIVEL"


func _calculate_stars(data: Dictionary) -> int:
	## Calcula el número de estrellas (1-3) según el rendimiento
	## 1 estrella: completar el nivel
	## 2 estrellas: buena precisión
	## 3 estrellas: perfecto (sin errores y completando todos los paquetes)

	var errors: int = data.get("errors", 0)
	var correct_packages: int = data.get("correct_packages", 0)
	var target_packages: int = data.get("target_packages", 1)

	# Siempre al menos 1 estrella por completar
	if errors == 0 and correct_packages >= target_packages:
		return 3
	elif errors <= 2 and correct_packages >= target_packages * 0.8:
		return 2
	else:
		return 1


func _display_stars(stars: int) -> void:
	## Dibuja las estrellas en el contenedor de estrellas
	## Limpia el contenedor y crea Labels con símbolos de estrella

	# Limpiar estrellas anteriores
	for child in stars_container.get_children():
		child.queue_free()

	var star_char: String = "★"
	for i in range(3):
		var star_label: Label = Label.new()
		star_label.text = star_char
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star_label.add_theme_font_size_override("font_size", 64)

		if i < stars:
			# Estrella obtenida: dorada
			star_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		else:
			# Estrella no obtenida: gris oscuro
			star_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

		stars_container.add_child(star_label)


func _on_next_pressed() -> void:
	## Avanza al siguiente nivel

	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	var next_level: int = _completed_level + 1
	if GameManager and GameManager.has_method("start_level"):
		GameManager.start_level(next_level)

	queue_free()


func _on_menu_pressed() -> void:
	## Vuelve al menú principal

	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	SignalBus.change_scene.emit("res://scenes/ui/StartMenu.tscn")

	queue_free()
