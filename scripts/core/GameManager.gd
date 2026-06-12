extends Node

## GameManager - Gestor principal del estado del juego
##
## Autoload que maneja los estados del juego (menú, jugando, pausado,
## victoria, derrota) y la lógica central de puntuación, vidas,
## combos y saturación. Se comunica con otros sistemas mediante
## las señales de SignalBus.
##
## Registrado como "GameManager" en Project Settings > Autoload.

# ------------------- Señales propias -------------------

## Señal interna para notificar cambio de estado
## @param new_state: Constants.GameState - Nuevo estado del juego
signal state_changed(new_state: int)

# ------------------- Variables de estado -------------------

## Estado actual del juego (ver Constants.GameState)
var current_state: int = Constants.GameState.MENU

## Nivel actual que se está jugando
var current_level: int = 1

## Puntuación actual del jugador en este nivel
var score: int = 0

## Vidas restantes del jugador
var lives: int = Constants.MAX_LIVES

## Contador de aciertos consecutivos para el combo
var combo_count: int = 0

## Multiplicador actual del combo
var combo_multiplier: int = 1

## Nivel de saturación actual (0.0 a 100.0)
var saturation: float = 0.0

# ------------------- Referencias @onready -------------------

@onready var signal_bus: Node = get_node("/root/SignalBus")


# ==================================================================
# Funciones de gestión de estado
# ==================================================================

## Inicia una nueva partida desde el nivel 1
func start_game() -> void:
	reset_game_state()
	current_state = Constants.GameState.PLAYING
	current_level = 1
	state_changed.emit(current_state)
	signal_bus.game_started.emit()


## Inicia un nivel específico
## @param level_num: int - Número de nivel a iniciar
func start_level(level_num: int) -> void:
	reset_game_state()
	current_state = Constants.GameState.PLAYING
	current_level = level_num
	
	# Cargar configuración del nivel
	var level_data = LevelManager.load_level(level_num)
	if level_data.is_empty():
		push_error("GameManager: No se pudo cargar el nivel ", level_num)
		return
	
	# Aplicar configuración del nivel
	lives = level_data.get("max_lives", Constants.MAX_LIVES)
	var max_sat = level_data.get("max_saturation", Constants.MAX_SATURATION)
	
	state_changed.emit(current_state)
	signal_bus.level_selected.emit(level_num)
	signal_bus.game_started.emit()


## Pausa el juego
func pause_game() -> void:
	if current_state == Constants.GameState.PLAYING:
		current_state = Constants.GameState.PAUSED
		state_changed.emit(current_state)
		signal_bus.game_paused.emit()


## Reanuda el juego desde pausa
func resume_game() -> void:
	if current_state == Constants.GameState.PAUSED:
		current_state = Constants.GameState.PLAYING
		state_changed.emit(current_state)
		signal_bus.game_resumed.emit()


# ==================================================================
# Funciones de puntuación y progreso
# ==================================================================

## Añade puntos a la puntuación actual aplicando el multiplicador de combo
## @param points: int - Puntos base a añadir
func add_score(points: int) -> void:
	var final_points = points * combo_multiplier
	score += final_points
	signal_bus.score_updated.emit(score)


## Reduce una vida al jugador y verifica si es derrota
func lose_life() -> void:
	lives = max(0, lives - 1)
	signal_bus.lives_changed.emit(lives)
	
	if lives <= 0:
		check_defeat()


## Incrementa el contador de combo y actualiza el multiplicador
func add_combo() -> void:
	combo_count += 1
	combo_multiplier = 1
	
	# Buscar el multiplicador correspondiente al combo actual
	var thresholds = Constants.COMBO_THRESHOLDS
	var sorted_counts = thresholds.keys()
	sorted_counts.sort()
	
	for count in sorted_counts:
		if combo_count >= count:
			combo_multiplier = thresholds[count]
		else:
			break
	
	signal_bus.combo_updated.emit(combo_count, combo_multiplier)


## Rompe la racha de combo, reiniciando contador y multiplicador
func break_combo() -> void:
	combo_count = 0
	combo_multiplier = 1
	signal_bus.combo_broken.emit()


## Añade saturación al medidor y verifica condiciones de derrota
## @param amount: float - Cantidad de saturación a añadir (0.0 a 100.0)
func add_saturation(amount: float) -> void:
	saturation = clamp(saturation + amount, 0.0, Constants.MAX_SATURATION)
	signal_bus.saturation_changed.emit(saturation)
	
	if saturation >= Constants.MAX_SATURATION:
		check_defeat()


## Verifica si se cumplen las condiciones de victoria
## (debe ser conectado desde LevelManager o escena de nivel)
func check_victory() -> void:
	if current_state != Constants.GameState.PLAYING:
		return
	
	current_state = Constants.GameState.VICTORY
	state_changed.emit(current_state)
	
	# Guardar puntuación
	if SaveManager:
		SaveManager.save_high_score(current_level, score)
		SaveManager.unlock_level(current_level + 1)
		SaveManager.save_game()
	
	signal_bus.victory.emit()


## Verifica si se cumplen las condiciones de derrota y cambia el estado
func check_defeat() -> void:
	if current_state != Constants.GameState.PLAYING:
		return
	
	current_state = Constants.GameState.DEFEAT
	state_changed.emit(current_state)
	
	var reason = ""
	if lives <= 0:
		reason = "Te quedaste sin vidas"
	elif saturation >= Constants.MAX_SATURATION:
		reason = "Saturación máxima alcanzada"
	else:
		reason = "Condición de derrota desconocida"
	
	signal_bus.defeat.emit(reason)


# ==================================================================
# Funciones de navegación
# ==================================================================

## Vuelve al menú principal
func return_to_menu() -> void:
	current_state = Constants.GameState.MENU
	state_changed.emit(current_state)
	reset_game_state()
	signal_bus.return_to_menu.emit()


## Reinicia todas las variables de estado del juego a sus valores iniciales
func reset_game_state() -> void:
	score = 0
	lives = Constants.MAX_LIVES
	combo_count = 0
	combo_multiplier = 1
	saturation = 0.0
