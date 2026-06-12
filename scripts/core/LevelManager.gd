extends Node

## LevelManager - Gestor de niveles y configuración
##
## Autoload que se encarga de cargar, validar y proveer la
## configuración de cada nivel. Los niveles se almacenan como
## recursos .tres en res://resources/levels/ y contienen
## parámetros como velocidad de cinta, colores disponibles,
## tipos de paquetes y límites del nivel.
##
## Registrado como "LevelManager" en Project Settings > Autoload.

# ------------------- Señales -------------------

## Se emite cuando un nivel ha sido cargado exitosamente
## @param level_num: int - Número de nivel cargado
## @param level_data: Dictionary - Configuración del nivel
signal level_loaded(level_num: int, level_data: Dictionary)

## Se emite cuando ocurre un error al cargar un nivel
## @param level_num: int - Número de nivel que falló
signal level_load_error(level_num: int)

# ------------------- Constantes de ruta -------------------

## Ruta base donde se almacenan los recursos de niveles
const LEVELS_PATH: String = "res://resources/levels/"

## Prefijo del archivo de nivel
const LEVEL_FILE_PREFIX: String = "level_"

## Extensión del archivo de nivel
const LEVEL_FILE_EXTENSION: String = ".tres"

# ------------------- Datos por defecto para cada nivel -------------------
## Configuración predefinida para niveles 1 al 10
## Si no existe un archivo .tres, se usan estos valores por defecto
const DEFAULT_LEVELS: Dictionary = {
	1: {
		"level_number": 1,
		"target_packages": 10,
		"conveyor_speed": 40.0,
		"spawn_interval": 3.0,
		"available_colors": ["azul", "rojo"],
		"available_package_types": [Constants.PackageType.NORMAL],
		"available_powerups": [],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 2,
		"allow_order_cancel": false,
		"difficulty_multiplier": 1.0
	},
	2: {
		"level_number": 2,
		"target_packages": 15,
		"conveyor_speed": 45.0,
		"spawn_interval": 2.8,
		"available_colors": ["azul", "rojo", "verde"],
		"available_package_types": [Constants.PackageType.NORMAL],
		"available_powerups": [],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 2,
		"allow_order_cancel": false,
		"difficulty_multiplier": 1.1
	},
	3: {
		"level_number": 3,
		"target_packages": 20,
		"conveyor_speed": 50.0,
		"spawn_interval": 2.5,
		"available_colors": ["azul", "rojo", "verde", "amarillo"],
		"available_package_types": [Constants.PackageType.NORMAL],
		"available_powerups": [],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 3,
		"allow_order_cancel": false,
		"difficulty_multiplier": 1.2
	},
	4: {
		"level_number": 4,
		"target_packages": 25,
		"conveyor_speed": 55.0,
		"spawn_interval": 2.5,
		"available_colors": ["azul", "rojo", "verde", "amarillo"],
		"available_package_types": [Constants.PackageType.NORMAL, Constants.PackageType.FAST],
		"available_powerups": [],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 3,
		"allow_order_cancel": false,
		"difficulty_multiplier": 1.3
	},
	5: {
		"level_number": 5,
		"target_packages": 28,
		"conveyor_speed": 60.0,
		"spawn_interval": 2.2,
		"available_colors": ["azul", "rojo", "verde", "amarillo"],
		"available_package_types": [Constants.PackageType.NORMAL, Constants.PackageType.FAST, Constants.PackageType.HEAVY],
		"available_powerups": [],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 3,
		"allow_order_cancel": false,
		"difficulty_multiplier": 1.4
	},
	6: {
		"level_number": 6,
		"target_packages": 30,
		"conveyor_speed": 65.0,
		"spawn_interval": 2.0,
		"available_colors": ["azul", "rojo", "verde", "amarillo", "morado"],
		"available_package_types": [Constants.PackageType.NORMAL, Constants.PackageType.FAST, Constants.PackageType.HEAVY],
		"available_powerups": ["slow_time"],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 4,
		"allow_order_cancel": true,
		"difficulty_multiplier": 1.5
	},
	7: {
		"level_number": 7,
		"target_packages": 32,
		"conveyor_speed": 70.0,
		"spawn_interval": 1.8,
		"available_colors": ["azul", "rojo", "verde", "amarillo", "morado"],
		"available_package_types": [Constants.PackageType.NORMAL, Constants.PackageType.FAST, Constants.PackageType.HEAVY, Constants.PackageType.GOLDEN],
		"available_powerups": ["slow_time", "extra_life"],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 4,
		"allow_order_cancel": true,
		"difficulty_multiplier": 1.6
	},
	8: {
		"level_number": 8,
		"target_packages": 35,
		"conveyor_speed": 75.0,
		"spawn_interval": 1.6,
		"available_colors": ["azul", "rojo", "verde", "amarillo", "morado"],
		"available_package_types": [Constants.PackageType.NORMAL, Constants.PackageType.FAST, Constants.PackageType.HEAVY, Constants.PackageType.GOLDEN, Constants.PackageType.BOMB],
		"available_powerups": ["slow_time", "extra_life", "shield"],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 4,
		"allow_order_cancel": true,
		"difficulty_multiplier": 1.7
	},
	9: {
		"level_number": 9,
		"target_packages": 38,
		"conveyor_speed": 80.0,
		"spawn_interval": 1.5,
		"available_colors": ["azul", "rojo", "verde", "amarillo", "morado"],
		"available_package_types": [Constants.PackageType.NORMAL, Constants.PackageType.FAST, Constants.PackageType.HEAVY, Constants.PackageType.GOLDEN, Constants.PackageType.BOMB, Constants.PackageType.FROZEN],
		"available_powerups": ["slow_time", "extra_life", "shield", "clear_queue"],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 5,
		"allow_order_cancel": true,
		"difficulty_multiplier": 1.8
	},
	10: {
		"level_number": 10,
		"target_packages": 40,
		"conveyor_speed": 85.0,
		"spawn_interval": 1.3,
		"available_colors": ["azul", "rojo", "verde", "amarillo", "morado"],
		"available_package_types": [Constants.PackageType.NORMAL, Constants.PackageType.FAST, Constants.PackageType.HEAVY, Constants.PackageType.GOLDEN, Constants.PackageType.BOMB, Constants.PackageType.FROZEN],
		"available_powerups": ["slow_time", "extra_life", "shield", "clear_queue", "magnet"],
		"max_lives": 3,
		"max_saturation": 100.0,
		"max_queue_size": 5,
		"allow_order_cancel": true,
		"difficulty_multiplier": 2.0
	}
}


