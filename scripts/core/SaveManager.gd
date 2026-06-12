extends Node

## SaveManager - Gestor de guardado y carga de progreso
##
## Autoload que maneja el guardado y carga del progreso del jugador
## usando ConfigFile de Godot. Almacena niveles desbloqueados,
## puntuaciones máximas por nivel y preferencias de audio.
##
## Los datos se persisten en user://package_bot_factory.cfg
##
## Registrado como "SaveManager" en Project Settings > Autoload.

# ------------------- Constantes -------------------

## Nombre del archivo de guardado
const SAVE_FILE_NAME: String = "package_bot_factory.cfg"

## Sección de configuración general en el archivo
const SECTION_PROGRESS: String = "progress"

## Sección de puntuaciones máximas
const SECTION_HIGH_SCORES: String = "high_scores"

## Sección de configuración de audio
const SECTION_SETTINGS: String = "settings"

# ------------------- Variables de datos -------------------

## Datos de guardado en memoria
## Se cargan al iniciar y se persisten al llamar save_game()
var save_data: Dictionary = {
	"unlocked_levels": 1,
	"high_scores": {},
	"settings": {
		"music_volume": 0.8,
		"sfx_volume": 1.0
	}
}

## Referencia al archivo de configuración interno
var _config_file: ConfigFile


# ==================================================================
# Funciones del ciclo de vida
# ==================================================================

func _ready() -> void:
	_config_file = ConfigFile.new()
	load_game()


# ==================================================================
# Funciones principales de guardado/carga
# ==================================================================

## Guarda todos los datos del juego en el archivo de configuración
##
## Escribe las secciones de progreso, puntuaciones máximas
## y preferencias en user://package_bot_factory.cfg
func save_game() -> void:
	if _config_file == null:
		push_error("SaveManager: ConfigFile no inicializado")
		return
	
	# Guardar progreso de niveles
	_config_file.set_value(SECTION_PROGRESS, "unlocked_levels", save_data.unlocked_levels)
	
	# Guardar puntuaciones máximas
	var high_scores = save_data.get("high_scores", {})
	for level_key in high_scores:
		_config_file.set_value(SECTION_HIGH_SCORES, str(level_key), high_scores[level_key])
	
	# Guardar configuración
	var settings = save_data.get("settings", {})
	for setting_key in settings:
		_config_file.set_value(SECTION_SETTINGS, setting_key, settings[setting_key])
	
	# Escribir a disco
	var error = _config_file.save("user://" + SAVE_FILE_NAME)
	if error != OK:
		push_error("SaveManager: Error al guardar (código ", error, ")")


## Carga todos los datos del juego desde el archivo de configuración
##
## Si el archivo no existe, se mantienen los valores por defecto.
## Si existe, se leen y se fusionan con save_data.
func load_game() -> void:
	if _config_file == null:
		push_error("SaveManager: ConfigFile no inicializado")
		return
	
	# Verificar si existe el archivo
	var file_path = "user://" + SAVE_FILE_NAME
	if not FileAccess.file_exists(file_path):
		# No hay datos guardados aún, usar valores por defecto
		return
	
	# Cargar desde disco
	var error = _config_file.load(file_path)
	if error != OK:
		push_error("SaveManager: Error al cargar (código ", error, ")")
		return
	
	# Cargar progreso de niveles
	if _config_file.has_section(SECTION_PROGRESS):
		var unlocked = _config_file.get_value(SECTION_PROGRESS, "unlocked_levels", 1)
		save_data.unlocked_levels = unlocked
	
	# Cargar puntuaciones máximas
	if _config_file.has_section(SECTION_HIGH_SCORES):
		var loaded_scores = {}
		var keys = _config_file.get_section_keys(SECTION_HIGH_SCORES)
		for key in keys:
			var level_num = int(key)
			loaded_scores[level_num] = _config_file.get_value(SECTION_HIGH_SCORES, key, 0)
		save_data.high_scores = loaded_scores
	
	# Cargar configuración
	if _config_file.has_section(SECTION_SETTINGS):
		var settings = save_data.get("settings", {})
		var setting_keys = _config_file.get_section_keys(SECTION_SETTINGS)
		for key in setting_keys:
			settings[key] = _config_file.get_value(SECTION_SETTINGS, key, settings.get(key))
		save_data.settings = settings


# ==================================================================
# Funciones de manipulación de datos
# ==================================================================

## Desbloquea un nivel específico
##
## Solo actualiza si el nivel proporcionado es mayor al
## máximo actualmente desbloqueado.
##
## @param level_num: int - Número de nivel a desbloquear
func unlock_level(level_num: int) -> void:
	if level_num > save_data.unlocked_levels:
		save_data.unlocked_levels = level_num


## Guarda la puntuación máxima de un nivel
##
## Solo actualiza si la nueva puntuación es mayor que la existente.
##
## @param level_num: int - Número del nivel
## @param score: int - Puntuación obtenida
## @return: int - La puntuación máxima actual para ese nivel
func save_high_score(level_num: int, score: int) -> int:
	var current_high = get_high_score(level_num)
	
	if score > current_high:
		save_data.high_scores[level_num] = score
		return score
	
	return current_high


## Obtiene la puntuación máxima de un nivel específico
## @param level_num: int - Número del nivel
## @return: int - Puntuación máxima guardada, 0 si no hay registro
func get_high_score(level_num: int) -> int:
	return save_data.high_scores.get(level_num, 0)


## Actualiza una preferencia de configuración
##
## @param key: String - Clave de la configuración (ej: "music_volume")
## @param value: Mixed - Valor a asignar
func update_setting(key: String, value) -> void:
	if not save_data.has("settings"):
		save_data.settings = {}
	
	save_data.settings[key] = value


## Reinicia todos los datos guardados a sus valores por defecto
##
## Borra el archivo de guardado y restaura save_data.
## Útil para depuración o para la opción "Nuevo juego".
func reset_all_data() -> void:
	# Restaurar valores por defecto
	save_data = {
		"unlocked_levels": 1,
		"high_scores": {},
		"settings": {
			"music_volume": 0.8,
			"sfx_volume": 1.0
		}
	}
	
	# Eliminar archivo de guardado
	var file_path = "user://" + SAVE_FILE_NAME
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
	
	# Guardar datos por defecto
	save_game()
