extends Node2D

## PackageSpawner - Generador de paquetes
##
## Crea nuevos paquetes en intervalos regulares.
## Se configura desde los datos del nivel (LevelManager).
## Los paquetes aparecen en la parte superior de la cinta
## y caen hacia abajo.
##
## Señales del SignalBus utilizadas:
## - package_spawned(package_ref)

signal package_spawned(package_ref)

# ------------------- Variables exportadas -------------------
## Intervalo entre spawns en segundos
@export var spawn_interval: float = 2.0
## Velocidad de los paquetes en la cinta
@export var conveyor_speed: float = 100.0
## Colores disponibles para generar (claves del mapa de colores)
@export var available_colors: Array = ["azul", "amarillo"]
## Tipos disponibles para generar (PackageType)
@export var available_types: Array = [0]
## Si el spawner está activo
@export var is_active: bool = false
## Máximo de paquetes simultáneos en pantalla
@export var max_packages_on_screen: int = 8

# ------------------- Variables internas -------------------
## Paquetes activos en pantalla
var _active_packages: Array = []
## Ruta base para instanciar paquetes
const PACKAGE_SCENE_PATH: String = "res://scenes/gameplay/Package.tscn"

## Timer para intervalo de spawn
@onready var spawn_timer: Timer = $SpawnTimer
## Punto de spawn
@onready var spawn_point: Marker2D = $SpawnPoint


func _ready():
	## Inicializar el spawner
	if spawn_timer:
		spawn_timer.wait_time = spawn_interval
		spawn_timer.one_shot = false
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func _process(_delta: float):
	## Limpiar referencias a paquetes eliminados
	_active_packages = _active_packages.filter(func(pkg): return is_instance_valid(pkg))


## Inicia la generación de paquetes
func start_spawning():
	if is_active:
		return
	
	is_active = true
	
	if spawn_timer:
		spawn_timer.start()


## Detiene la generación de paquetes
func stop_spawning():
	is_active = false
	
	if spawn_timer:
		spawn_timer.stop()


## Crea un nuevo paquete cuando el timer llega a cero
func _on_spawn_timer_timeout():
	if not is_active:
		return
	
	# Verificar límite de paquetes en pantalla
	if _active_packages.size() >= max_packages_on_screen:
		return
	
	# Crear nuevo paquete
	var package = _create_package()
	if package:
		add_child(package)
		_active_packages.append(package)
		
		# Posicionar en el punto de spawn
		if spawn_point:
			package.position = spawn_point.position
		else:
			package.position = Vector2(0, -100)
		
		# Configurar velocidad
		package.speed = conveyor_speed
		
		# Reproducir animación de aparición
		package.play_spawn_animation()
		
		# Emitir señales
		package_spawned.emit(package)
		SignalBus.package_spawned.emit(package)
		
		# Conectar señal de que llegó al fondo
		package.missed.connect(_on_package_missed.bind(package))


## Crea una instancia de Package con configuración aleatoria
func _create_package():
	# En lugar de instanciar desde escena (que no existe aún),
	# creamos el nodo directamente si no hay escena
	
	var package = load("res://scripts/gameplay/Package.gd")
	if not package:
		return null
	
	# Crear instancia del script
	var package_instance = load("res://scripts/gameplay/Package.gd").new()
	
	if not package_instance:
		return null
	
	# Configurar propiedades aleatorias
	var color = get_random_color()
	var ptype = get_random_type()
	var spd = conveyor_speed
	var pts = 10
	
	# Ajustar según tipo
	if ptype == 1:  # GOLDEN
		pts = 50
	elif ptype == 3:  # FAST
		spd = conveyor_speed * 1.5
	elif ptype == 4:  # HEAVY
		spd = conveyor_speed * 0.7
	
	package_instance.set_config(color, ptype, spd, pts)
	
	return package_instance


## Evento cuando un paquete llega al fondo
func _on_package_missed(package):
	SignalBus.package_reached_bottom.emit(package)


## Configura el spawner desde datos del nivel
## @param level_data: Dictionary - Datos del nivel
func configure_from_level(level_data: Dictionary):
	if level_data.has("spawn_interval"):
		spawn_interval = level_data.spawn_interval
		if spawn_timer:
			spawn_timer.wait_time = spawn_interval
	
	if level_data.has("conveyor_speed"):
		conveyor_speed = level_data.conveyor_speed
	
	if level_data.has("colors"):
		available_colors = level_data.colors.duplicate()
	
	if level_data.has("types"):
		available_types = level_data.types.duplicate()
	
	if level_data.has("max_packages"):
		max_packages_on_screen = level_data.max_packages


## Retorna un color aleatorio de la lista disponible
func get_random_color() -> String:
	if available_colors.is_empty():
		return "azul"
	return available_colors[randi() % available_colors.size()]


## Retorna un tipo de paquete aleatorio de la lista disponible
func get_random_type() -> int:
	if available_types.is_empty():
		return 0
	return available_types[randi() % available_types.size()]
