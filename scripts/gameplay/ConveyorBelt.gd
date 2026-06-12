extends Node2D

## Script para la cinta transportadora
##
## Maneja el movimiento visual (líneas animadas) de la cinta
## y emite una señal cuando un paquete llega a la zona de succión.
##
## Señales del SignalBus utilizadas:
## - conveyor_speed_changed(speed)
## - game_paused / game_resumed

signal package_reached_suction_zone(package_ref)

# ------------------- Variables exportadas -------------------
## Velocidad de la animación de la cinta (px/s)
@export var speed: float = 100.0
## Si la cinta está activa o pausada
@export var active: bool = true
## Alto visual de la cinta
@export var belt_height: float = 600.0
## Ancho visual de la cinta
@export var belt_width: float = 60.0

# ------------------- Variables internas -------------------
## Offset de las líneas animadas para efecto de movimiento
var _line_offset: float = 0.0
## Color de las líneas de la cinta
var _line_color: Color = Color(0.4, 0.4, 0.4)
## Color de fondo de la cinta
var _bg_color: Color = Color(0.25, 0.25, 0.25)

func _ready():
	## Configurar y conectar señales relevantes
	SignalBus.game_paused.connect(_on_game_paused)
	SignalBus.game_resumed.connect(_on_game_resumed)
	SignalBus.conveyor_speed_changed.connect(set_speed)


func _process(delta: float):
	## Movimiento de las líneas animadas de la cinta
	if not active:
		return
	
	_line_offset += speed * delta
	if _line_offset > belt_height:
		_line_offset = 0.0
	
	queue_redraw()


func _draw():
	## Dibujar el cuerpo de la cinta transportadora
	## Es un rectángulo alargado que representa la banda
	
	# Fondo de la cinta
	var belt_rect = Rect2(-belt_width / 2, 0, belt_width, belt_height)
	draw_rect(belt_rect, _bg_color)
	
	# Bordes laterales
	draw_line(Vector2(-belt_width / 2, 0), Vector2(-belt_width / 2, belt_height), Color(0.5, 0.5, 0.5), 2.0)
	draw_line(Vector2(belt_width / 2, 0), Vector2(belt_width / 2, belt_height), Color(0.5, 0.5, 0.5), 2.0)
	
	# Líneas animadas hacia abajo (efecto de movimiento)
	var spacing: float = 40.0
	var line_length: float = 15.0
	var y_start: float = _line_offset
	
	for i in range(int(belt_height / spacing) + 2):
		var y_pos = y_start - spacing * i
		if y_pos < -line_length || y_pos > belt_height + line_length:
			continue
		
		# Línea horizontal
		draw_line(
			Vector2(-belt_width / 4, y_pos),
			Vector2(belt_width / 4, y_pos),
			_line_color,
			3.0
		)
		
		# Pequeña flecha hacia abajo
		draw_line(
			Vector2(0, y_pos),
			Vector2(0, y_pos + 8),
			_line_color,
			2.0
		)


## Cambia la velocidad de la cinta
func set_speed(new_speed: float):
	speed = new_speed


## Pausa la cinta transportadora
func pause():
	active = false


## Reanuda la cinta transportadora
func resume():
	active = true


# ------------------- Señales del SignalBus -------------------

func _on_game_paused():
	pause()


func _on_game_resumed():
	resume()
