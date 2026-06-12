extends Node2D

## GameWorld - Coordinador central del gameplay
##
## Orquesta todos los sistemas del juego: carga el nivel,
## instancia los tubos, conecta las señales entre componentes,
## y maneja el ciclo de juego completo.
##
## Señales del SignalBus utilizadas:
## - tube_tapped(tube_color, tube_index)
## - order_added_to_queue(order)
## - order_processed(order, package_ref, success)
## - package_reached_bottom(package_ref)
## - package_collected / package_error
## - combo_updated / combo_broken
## - lives_changed / saturation_changed / score_updated
## - victory / defeat

# ------------------- Constantes -------------------
const TUBE_SCENE_PATH: String = "res://scenes/game/SuctionTube.tscn"
const ROBOT_SCENE_PATH: String = "res://scenes/game/Robot.tscn"
const PACKAGE_SCENE_PATH: String = "res://scenes/game/Package.tscn"

const TUBE_COLORS_LIST: Array = ["azul", "amarillo", "rojo", "verde", "morado"]

# ------------------- Variables de nivel -------------------
var _level_data: Dictionary = {}
var _packages_collected: int = 0
var _packages_target: int = 10
var _errors: int = 0
var _max_combo: int = 0

# ------------------- Referencias a nodos hijos -------------------
@onready var conveyor_belt: Node2D = $ConveyorBelt
@onready var robot_container: Node2D = $RobotContainer
@onready var tubes_container: Node2D = $SuctionTubesContainer
@onready var package_spawner: Node2D = $PackageSpawner
@onready var power_up_manager: Node = $PowerUpManager
@onready var suction_queue: Node = $SuctionQueue
@onready var combo_manager: Node = $ComboManager
@onready var saturation_system: Node = $SaturationSystem

# ------------------- Arrays de tubos -------------------
var _tubes: Array = []  # Array de referencias a SuctionTube

# ------------------------------------------------------------------
# INICIALIZACIÓN
# ------------------------------------------------------------------

func _ready():
	_cargar_nivel_y_configurar()


## Carga los datos del nivel y configura todos los sistemas
func _cargar_nivel_y_configurar():
	# Obtener nivel actual de GameManager
	var level_num = 1
	if GameManager:
		level_num = GameManager.current_level
	
	# Cargar datos del nivel desde LevelManager
	if LevelManager:
		_level_data = LevelManager.load_level(level_num)
	
	if _level_data.is_empty():
		push_error("GameWorld: No se pudo cargar el nivel ", level_num)
		# Datos por defecto para nivel 1
		_level_data = _crear_nivel_default()
	
	# Aplicar configuración a GameManager
	if GameManager:
		GameManager.current_level = level_num
		GameManager.reset_game_state()
		GameManager.current_state = Constants.GameState.PLAYING
	
	# 1. Instanciar tubos
	_instanciar_tubos()
	
	# 2. Instanciar robot
	_instanciar_robot()
	
	# 3. Configurar SuctionQueue
	_configurar_suction_queue()
	
	# 4. Configurar PackageSpawner
	_configurar_package_spawner()
	
	# 5. Configurar PowerUpManager
	_configurar_powerup_manager()
	
	# 6. Conectar señales
	_conectar_seniales()
	
	# 7. Iniciar spawn de paquetes
	if package_spawner and package_spawner.has_method("start_spawning"):
		package_spawner.start_spawning()


## Crea datos de nivel por defecto (fallback)
func _crear_nivel_default() -> Dictionary:
	return {
		"level_number": 1,
		"target_packages": 10,
		"conveyor_speed": 80.0,
		"spawn_interval": 3.0,
		"available_colors": ["azul", "amarillo"],
		"available_package_types": [0],
		"available_powerups": [],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 2,
		"allow_order_cancel": true,
		"difficulty_multiplier": 1.0
	}


# ------------------------------------------------------------------
# INSTANCIACIÓN DE COMPONENTES
# ------------------------------------------------------------------

