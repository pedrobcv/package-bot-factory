extends Node

## ComboManager - Sistema de combos
##
## Maneja las rachas de aciertos consecutivos. Cada vez que
## el jugador procesa un paquete correctamente, el combo
## aumenta. Al fallar, el combo se reinicia.
##
## El multiplicador de puntos aumenta según la cantidad
## de aciertos consecutivos, usando los umbrales definidos
## en Constants.COMBO_THRESHOLDS.
##
## Señales del SignalBus utilizadas:
## - combo_updated(combo_count, multiplier)
## - combo_broken()

# ------------------- Variables exportadas -------------------
## Referencia a Constants autoload
@onready var constants: Node = get_node("/root/Constants")

# ------------------- Variables internas -------------------
## Contador actual de combo (aciertos consecutivos)
var combo_count: int = 0
## Máximo combo alcanzado en la partida
@export var max_combo: int = 0
## Multiplicador actual de puntos
@export var multiplier: int = 1

# ------------------- Variables internas -------------------
## Referencia a Constants para acceder a los umbrales


func _ready():
	## Inicializar el sistema de combos
	_combo_updated()


## Registra un acierto: incrementa combo y actualiza multiplicador
func register_success():
	combo_count += 1
	_calculate_multiplier()
	
	# Actualizar máximo combo
	if combo_count > max_combo:
		max_combo = combo_count
	
	_combo_updated()


## Registra un fallo: resetea el combo
func register_fail():
	if combo_count > 0:
		combo_count = 0
		multiplier = 1
		_combo_updated()
		SignalBus.combo_broken.emit()


## Calcula el multiplicador según el combo actual
## usando los umbrales de Constants.COMBO_THRESHOLDS
func _calculate_multiplier():
	multiplier = 1
	
	# Obtener umbrales de Constants
	var thresholds = _get_combo_thresholds()
	
	# Recorrer umbrales de mayor a menor para encontrar el multiplicador adecuado
	var sorted_keys = thresholds.keys()
	sorted_keys.sort()
	sorted_keys.reverse()
	
	for threshold in sorted_keys:
		if combo_count >= threshold:
			multiplier = thresholds[threshold]
			return


## Obtiene los umbrales de combo desde Constants autoload
func _get_combo_thresholds() -> Dictionary:
	if constants and "COMBO_THRESHOLDS" in constants:
		return constants.COMBO_THRESHOLDS
	
	# Fallback: umbrales por defecto
	return {
		2: 5,
		3: 10,
		4: 15
	}


## Emite señal de combo actualizado
func _combo_updated():
	SignalBus.combo_updated.emit(combo_count, multiplier)


## Retorna el multiplicador actual
func get_current_multiplier() -> int:
	return multiplier


## Retorna el máximo combo alcanzado
func get_max_combo() -> int:
	return max_combo


## Resetea completamente el sistema de combos
func reset():
	combo_count = 0
	max_combo = 0
	multiplier = 1
	_combo_updated()
