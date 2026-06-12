extends Area2D

## PowerUp - Power-up individual
##
## Representa un power-up que aparece en pantalla y el jugador
## puede tocar para activarlo. Cada power-up tiene un tipo,
## duración y efecto específico.
##
## Tipos de power-up:
## - slow_motion: Ralentiza todos los paquetes
## - auto_correct: Corrige automáticamente el color del tubo
## - perfect_suction: Succión perfecta sin penalización
## - bomb_cleaner: Elimina todas las bombas en pantalla
## - double_points: Duplica los puntos obtenidos
## - preview: Muestra el próximo color de paquete
##
## Conexiones requeridas:
## - CollisionShape2D como hijo
## - Label como hijo (para la letra/símbolo)
##
## Señales del SignalBus utilizadas:
## - power_up_activated(power_up_type)

# ------------------- Configuración de tipos -------------------
## Colores por tipo de power-up
const TYPE_COLORS: Dictionary = {
	"slow_motion": Color("#00bcd4"),      # Cyan
	"auto_correct": Color("#ff9800"),     # Naranja
	"perfect_suction": Color("#e91e63"),  # Rosa
	"bomb_cleaner": Color("#ff5722"),     # Naranja oscuro
	"double_points": Color("#ffeb3b"),    # Amarillo
	"preview": Color("#9c27b0")           # Morado
}

## Letras/símbolos por tipo de power-up
const TYPE_LETTERS: Dictionary = {
	"slow_motion": "S",
	"auto_correct": "A",
	"perfect_suction": "P",
	"bomb_cleaner": "B",
	"double_points": "X2",
	"preview": "V"
}

# ------------------- Variables exportadas -------------------
## Tipo de power-up
@export var power_up_type: String = "slow_motion"
## Duración del efecto en segundos
@export var duration: float = 5.0
## Si está activo actualmente
@export var is_active: bool = false

# ------------------- Variables internas -------------------
## Color del power-up según su tipo
var _color: Color = Color("#00bcd4")
## Letra/símbolo a mostrar
var _letter: String = "S"
## Tamaño del círculo
var _circle_radius: float = 25.0
## Parpadeo para indicar que está activo
var _blink_timer: float = 0.0
## Velocidad de rotación decorativa
var _rot_speed: float = 0.0

## Referencia al CollisionShape2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## Referencia al Label
@onready var letter_label: Label = $LetterLabel


func _ready():
	## Configurar apariencia según el tipo
	_color = TYPE_COLORS.get(power_up_type, Color("#00bcd4"))
	_letter = TYPE_LETTERS.get(power_up_type, "?")
	
	# Configurar shape de colisión
	if collision_shape and collision_shape.shape == null:
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = _circle_radius
		collision_shape.shape = circle_shape
	
	# Configurar label
	if letter_label:
		letter_label.text = _letter
		letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter_label.add_theme_font_size_override("font_size", 18)
		letter_label.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Conectar señal de entrada táctil
	input_event.connect(_on_input_event)
	
	# Velocidad de rotación aleatoria para animación
	_rot_speed = randf_range(0.5, 2.0)
	
	queue_redraw()


func _process(delta: float):
	## Animación de rotación y parpadeo
	_rot_speed += delta
	
	if is_active:
		_blink_timer += delta
		var alpha = abs(sin(_blink_timer * 5.0))
		modulate = Color(1, 1, 1, alpha)
	
	queue_redraw()


func _draw():
	## Dibujar círculo brillante con letra del power-up
	var center = Vector2.ZERO
	
	# Círculo exterior (brillo)
	draw_circle(center, _circle_radius + 3, _color.lightened(0.4))
	
	# Círculo principal
	draw_circle(center, _circle_radius, _color)
	
	# Borde
	draw_circle(center, _circle_radius, _color.darkened(0.3), false, 2.0)
	
	# Brillo interior (efecto de cristal)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 0.3))
	gradient.add_point(0.5, Color(1, 1, 1, 0.1))
	gradient.add_point(1.0, Color(1, 1, 1, 0.0))
	
	# Pequeño destello en la esquina superior izquierda
	draw_circle(Vector2(-_circle_radius * 0.3, -_circle_radius * 0.3), _circle_radius * 0.3, Color(1, 1, 1, 0.2))


## Detecta toque en el power-up
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventScreenTouch and event.pressed:
		activate()


## Activa el power-up
func activate():
	if is_active:
		return
	
	is_active = true
	SignalBus.power_up_activated.emit(power_up_type)
	
	# Efecto visual de activación (agrandar y desaparecer)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	
	await tween.finished
	queue_free()


## Desactiva el power-up
func deactivate():
	is_active = false
	modulate = Color(1, 1, 1, 1)


## Retorna la duración del power-up
func get_duration() -> float:
	return duration