## Crea los tubos de succión según los colores disponibles en el nivel
func _instanciar_tubos():
	var colors: Array = _level_data.get("available_colors", ["azul", "amarillo"])
	var num_tubes = colors.size()
	var scene = load(TUBE_SCENE_PATH)
	
	if not scene:
		push_error("GameWorld: No se encontró la escena del tubo")
		return
	
	# Calcular espaciado horizontal
	var screen_width = 720.0
	var spacing = screen_width / (num_tubes + 1)
	
	for i in range(num_tubes):
		var tube = scene.instantiate()
		if not tube:
			continue
		
		# Asignar color e índice
		tube.tube_color = colors[i]
		tube.tube_index = i
		
		# Posicionar horizontalmente, alineados arriba del robot
		var x_pos = spacing * (i + 1)
		tube.position = Vector2(x_pos, 0)
		
		tubes_container.add_child(tube)
		_tubes.append(tube)


## Instancia el robot en su contenedor
func _instanciar_robot():
	var scene = load(ROBOT_SCENE_PATH)
	if not scene:
		return
	
	var robot = scene.instantiate()
	if robot:
		robot.position = Vector2(360, 0)
		robot_container.add_child(robot)


# ------------------------------------------------------------------
# CONFIGURACIÓN DE SISTEMAS
# ------------------------------------------------------------------

## Configura la cola de succión con los parámetros del nivel
func _configurar_suction_queue():
	if not suction_queue:
		return
	
	var max_queue = _level_data.get("max_queue_size", 3)
	var allow_cancel = _level_data.get("allow_order_cancel", true)
	
	suction_queue.max_queue_size = max_queue
	suction_queue.allow_cancel = allow_cancel


## Configura el spawner de paquetes con los datos del nivel
func _configurar_package_spawner():
	if not package_spawner:
		return
	
	var level_dict = _level_data
	
	if package_spawner.has_method("configure_from_level"):
		package_spawner.configure_from_level(level_dict)
	
	# También configurar propiedades directamente
	if "spawn_interval" in package_spawner:
		package_spawner.spawn_interval = level_dict.get("spawn_interval", 3.0)
	if "conveyor_speed" in package_spawner:
		package_spawner.conveyor_speed = level_dict.get("conveyor_speed", 80.0)
	if "available_colors" in package_spawner:
		package_spawner.available_colors = level_dict.get("available_colors", ["azul", "amarillo"]).duplicate()
	if "available_package_types" in package_spawner:
		package_spawner.available_types = level_dict.get("available_package_types", [0]).duplicate()
	
	# Configurar timer
	var spawn_timer = package_spawner.get_node_or_null("SpawnTimer")
	if spawn_timer:
		spawn_timer.wait_time = level_dict.get("spawn_interval", 3.0)
	
	# Actualizar target de paquetes
	_packages_target = level_dict.get("target_packages", 10)


## Configura el manager de power-ups
func _configurar_powerup_manager():
	if not power_up_manager:
		return
	
	var powerups = _level_data.get("available_powerups", [])
	if power_up_manager.has_method("configure_from_level"):
		power_up_manager.configure_from_level(powerups)


# ------------------------------------------------------------------
# CONEXIÓN DE SEÑALES
# ------------------------------------------------------------------

## Conecta todas las señales entre los sistemas del juego
func _conectar_seniales():
	# TUBO TOCADO → agregar a cola de succión
	if not SignalBus.tube_tapped.is_connected(_on_tube_tapped):
		SignalBus.tube_tapped.connect(_on_tube_tapped)
	
	# PAQUETE SPAWNEADO → conectar señal de llegada al fondo
	if not SignalBus.package_spawned.is_connected(_on_package_spawned):
		SignalBus.package_spawned.connect(_on_package_spawned)
	
	# PAQUETE LLEGA AL FONDO → aumentar saturación
	if not SignalBus.package_reached_bottom.is_connected(_on_package_missed):
		SignalBus.package_reached_bottom.connect(_on_package_missed)
	
	# PAQUETE RECOLECTADO → puntuación y combo
	if not SignalBus.package_collected.is_connected(_on_package_collected):
		SignalBus.package_collected.connect(_on_package_collected)
	
	# ORDEN PROCESADA → animaciones
	if SignalBus.has_signal("order_processed"):
		if not SignalBus.order_processed.is_connected(_on_order_processed):
			SignalBus.order_processed.connect(_on_order_processed)


# ------------------------------------------------------------------
# CALLBACKS DE SEÑALES
# ------------------------------------------------------------------

