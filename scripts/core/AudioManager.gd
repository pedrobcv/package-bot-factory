extends Node

## AudioManager - Gestor de audio del juego
##
## Autoload que maneja la reproducción de efectos de sonido (SFX)
## y música de fondo. Los sonidos se cargan desde rutas predefinidas
## en res://assets/audio/ y se reproducen mediante nodos
## AudioStreamPlayer2D (para SFX posicionales) y AudioStreamPlayer
## (para música).
##
## Registrado como "AudioManager" en Project Settings > Autoload.

# ------------------- Constantes de rutas -------------------

## Ruta base para los efectos de sonido
const SFX_PATH: String = "res://assets/audio/sfx/"

## Ruta base para la música
const MUSIC_PATH: String = "res://assets/audio/music/"

## Formato de audio esperado (OGG Vorbis)
const AUDIO_EXTENSION: String = ".ogg"

# ------------------- Referencias @onready -------------------

## Reproductor de efectos de sonido (2D para posicionamiento espacial)
@onready var sfx_player: AudioStreamPlayer2D = _create_sfx_player()

## Reproductor de música de fondo (estéreo, no posicional)
@onready var music_player: AudioStreamPlayer = _create_music_player()

# ------------------- Caché de sonidos -------------------

## Caché de streams cargados para evitar recargas
var _sfx_cache: Dictionary = {}

## Caché de streams de música
var _music_cache: Dictionary = {}

## Nombre de la canción actualmente en reproducción
var _current_music: String = ""


# ==================================================================
# Funciones de inicialización
# ==================================================================

## Crea y configura el reproductor de efectos de sonido
## @return: AudioStreamPlayer2D - Reproductor configurado
func _create_sfx_player() -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.name = "SFXPlayer"
	player.bus = "SFX"
	add_child(player)
	return player


## Crea y configura el reproductor de música
## @return: AudioStreamPlayer - Reproductor configurado
func _create_music_player() -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.name = "MusicPlayer"
	player.bus = "Music"
	add_child(player)
	return player


# ==================================================================
# Funciones de reproducción de SFX
# ==================================================================

## Reproduce un efecto de sonido por su nombre
##
## Busca el archivo en res://assets/audio/sfx/<nombre>.ogg
## Si el archivo no existe, muestra una advertencia sin fallar.
##
## @param sfx_name: String - Nombre del efecto (sin extensión)
func play_sfx(sfx_name: String) -> void:
	var stream = _get_sfx_stream(sfx_name)
	if stream == null:
		push_warning("AudioManager: SFX no encontrado: ", sfx_name)
		return
	
	sfx_player.stream = stream
	sfx_player.play()


## Reproduce un efecto de sonido en una posición específica del mundo
##
## @param sfx_name: String - Nombre del efecto
## @param position: Vector2 - Posición global donde reproducir el sonido
func play_sfx_at_position(sfx_name: String, position: Vector2) -> void:
	var stream = _get_sfx_stream(sfx_name)
	if stream == null:
		push_warning("AudioManager: SFX no encontrado: ", sfx_name)
		return
	
	sfx_player.stream = stream
	sfx_player.global_position = position
	sfx_player.play()


# ==================================================================
# Funciones de reproducción de música
# ==================================================================

## Reproduce una pista de música por su nombre
##
## Si ya está sonando la misma pista, no hace nada.
## Busca el archivo en res://assets/audio/music/<nombre>.ogg
##
## @param music_name: String - Nombre de la pista (sin extensión)
func play_music(music_name: String) -> void:
	# No reiniciar si ya está sonando la misma canción
	if _current_music == music_name and music_player.playing:
		return
	
	var stream = _get_music_stream(music_name)
	if stream == null:
		push_warning("AudioManager: Música no encontrada: ", music_name)
		return
	
	music_player.stream = stream
	music_player.play()
	_current_music = music_name


## Detiene la reproducción de música actual
func stop_music() -> void:
	if music_player.playing:
		music_player.stop()
	_current_music = ""


## Pausa o reanuda la música actual
## @param paused: bool - true para pausar, false para reanudar
func set_music_paused(paused: bool) -> void:
	music_player.stream_paused = paused


# ==================================================================
# Funciones de control de volumen
# ==================================================================

## Establece el volumen de los efectos de sonido
##
## @param vol: float - Volumen en escala lineal (0.0 = silencio, 1.0 = máximo).
##                     Se convierte a decibelios internamente.
func set_sfx_volume(vol: float) -> void:
	var db_value = linear_to_db(clamp(vol, 0.0, 1.0))
	
	# Si el reproductor está en el árbol, ajustar su volumen
	if is_instance_valid(sfx_player):
		sfx_player.volume_db = db_value
	
	# Guardar preferencia
	if SaveManager:
		SaveManager.update_setting("sfx_volume", vol)
		SaveManager.save_game()


## Establece el volumen de la música de fondo
##
## @param vol: float - Volumen en escala lineal (0.0 = silencio, 1.0 = máximo).
##                     Se convierte a decibelios internamente.
func set_music_volume(vol: float) -> void:
	var db_value = linear_to_db(clamp(vol, 0.0, 1.0))
	
	if is_instance_valid(music_player):
		music_player.volume_db = db_value
	
	# Guardar preferencia
	if SaveManager:
		SaveManager.update_setting("music_volume", vol)
		SaveManager.save_game()


## Obtiene el volumen actual de SFX
## @return: float - Volumen en escala lineal (0.0 - 1.0)
func get_sfx_volume() -> float:
	if SaveManager:
		return SaveManager.save_data.get("settings", {}).get("sfx_volume", 1.0)
	return 1.0


## Obtiene el volumen actual de música
## @return: float - Volumen en escala lineal (0.0 - 1.0)
func get_music_volume() -> float:
	if SaveManager:
		return SaveManager.save_data.get("settings", {}).get("music_volume", 0.8)
	return 0.8


# ==================================================================
# Funciones auxiliares privadas
# ==================================================================

## Obtiene o carga un stream de audio SFX desde la caché
##
## @param name: String - Nombre del archivo de audio
## @return: AudioStream - Stream de audio, o null si no existe
func _get_sfx_stream(name: String) -> AudioStream:
	# Revisar caché primero
	if _sfx_cache.has(name):
		return _sfx_cache[name]
	
	# Construir ruta y verificar existencia
	var path = SFX_PATH + name + AUDIO_EXTENSION
	if not ResourceLoader.exists(path):
		# Intentar sin extensión por si usa .mp3
		path = SFX_PATH + name + ".mp3"
		if not ResourceLoader.exists(path):
			return null
	
	# Cargar y cachear
	var stream = ResourceLoader.load(path)
	if stream:
		_sfx_cache[name] = stream
	
	return stream


## Obtiene o carga un stream de audio de música desde la caché
##
## @param name: String - Nombre del archivo de audio
## @return: AudioStream - Stream de audio, o null si no existe
func _get_music_stream(name: String) -> AudioStream:
	# Revisar caché primero
	if _music_cache.has(name):
		return _music_cache[name]
	
	# Construir ruta y verificar existencia
	var path = MUSIC_PATH + name + AUDIO_EXTENSION
	if not ResourceLoader.exists(path):
		# Intentar sin extensión por si usa .mp3
		path = MUSIC_PATH + name + ".mp3"
		if not ResourceLoader.exists(path):
			return null
	
	# Cargar y cachear
	var stream = ResourceLoader.load(path)
	if stream:
		_music_cache[name] = stream
	
	return stream
