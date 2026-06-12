extends Area2D

## SuctionTube - Tubo de succión individual
##
## Representa un tubo de succión donde el jugador puede
## colocar órdenes tocándolo. Se dibuja como un rectángulo
## redondeado con el color correspondiente y un número
## de orden encima.
##
## Conexiones requeridas en el árbol de escena:
## - CollisionShape2D como hijo
## - Label como hijo (para número de orden)
##
## Señales del SignalBus utilizadas:
## - tube_tapped(tube_color, tube_index)

# ------------------- Mapa de colores -------------------
const TUBE_COLORS: Dictionary = {
	"azul": Color("#3498db"),
	"amarillo": Color("#f1c40f"),
	"rojo": Color("#e74c3c"),
	"verde": Color("#2ecc71"),
	"morado": Color("#9b59b6")
}

# ------------------- Variables exportadas -------------------
## Color del tubo (clave del mapa TUBE_COLORS)
@export var tube_color: String = "azul"
## Índice del tubo (posición en la escena)
@export var tube_index: int = 0
## Número de orden (0 = sin orden)
@export var order_number: int = 0
## Si el tubo está seleccionado (animación brillante)
@export var is_selected: bool = false
## Si el tubo está bloqueado (no puede recibir órdenes)
@export var is_blocked: bool = false
## Ancho del tubo en píxeles
@export var tube_width: float = 70.0
## Alto del tubo en píxeles
@export var tube_height: float = 120.0

# ------------------- Variables internas -------------------
## Color actual del tubo
var _current_color: Color = Color("#3498db")
## Temporizador para animación de error
var _error_timer: float = 0.0
## Factor de escala para animación de succión
var _suck_scale: float = 1.0
## Factor de brillo para selección
var _select_brightness: float = 0.0

## Referencia al CollisionShape2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## Referencia al Label para el número de orden
@onready var order_label: Label = $OrderLabel


func _ready():
	## Configurar área táctil y apariencia inicial
	_current_color = TUBE_COLORS.get(tube_color, Color("#3498db"))
	
	# Conectar señal de entrada
	input_event.connect(_on_input_event)
	
	# Configurar shape de colisión
	if collision_shape and collision_shape.shape == null:
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(tube_width, tube_height)
		collision_shape.shape = rect_shape
	
	# Configurar label de orden
	if order_label:
		order_label.text = str(order_number) if order_number > 0 else ""
		order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		order_label.position = Vector2(-20, -tube_height / 2 - 25)
		order_label.size = Vector2(40, 30)
		order_label.add_theme_font_size_override("font_size", 20)
	
	queue_redraw()


func _draw():
	## Dibujar el tubo como rectángulo redondeado con color
	
	var color_to_use: Color = _current_color
	
	# Efecto de selección (más brillante)
	if is_selected:
		color_to_use = color_to_use.lightened(0.3 + _select_brightness)
	
	# Cuerpo principal del tubo
	var rect = Rect2(-tube_width / 2, -tube_height / 2, tube_width, tube_height)
	draw_rect(rect, color_to_use)
	
	# Borde redondeado simulado con líneas
	draw_rect(rect, color_to_use.darkened(0.2), false, 3.0)
	
	# Parte superior (boca del tubo) - un rectángulo más oscuro
	var top_rect = Rect2(-tube_width / 2 + 5, -tube_height / 2 - 5, tube_width - 10, 15)
	draw_rect(top_rect, color_to_use.darkened(0.3))
	
	# Base del tubo
	var bottom_rect = Rect2(-tube_width / 2 + 5, tube_height / 2 - 10, tube_width - 10, 10)
	draw_rect(bottom_rect, color_to_use.darkened(0.2))
	
	# Línea decorativa vertical en el centro
	draw_line(
		Vector2(0, -tube_height / 2 + 15),
		Vector2(0, tube_height / 2 - 10),
		Color(1, 1, 1, 0.2),
		2.0
	)


func _process(delta: float):
	## Animaciones en tiempo real
	
	# Animación de error (temblor)
	if _error_timer > 0:
		_error_timer -= delta
		var shake_offset = Vector2(
			randf_range(-3.0, 3.0),
			randf_range(-3.0, 3.0)
		)
		position = position + shake_offset * 0.5
		queue_redraw()
	
	# Animación de succión (escala)
	if _suck_scale != 1.0:
		_suck_scale = lerp(_suck_scale, 1.0, delta * 10.0)
		if abs(_suck_scale - 1.0) < 0.01:
			_suck_scale = 1.0
		scale = Vector2(_suck_scale, _suck_scale)
	
	# Animación de selección (pulso)
	if is_selected:
		_select_brightness = sin(Time.get_ticks_msec() * 0.005) * 0.1
		queue_redraw()


## Detecta toques táctiles en el área del tubo
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventScreenTouch and event.pressed:
		_on_tap()


## Maneja el toque en el tubo - emite señal al SuctionQueue
## a través del SignalBus
func _on_tap():
	if is_blocked:
		return
	
	# Emitir señal para que SuctionQueue procese
	SignalBus.tube_tapped.emit(tube_color, tube_index)
	play_select_animation()


## Muestra el número de orden encima del tubo
func set_order_number(num: int):
	order_number = num
	if order_label:
		order_label.text = str(num) if num > 0 else ""
	queue_redraw()


## Limpia el número de orden
func clear_order():
	set_order_number(0)
	is_selected = false


## Animación de succión: el tubo se agranda y vuelve a su tamaño normal
func play_suction_animation():
	_suck_scale = 1.2
	var tween = create_tween()
	tween.tween_property(self, "_suck_scale", 1.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## Animación de selección: brillo momentáneo
func play_select_animation():
	is_selected = true
	await get_tree().create_timer(0.5).timeout
	is_selected = false
	queue_redraw()


## Animación de error: tiembla y se pone rojo momentáneamente
func play_error_animation():
	var original_color = _current_color
	_current_color = Color("#e74c3c")  # Rojo
	_error_timer = 0.5
	queue_redraw()
	
	await get_tree().create_timer(0.5).timeout
	_current_color = original_color
	_error_timer = 0.0
	queue_redraw()


## Bloquea o desbloquea el tubo
func set_blocked(blocked: bool):
	is_blocked = blocked
	if blocked:
		modulate = Color(0.5, 0.5, 0.5, 0.7)
	else:
		modulate = Color(1, 1, 1, 1)