## Cuando el jugador toca un tubo
func _on_tube_tapped(tube_color: String, tube_index: int):
	if not suction_queue or not suction_queue.has_method("add_tube_to_queue"):
		return
	
	suction_queue.add_tube_to_queue(tube_color, tube_index)


## Cuando un paquete es spawneado — conectar su señal de llegada
func _on_package_spawned(package_ref):
	if not package_ref:
		return
	
	# Conectar la señal "reached_suction_zone" del paquete
	if package_ref.has_signal("reached_suction_zone"):
		if not package_ref.reached_suction_zone.is_connected(_on_package_in_suction_zone):
			package_ref.reached_suction_zone.connect(_on_package_in_suction_zone.bind(package_ref))


## Cuando un paquete llega a la zona de succión
func _on_package_in_suction_zone(package_ref):
	if not suction_queue or not suction_queue.has_method("process_next_order"):
		return
	
	if not is_instance_valid(package_ref):
		return
	
	var package_color = package_ref.get_color()
	var result = suction_queue.process_next_order(package_color)
	
	if result.get("matched", false):
		# ÉXITO: recoger paquete
		var order = result.get("order", {})
		var tube_index = order.get("tube_index", 0)
		
		# Buscar el tubo y hacer animación
		if tube_index < _tubes.size():
			var tube = _tubes[tube_index]
			if is_instance_valid(tube) and tube.has_method("play_suction_animation"):
				tube.play_suction_animation()
				tube.clear_order()
		
		# Animar succión del paquete hacia el tubo
		if tube_index < _tubes.size():
			var tube = _tubes[tube_index]
			if is_instance_valid(tube):
				package_ref.play_suck_animation(tube.global_position, func(): pass)
		
		# Actualizar números de orden de los tubos restantes
		_actualizar_numeros_tubos()
	else:
		# ERROR: paquete no coincide
		if package_ref.has_method("play_error_animation"):
			package_ref.play_error_animation()
		
		# Animar error en el tubo correspondiente
		var order = result.get("order", {})
		var tube_index = order.get("tube_index", -1)
		if tube_index >= 0 and tube_index < _tubes.size():
			var tube = _tubes[tube_index]
			if is_instance_valid(tube) and tube.has_method("play_error_animation"):
				tube.play_error_animation()
		
		# Emitir señal de error
		SignalBus.package_error.emit(package_ref)


## Cuando un paquete llega al fondo sin ser recogido
func _on_package_missed(package_ref):
	# Aumentar saturación
	if GameManager:
		GameManager.add_saturation(15.0)


## Cuando un paquete es recolectado correctamente
func _on_package_collected(package_ref, points: int):
	_packages_collected += 1
	
	# Sumar puntos
	if GameManager:
		GameManager.add_score(points)
		GameManager.add_combo()
	
	# Verificar victoria
	if _packages_collected >= _packages_target:
		_victoria()


## Cuando una orden es procesada (acierto o error)
func _on_order_processed(order: Dictionary, _package_ref, success: bool):
	if not success:
		_errors += 1
		if GameManager:
			GameManager.break_combo()


# ------------------------------------------------------------------
# ACTUALIZACIÓN DE TUBOS
# ------------------------------------------------------------------

## Actualiza los números de orden en todos los tubos
func _actualizar_numeros_tubos():
	if not suction_queue or not suction_queue.has_method("get_queue_size"):
		return
	
	var queue = suction_queue.get("_order_queue")
	if queue == null:
		return
	
	for i in range(_tubes.size()):
		var tube = _tubes[i]
		if not is_instance_valid(tube):
			continue
		
		# Buscar si este tubo tiene una orden en la cola
		var order_num = 0
		for j in range(queue.size()):
			if queue[j].get("tube_index", -1) == i:
				order_num = j + 1
				break
		
		if tube.has_method("set_order_number"):
			tube.set_order_number(order_num)


# ------------------------------------------------------------------
# VICTORIA / DERROTA
# ------------------------------------------------------------------

func _victoria():
	if GameManager:
		GameManager.set_last_level_result({
			"level": GameManager.current_level,
			"score": GameManager.score,
			"packages": _packages_collected,
			"target": _packages_target,
			"errors": _errors,
			"max_combo": _max_combo
		})
		GameManager.check_victory()


func _check_defeat():
	if GameManager:
		GameManager.check_defeat()
