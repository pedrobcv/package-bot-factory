extends Node

## SuctionQueue - Cola de órdenes de tubos
##
## SISTEMA CRÍTICO: maneja la cola de órdenes de tubos.
## NO es autoload, se coloca en un nodo dentro de GameWorld.
##
## Los tubos añaden órdenes aquí cuando son tocados.
## El procesamiento verifica si el paquete entrante coincide
## con la primera orden de la cola.
##
## Señales del SignalBus utilizadas:
## - order_added_to_queue(order)
## - order_processed(order, package_ref, success)
## - queue_cleared()

# ------------------- Variables exportadas -------------------
## Tamaño máximo de la cola de órdenes
@export var max_queue_size: int = 3
## Si se permite cancelar órdenes
@export var allow_cancel: bool = true

# ------------------- Variables internas -------------------
## Array de diccionarios: {tube_color: String, tube_index: int, order_number: int}
var _order_queue: Array = []


func _ready():
	## Inicializa la cola vacía
	_order_queue = []


## Agrega un tubo a la cola de órdenes.
## @param tube_color: String - Color del tubo
## @param tube_index: int - Índice del tubo
## @return: bool - false si la cola está llena
func add_tube_to_queue(tube_color: String, tube_index: int) -> bool:
	if is_queue_full():
		return false
	
	var order_number = _order_queue.size() + 1
	var order: Dictionary = {
		"tube_color": tube_color,
		"tube_index": tube_index,
		"order_number": order_number
	}
	
	_order_queue.append(order)
	
	# Emitir señal al SignalBus
	SignalBus.order_added_to_queue.emit(order)
	
	return true


## Retorna el primer elemento de la cola sin eliminarlo.
## Si la cola está vacía, retorna un diccionario vacío.
func get_next_order() -> Dictionary:
	if _order_queue.is_empty():
		return {}
	return _order_queue[0].duplicate()


## Procesa el primer paquete de la cola comparándolo con el color del paquete.
## @param package_color: String - Color del paquete a procesar
## @return: Dictionary - {matched: bool, order: Dictionary}
##   Si matched=true: la orden fue procesada y eliminada de la cola
##   Si matched=false: el color no coincide, la orden permanece
func process_next_order(package_color: String) -> Dictionary:
	if _order_queue.is_empty():
		return {
			"matched": false,
			"order": {},
			"error": "Cola vacía"
		}
	
	var first_order: Dictionary = _order_queue[0]
	var matches: bool = (first_order["tube_color"] == package_color)
	
	if matches:
		# Remover la primera orden
		_order_queue.remove_at(0)
		
		# Actualizar números de orden de los elementos restantes
		for i in range(_order_queue.size()):
			_order_queue[i]["order_number"] = i + 1
		
		# Emitir señal de procesamiento exitoso
		SignalBus.order_processed.emit(first_order, null, true)
		
		# Si la cola quedó vacía, emitir señal
		if _order_queue.is_empty():
			SignalBus.queue_cleared.emit()
		
		return {
			"matched": true,
			"order": first_order
		}
	else:
		# Emitir señal de error
		SignalBus.order_processed.emit(first_order, null, false)
		
		return {
			"matched": false,
			"order": first_order,
			"error": "El color del paquete no coincide con la orden"
		}


## Cancela una orden por índice de tubo.
## @param tube_index: int - Índice del tubo a cancelar
## @return: bool - true si se canceló exitosamente
func cancel_order(tube_index: int) -> bool:
	if not allow_cancel:
		return false
	
	var index_to_remove: int = -1
	for i in range(_order_queue.size()):
		if _order_queue[i]["tube_index"] == tube_index:
			index_to_remove = i
			break
	
	if index_to_remove == -1:
		return false
	
	_order_queue.remove_at(index_to_remove)
	
	# Actualizar números de orden
	for i in range(_order_queue.size()):
		_order_queue[i]["order_number"] = i + 1
	
	# Emitir señal indicando que se procesó (cancelación)
	SignalBus.order_processed.emit({"tube_color": "", "tube_index": tube_index}, null, false)
	
	return true


## Limpia toda la cola de órdenes
func clear_queue():
	_order_queue.clear()
	SignalBus.queue_cleared.emit()


## Retorna el tamaño actual de la cola
func get_queue_size() -> int:
	return _order_queue.size()


## Verifica si la cola está llena
func is_queue_full() -> bool:
	return _order_queue.size() >= max_queue_size


## Cambia el tamaño máximo de la cola
func set_max_queue_size(size: int):
	max_queue_size = size
