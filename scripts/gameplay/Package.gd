extends Area2D

## Package - Paquete individual
##
## Representa un paquete que viaja por la cinta transportadora.
## Puede ser de diferentes colores y tipos, y debe coincidir
## con la orden del tubo para ser recolectado correctamente.
##
## Conexiones requeridas en el árbol de escena:
## - CollisionShape2D como hijo
## - Area2D para detectar la zona de succión (opcional)
##
## Señales emitidas:
## - reached_suction_zone(package_ref): Cuando llega a la zona de succión
## - collected(package_ref): Cuando es recolectado exitosamente
## - missed(package_ref): Cuando llega al fondo sin ser recolectado

signal reached_suction_zone(package_ref)
signal collected(package_ref)
signal missed(package_ref)

# ------------------- Mapa de colores -------------------
const PACKAGE_COLORS: Dictionary = {
	"azul": Color("#3498db"),
	"amarillo": Color("#f1c40f"),
	"rojo": Color("#e74c3c"),
	"verde": Color("#2ecc71"),
	"morado": Color("#9b59b6")
}

# ------------------- Variables exportadas -------------------
## Color del paquete (clave del mapa PACKAGE_COLORS)
@export var package_color: String = "azul"
## Tipo de paquete (PackageType.NORMAL, etc.)
@export var package_type: int = 0
## Velocidad de movimiento vertical del paquete
@export var speed: float = 100.0
## Puntos que otorga al ser recolectado
@export var points: int = 10
## Penalización por error
@export var penalty: int = 0
## Si puede ser succionado por los tubos
@export var can_be_sucked: bool = true
## Si requiere coincidencia exacta de color
@export var requires_exact_match: bool = true
## Duración del efecto congelado (0 = sin congelar)
@export var frozen_duration: float = 0.0

# ------------------- Variables internas -------------------
## Color actual del paquete
var _current_color: Color = Color("#3498db")
## Tamaño del paquete en píxeles
var _package_size: float = 30.0
## Si está siendo succionado (animación en curso)
var _is_being_sucked: bool = false
## Temporizador de error visual
var _error_timer: float = 0.0
## Temporizador de congelamiento
var _frozen_timer: float = 0.0
## Offset vertical para spawn animado
var _spawn_offset: float = 0.0
## Si ya pasó por la zona de succión
var _has_entered_suction_zone: bool = false

## Referencia al CollisionShape2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready():
	## Configurar apariencia, color y tipo según variables exportadas
	_current_color = PACKAGE_COLORS.get(package_color, Color("#3498db"))
	
	# Configurar shape de colisión
	if collision_shape and collision_shape.shape == null:
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(_package_size, _package_size)
		collision_shape.shape = rect_shape
	
	# Posición inicial con offset para animación de spawn
	_spawn_offset = -30.0
	
	queue_redraw()


func _process(delta: float):
	## Movimiento vertical hacia abajo por la cinta
	
	# Si está congelado, no se mueve
	if _frozen_timer > 0:
		_frozen_timer -= delta
		return
	
	# Si está siendo succionado, no se mueve por la cinta
	if _is_being_sucked:
		return
	
	# Animación de spawn (rebote)
	if _spawn_offset < 0:
		_spawn_offset = lerp(_spawn_offset, 0.0, delta * 15.0)
		if abs(_spawn_offset) < 0.5:
			_spawn_offset = 0.0
	else:
		# Movimiento normal hacia abajo
		position.y += speed * delta
	
	# Animación de error (temblor)
	if _error_timer > 0:
		_error_timer -= delta
		position.x += randf_range(-2.0, 2.0)
		queue_redraw()
	
	# Verificar si entró en zona de succión (cerca de los tubos, ~y=950)
	if not _has_entered_suction_zone and position.y > 900:
		_has_entered_suction_zone = true
		reached_suction_zone.emit(self)
	
	# Verificar si llegó al fondo (fuera de pantalla, altura 1280)
	if position.y > 1200:
		missed.emit(self)
		queue_free()


func _draw():
	## Dibujar cuadrado de color con borde
	
	# Tamaño efectivo con offset de spawn
	var draw_size = _package_size + _spawn_offset
	
	if draw_size <= 0:
		return
	
	var half_size = draw_size / 2
	var rect = Rect2(-half_size, -half_size, draw_size, draw_size)
	
	# Color base
	var color_to_use = _current_color
	
	# Si está en error, flash rojo
	if _error_timer > 0:
		color_to_use = Color("#e74c3c")
	
	# Fondo
	draw_rect(rect, color_to_use)
	
	# Borde
	draw_rect(rect, color_to_use.darkened(0.3), false, 2.0)
	
	# Si es dorado, dibujar brillo
	if package_type == 1:  # PackageType.GOLDEN
		var inner_rect = Rect2(-half_size + 4, -half_size + 4, draw_size - 8, draw_size - 8)
		draw_rect(inner_rect, Color(1, 1, 0.5, 0.3))
	
	# Si es bomba, dibujar símbolo
	if package_type == 2:  # PackageType.BOMB
		draw_circle(Vector2.ZERO, draw_size * 0.2, Color(1, 0, 0, 0.5))


## Configura las propiedades del paquete
func set_config(color: String, type: int, spd: float, pts: int):
	package_color = color
	package_type = type
	speed = spd
	points = pts
	_current_color = PACKAGE_COLORS.get(color, Color("#3498db"))
	queue_redraw()


## Retorna el color del paquete
func get_color() -> String:
	return package_color


## Retorna el tipo del paquete
func get_type() -> int:
	return package_type


## Animación de succión: moverse a target y encogerse
## @param target_pos: Vector2 - Posición objetivo (tubo)
## @param callback: Callable - Función a llamar al completar
func play_suck_animation(target_pos: Vector2, callback: Callable):
	if _is_being_sucked:
		return
	
	_is_being_sucked = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Moverse al objetivo
	tween.tween_property(self, "position", target_pos, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	# Encogerse
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# Desvanecer
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	
	await tween.finished
	
	collected.emit(self)
	SignalBus.package_collected.emit(self, points)
	
	if callback:
		callback.call()
	
	queue_free()


## Animación de error: tiembla y flash rojo
func play_error_animation():
	_error_timer = 0.5
	modulate = Color(1, 0.5, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	_error_timer = 0.0
	modulate = Color(1, 1, 1)
	queue_redraw()


## Animación de spawn: rebote al aparecer
func play_spawn_animation():
	_spawn_offset = -30.0
	scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## Verifica si el paquete está en la zona de succión
func is_in_suction_zone() -> bool:
	return _has_entered_suction_zone
