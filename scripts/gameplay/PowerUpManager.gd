extends Node

## PowerUpManager - Administrador de power-ups
##
## Gestiona la lista de power-ups disponibles, su activación,
## desactivación y seguimiento de power-ups activos.
##
## Señales del SignalBus utilizadas:
## - power_up_activated(power_up_type)
## - power_up_deactivated(power_up_type)

# ------------------- Variables exportadas -------------------
## Lista de tipos de power-up disponibles en el nivel
## Ejemplo: ["slow_motion", "double_points", "bomb_cleaner"]
@export var available_powerups: Array = []

# ------------------- Variables internas -------------------
## Diccionario de power-ups activos: {type: String, timer: float}
var active_powerups: Dictionary = {}

## Referencia a la escena de PowerUp (para instanciar)
const POWERUP_SCENE_PATH: String = "res://scenes/gameplay/PowerUp.tscn"

## Temporizador para spawn de power-ups
@onready var spawn_timer: Timer = $SpawnTimer


func _ready():
	## Inicializar el administrador de power-ups
	if spawn_timer:
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		spawn_timer.one_shot = false
		spawn_timer.wait_time = 12.0  # Primer power-up a los 12 segundos
		spawn_timer.start()


func _process(delta: float):
	## Verificar expiración de power-ups activos
	var expired_types: Array = []
	
	for power_up_type in active_powerups.keys():
		active_powerups[power_up_type] -= delta
		if active_powerups[power_up_type] <= 0.0:
			expired_types.append(power_up_type)
	
	# Desactivar power-ups expirados
	for power_up_type in expired_types:
		deactivate_power_up(power_up_type)


## Configura el manager desde datos del nivel
## @param powerup_list: Array - Lista de power-ups disponibles
func configure_from_level(powerup_list: Array):
	available_powerups = powerup_list.duplicate()


## Intenta spawnear un power-up aleatorio
func spawn_power_up():
	if available_powerups.is_empty():
		return null
	
	# Elegir tipo aleatorio
	var type_index = randi() % available_powerups.size()
	var power_up_type = available_powerups[type_index]
	
	# Crear instancia de PowerUp desde escena
	var power_up_scene = load(POWERUP_SCENE_PATH)
	if not power_up_scene:
		return null
	var power_up = power_up_scene.instantiate()
	
	power_up.power_up_type = power_up_type
	
	# Configurar duración según tipo
	match power_up_type:
		"slow_motion":
			power_up.duration = 5.0
		"auto_correct":
			power_up.duration = 8.0
		"perfect_suction":
			power_up.duration = 6.0
		"bomb_cleaner":
			power_up.duration = 0.0  # Instantáneo
		"double_points":
			power_up.duration = 7.0
		"preview":
			power_up.duration = 10.0
	
	return power_up


## Activa un power-up por tipo
## @param type: String - Tipo de power-up a activar
func activate_power_up(type: String):
	if has_active_power_up(type):
		# Si ya está activo, reiniciar timer
		active_powerups[type] = _get_duration_for_type(type)
		return
	
	# Obtener duración
	var duration = _get_duration_for_type(type)
	active_powerups[type] = duration
	
	SignalBus.power_up_activated.emit(type)


## Desactiva un power-up por tipo
## @param type: String - Tipo de power-up a desactivar
func deactivate_power_up(type: String):
	if not active_powerups.has(type):
		return
	
	active_powerups.erase(type)
	SignalBus.power_up_deactivated.emit(type)


## Verifica si un power-up está activo
## @param type: String - Tipo de power-up
## @return: bool - true si está activo
func has_active_power_up(type: String) -> bool:
	return active_powerups.has(type)


## Retorna la duración para un tipo de power-up
func _get_duration_for_type(type: String) -> float:
	match type:
		"slow_motion":
			return 5.0
		"auto_correct":
			return 8.0
		"perfect_suction":
			return 6.0
		"bomb_cleaner":
			return 0.0  # Instantáneo
		"double_points":
			return 7.0
		"preview":
			return 10.0
		_:
			return 5.0


## Evento del timer de spawn
func _on_spawn_timer_timeout():
	var power_up = spawn_power_up()
	if power_up:
		add_child(power_up)
		# El power_up se posicionará donde el nivel decida