# ==================================================================
# Funciones principales
# ==================================================================

## Carga la configuración de un nivel específico
##
## Intenta cargar desde un archivo .tres en resources/levels/.
## Si no existe el archivo, usa los valores por defecto definidos
## en DEFAULT_LEVELS.
##
## @param level_num: int - Número de nivel a cargar (1-10)
## @return: Dictionary - Configuración completa del nivel.
##          Diccionario vacío si el nivel no existe.
func load_level(level_num: int) -> Dictionary:
	# Validar rango del nivel
	if level_num < 1 or level_num > get_level_count():
		push_error("LevelManager: Nivel ", level_num, " fuera de rango (1-", get_level_count(), ")")
		level_load_error.emit(level_num)
		return {}
	
	# Intentar cargar desde archivo .tres
	var file_path = LEVELS_PATH + LEVEL_FILE_PREFIX + str(level_num) + LEVEL_FILE_EXTENSION
	var level_data = _try_load_resource(file_path)
	
	# Si no se pudo cargar el recurso, usar valores por defecto
	if level_data.is_empty():
		level_data = _get_default_level_data(level_num)
		if level_data.is_empty():
			level_load_error.emit(level_num)
			return {}
	
	# Validar datos del nivel
	if not _validate_level_data(level_data):
		push_error("LevelManager: Datos inválidos en nivel ", level_num)
		level_load_error.emit(level_num)
		return {}
	
	level_loaded.emit(level_num, level_data)
	return level_data


## Obtiene el número total de niveles disponibles
## @return: int - Cantidad de niveles (10)
func get_level_count() -> int:
	return DEFAULT_LEVELS.size()


## Verifica si un nivel está desbloqueado para el jugador
## @param level_num: int - Número de nivel a verificar
## @return: bool - true si el nivel está desbloqueado
func is_level_unlocked(level_num: int) -> bool:
	if level_num <= 1:
		return true
	
	# Consultar datos guardados
	var unlocked = 1
	if SaveManager:
		unlocked = SaveManager.save_data.get("unlocked_levels", 1)
	
	return level_num <= unlocked


# ==================================================================
# Funciones auxiliares privadas
# ==================================================================

## Intenta cargar un recurso desde disco
## @param path: String - Ruta completa al archivo .tres
## @return: Dictionary - Datos del nivel o diccionario vacío si falla
func _try_load_resource(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	
	var resource = ResourceLoader.load(path)
	if resource == null:
		return {}
	
	# Convertir recurso a Dictionary
	var data = {}
	if resource.has_method("get_data"):
		data = resource.get_data()
	
	return data


## Obtiene los datos por defecto para un nivel
## @param level_num: int - Número de nivel
## @return: Dictionary - Datos del nivel o diccionario vacío
func _get_default_level_data(level_num: int) -> Dictionary:
	if DEFAULT_LEVELS.has(level_num):
		return DEFAULT_LEVELS[level_num].duplicate(true)
	
	return {}


## Valida que los datos del nivel contengan todos los campos requeridos
## @param data: Dictionary - Datos a validar
## @return: bool - true si los datos son válidos
func _validate_level_data(data: Dictionary) -> bool:
	var required_fields = [
		"level_number",
		"target_packages",
		"conveyor_speed",
		"spawn_interval",
		"available_colors",
		"available_package_types",
		"available_powerups",
		"max_lives",
		"max_saturation",
		"max_queue_size",
		"allow_order_cancel",
		"difficulty_multiplier"
	]
	
	for field in required_fields:
		if not data.has(field):
			push_error("LevelManager: Falta el campo '", field, "' en los datos del nivel")
			return false
	
	return true
