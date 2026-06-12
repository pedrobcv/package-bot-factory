extends Control

## Pantalla de selección de niveles.
## Muestra una cuadrícula de 2 filas x 5 columnas con los niveles disponibles.
## Los niveles desbloqueados se muestran en verde, los bloqueados en gris.
## Debajo de cada nivel se muestra la puntuación más alta obtenida.

signal level_selected(level_num: int)

@onready var level_grid: GridContainer = $LevelGrid
@onready var back_button: Button = $BackButton

## Cantidad total de niveles
const TOTAL_LEVELS: int = 10

## Columnas del grid
const GRID_COLUMNS: int = 5

## Referencias a los botones de nivel
var _level_buttons: Array[Button] = []

## Referencias a etiquetas de puntuación por nivel
var _score_labels: Array[Label] = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	# Configurar el grid
	level_grid.columns = GRID_COLUMNS

	# Crear los botones de nivel
	_build_level_buttons()

	# Refrescar estado de niveles
	refresh_levels()

	# Notificar a SignalBus
	SignalBus.menu_opened.emit("level_select")


func _build_level_buttons() -> void:
	## Construye los botones de nivel y las etiquetas de puntuación

	for i in range(TOTAL_LEVELS):
		var level_num: int = i + 1

		# Contenedor vertical para cada nivel (botón + puntuación)
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.name = "LevelVBox_%d" % level_num
		vbox.custom_minimum_size = Vector2(120, 140)
		vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		# Botón del nivel
		var btn: Button = Button.new()
		btn.name = "LevelButton_%d" % level_num
		btn.text = str(level_num)
		btn.custom_minimum_size = Vector2(100, 100)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_level_button_pressed.bind(level_num))
		vbox.add_child(btn)
		_level_buttons.append(btn)

		# Etiqueta de puntuación
		var score_label: Label = Label.new()
		score_label.name = "ScoreLabel_%d" % level_num
		score_label.text = ""
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.custom_minimum_size = Vector2(100, 30)
		vbox.add_child(score_label)
		_score_labels.append(score_label)

		level_grid.add_child(vbox)


func refresh_levels() -> void:
	## Actualiza el estado visual de todos los niveles según el progreso guardado

	var unlocked_levels: int = 1
	if SaveManager and SaveManager.has_method("get_last_unlocked_level"):
		unlocked_levels = SaveManager.get_last_unlocked_level()

	for i in range(TOTAL_LEVELS):
		var level_num: int = i + 1
		var btn: Button = _level_buttons[i]
		var score_label: Label = _score_labels[i]

		var is_unlocked: bool = level_num <= unlocked_levels

		# Estilo visual del botón
		if is_unlocked:
			btn.disabled = false
			btn.modulate = Color(0.15, 0.70, 0.15)  # Verde
		else:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)  # Gris

		# Mostrar puntuación máxima
		if is_unlocked and SaveManager and SaveManager.has_method("get_level_score"):
			var high_score: int = SaveManager.get_level_score(level_num)
			if high_score > 0:
				score_label.text = "PUNTOS: %d" % high_score
			else:
				score_label.text = ""
		else:
			score_label.text = ""


func _on_level_button_pressed(level_num: int) -> void:
	## Maneja la pulsación de un botón de nivel

	# Reproducir sonido
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	# Emitir señal para que GameManager cargue el nivel
	level_selected.emit(level_num)

	# Iniciar el nivel seleccionado
	if GameManager and GameManager.has_method("start_level"):
		GameManager.start_level(level_num)


func _on_back_pressed() -> void:
	## Vuelve al menú principal

	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")

	SignalBus.change_scene.emit("res://scenes/ui/StartMenu.tscn")
