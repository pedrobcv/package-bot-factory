extends Node

## SaturationSystem - Sistema de saturación (paquetes perdidos)
##
## Mide el nivel de saturación del juego, que aumenta cuando
## los paquetes llegan al fondo sin ser recolectados y se reduce
## cuando se procesan correctamente.
##
## Cuando la saturación llega al máximo (100%), se emite
## una señal de derrota a través del SignalBus.
##
## Señales del SignalBus utilizadas:
## - saturation_changed(saturation)
## - defeat(reason)

# ------------------- Variables exportadas -------------------
## Nivel actual de saturación (0.0 a 100.0)
@export var current_saturation: float = 0.0
## Saturación máxima permitida
@export var max_saturation: float = 100.0

# ------------------- Variables internas -------------------
## Factor de aumento por paquete perdido
const SATURATION_PER_MISS: float = 15.0
## Factor de reducción por acierto
const SATURATION_PER_HIT: float = 5.0


func _ready():
	## Inicializar el sistema de saturación
	_conectar_senales()


## Conecta las señales relevantes del SignalBus
func _conectar_senales():
	## Conectar señal de paquete perdido (llega al fondo)
	SignalBus.package_reached_bottom.connect(_on_package_reached_bottom)
	
	## Conectar señal de paquete recolectado exitosamente
	SignalBus.package_collected.connect(_on_package_collected)


## Aumenta la saturación por paquetes perdidos
## @param amount: float - Cantidad de saturación a añadir
func add_saturation(amount: float):
	current_saturation = clamp(current_saturation + amount, 0.0, max_saturation)
	_emitir_cambio()
	
	if is_maxed():
		SignalBus.defeat.emit("Saturación máxima alcanzada")


## Reduce la saturación por aciertos
## @param amount: float - Cantidad de saturación a reducir
func reduce_saturation(amount: float):
	current_saturation = clamp(current_saturation - amount, 0.0, max_saturation)
	_emitir_cambio()


## Resetea la saturación a cero
func reset_saturation():
	current_saturation = 0.0
	_emitir_cambio()


## Verifica si la saturación está al máximo
## @return: bool - true si la saturación alcanzó el máximo
func is_maxed() -> bool:
	return current_saturation >= max_saturation


## Retorna el porcentaje de saturación (0.0 a 1.0)
## @return: float - Porcentaje de saturación
func get_saturation_percent() -> float:
	return current_saturation / max_saturation


## Emite la señal de cambio de saturación
func _emitir_cambio():
	SignalBus.saturation_changed.emit(current_saturation)


# ------------------- Manejadores de señales -------------------

## Cuando un paquete llega al fondo sin ser recolectado
func _on_package_reached_bottom(package_ref):
	add_saturation(SATURATION_PER_MISS)


## Cuando un paquete es recolectado exitosamente
func _on_package_collected(package_ref, points: int):
	reduce_saturation(SATURATION_PER_HIT)
