extends Node2D

## RobotController - Control de animaciones del robot
##
## Controla las animaciones del robot que aparece en la parte
## superior de la pantalla. El robot se dibuja con formas
## simples: cuerpo rectangular, cabeza cuadrada y ojos circulares.
##
## Conexiones requeridas en el árbol de escena:
## - RobotBody (Node2D) como hijo - para el cuerpo
## - RobotHead (Node2D) como hijo - para la cabeza
## - RobotEyes (Node2D) como hijo - para los ojos
##
## Señales del SignalBus utilizadas:
## - tubo succionando: animación vía tube_tapped
## - error: animación vía package_error
## - victory: animación vía victory
## - combo_broken/juego: animaciones de reacción

# ------------------- Referencias a nodos hijos -------------------
## Nodo que contiene el dibujo del cuerpo del robot
@onready var robot_body: Node2D = $RobotBody
## Nodo que contiene el dibujo de la cabeza del robot
@onready var robot_head: Node2D = $RobotHead
## Nodo que contiene el dibujo de los ojos del robot
@onready var robot_eyes: Node2D = $RobotEyes

# ------------------- Variables internas -------------------
## Temporizador para animación de error (temblor)
var _error_timer: float = 0.0
## Posición original del robot (para animación de temblor)
var _original_position: Vector2 = Vector2.ZERO
## Escala para animación de victoria
var _victory_scale: float = 1.0
## Tiempo transcurrido para animación idle
var _idle_time: float = 0.0


func _ready():
	## Configurar drawn en cada parte del robot
	_original_position = position
	
	# Conectar señales del SignalBus
	SignalBus.tube_tapped.connect(_on_tube_tapped)
	SignalBus.package_error.connect(_on_package_error)
	SignalBus.victory.connect(play_victory_animation)
	SignalBus.combo_broken.connect(_on_combo_broken)
	
	# Dibujar inicial
	_trigger_redraw()


func _process(delta: float):
	## Animaciones en tiempo real
	
	# Animación idle suave
	_idle_time += delta
	var idle_offset_y = sin(_idle_time * 1.5) * 2.0
	position.y = _original_position.y + idle_offset_y
	
	# Animación de error (temblor)
	if _error_timer > 0:
		_error_timer -= delta
		position.x = _original_position.x + randf_range(-4.0, 4.0)
	
	# Animación de victoria (rebote)
	if _victory_scale != 1.0:
		_victory_scale = lerp(_victory_scale, 1.0, delta * 3.0)
		if abs(_victory_scale - 1.0) < 0.01:
			_victory_scale = 1.0
		scale = Vector2(_victory_scale, _victory_scale)


func _trigger_redraw():
	## Forzar redibujo de todas las partes
	if robot_body:
		robot_body.queue_redraw()
	if robot_head:
		robot_head.queue_redraw()
	if robot_eyes:
		robot_eyes.queue_redraw()


## Anima el tubo succionando (el robot reacciona al toque de tubo)
func play_suck_animation(tube_index: int):
	## Anima el robot mirando hacia el tubo y haciendo una pequeña
	## inclinación hacia el frente
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Inclinación hacia adelante
	var target_rotation = 0.05 if tube_index % 2 == 0 else -0.05
	tween.tween_property(self, "rotation", target_rotation, 0.1).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", 0.0, 0.15).set_ease(Tween.EASE_OUT).set_delay(0.1)
	
	# Pequeño salto
	tween.tween_property(self, "position:y", _original_position.y - 10, 0.1)
	tween.tween_property(self, "position:y", _original_position.y, 0.15).set_ease(Tween.EASE_OUT).set_delay(0.1)


## Anima el robot cuando ocurre un error (tiembla, flash rojo)
func play_error_animation():
	_error_timer = 0.8
	
	# Flash rojo en el robot
	if robot_body:
		robot_body.modulate = Color(1, 0.3, 0.3)
	if robot_head:
		robot_head.modulate = Color(1, 0.3, 0.3)
	
	await get_tree().create_timer(0.8).timeout
	_error_timer = 0.0
	
	if robot_body:
		robot_body.modulate = Color(1, 1, 1)
	if robot_head:
		robot_head.modulate = Color(1, 1, 1)
	
	position = _original_position


## Anima el robot celebrando (rebotes, giros)
func play_victory_animation():
	var tween = create_tween()
	tween.set_parallel(false)
	
	# Rebote 1
	tween.tween_property(self, "_victory_scale", 1.2, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_victory_scale", 1.0, 0.2).set_ease(Tween.EASE_IN)
	
	# Rebote 2
	tween.tween_property(self, "_victory_scale", 1.15, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_victory_scale", 1.0, 0.15).set_ease(Tween.EASE_IN)
	
	# Giro de celebración
	tween.tween_property(self, "rotation", 0.2, 0.1)
	tween.tween_property(self, "rotation", -0.2, 0.2)
	tween.tween_property(self, "rotation", 0.0, 0.1)


## Animación idle suave (respiración)
func play_idle_animation():
	## Ya manejada en _process, esta función sirve para
	## reiniciar o forzar la animación idle
	_idle_time = 0.0


# ------------------- Señales del SignalBus -------------------

func _on_tube_tapped(tube_color: String, tube_index: int):
	play_suck_animation(tube_index)


func _on_package_error(package_ref):
	play_error_animation()


func _on_combo_broken():
	play_error_animation()
