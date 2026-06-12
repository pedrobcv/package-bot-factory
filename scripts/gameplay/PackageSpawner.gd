extends Node2D

## PackageSpawner - Generador de paquetes en la cinta transportadora

@export var spawn_interval: float = 3.0
@export var conveyor_speed: float = 80.0
@export var available_colors: Array = ["azul", "amarillo"]
@export var available_types: Array = [0]
@export var is_active: bool = false
@export var max_packages_on_screen: int = 8

var _active_packages: Array = []
const PACKAGE_SCENE_PATH: String = "res://scenes/game/Package.tscn"

@onready var spawn_timer: Timer = $SpawnTimer


func _ready():
	if spawn_timer:
		spawn_timer.wait_time = spawn_interval
		spawn_timer.one_shot = false
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func _process(_delta: float):
	_active_packages = _active_packages.filter(func(pkg): return is_instance_valid(pkg))


func start_spawning():
	if is_active:
		return
	is_active = true
	if spawn_timer:
		spawn_timer.start()


func stop_spawning():
	is_active = false
	if spawn_timer:
		spawn_timer.stop()


func _on_spawn_timer_timeout():
	if not is_active:
		return
	
	if _active_packages.size() >= max_packages_on_screen:
		return
	
	var package = _create_package()
	if not package:
		return
	
	# Añadir como hijo del GameWorld (el padre del spawner) para posiciones globales
	var world = get_parent()
	if world:
		world.add_child(package)
	else:
		add_child(package)
	
	_active_packages.append(package)
	
	# Posición de spawn: centro-arriba, con variación horizontal
	var spawn_x = randf_range(120, 600)
	package.position = Vector2(spawn_x, 80)
	
	package.speed = conveyor_speed
	package.play_spawn_animation()
	
	SignalBus.package_spawned.emit(package)
	
	# Conectar señal de paquete perdido
	if package.has_signal("missed"):
		package.missed.connect(_on_package_missed)


func _create_package():
	var scene = load(PACKAGE_SCENE_PATH)
	if not scene:
		return null
	
	var pkg = scene.instantiate()
	if not pkg:
		return null

	var color = get_random_color()
	var ptype = get_random_type()
	var spd = conveyor_speed
	var pts = 10
	
	if ptype == 1:  # GOLDEN
		pts = 50
	elif ptype == 3:  # FAST
		spd = conveyor_speed * 1.5
	elif ptype == 4:  # HEAVY
		spd = conveyor_speed * 0.5
	
	if pkg.has_method("set_config"):
		pkg.set_config(color, ptype, spd, pts)
	
	return pkg


func _on_package_missed(package_ref):
	SignalBus.package_reached_bottom.emit(package_ref)
	_active_packages.erase(package_ref)


func configure_from_level(level_data: Dictionary):
	if level_data.has("spawn_interval"):
		spawn_interval = level_data.spawn_interval
		if spawn_timer:
			spawn_timer.wait_time = spawn_interval
	
	if level_data.has("conveyor_speed"):
		conveyor_speed = level_data.conveyor_speed
	
	if level_data.has("available_colors"):
		available_colors = level_data.available_colors.duplicate()
	
	if level_data.has("available_package_types"):
		available_types = level_data.available_package_types.duplicate()


func get_random_color() -> String:
	if available_colors.is_empty():
		return "azul"
	return available_colors[randi() % available_colors.size()]


func get_random_type() -> int:
	if available_types.is_empty():
		return 0
	return available_types[randi() % available_types.size()]
