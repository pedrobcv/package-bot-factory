extends Node

## SignalBus - Sistema central de señales del juego
##
## Autoload que actúa como bus de comunicación entre todos los
## sistemas del juego. Los componentes se comunican mediante
## señales en lugar de referencias directas, manteniendo
## un acoplamiento bajo y facilitando el mantenimiento.
##
## Registrado como "SignalBus" en Project Settings > Autoload.

# ------------------- Señales del juego -------------------

## Se emite cuando el jugador inicia una partida desde el menú
signal game_started()

## Se emite al pausar el juego
signal game_paused()

## Se emite al reanudar el juego después de una pausa
signal game_resumed()

## Se emite cuando se selecciona un nivel específico
## @param level_number: int - Número de nivel seleccionado
signal level_selected(level_number: int)

## Se emite cuando un paquete aparece en pantalla
## @param package_ref: Referencia al nodo del paquete
signal package_spawned(package_ref)

## Se emite cuando un paquete llega al fondo sin ser recolectado
## @param package_ref: Referencia al nodo del paquete
signal package_reached_bottom(package_ref)

## Se emite cuando el jugador toca un tubo
## @param tube_color: String - Color del tubo tocado
## @param tube_index: int - Índice del tubo en la escena
signal tube_tapped(tube_color: String, tube_index: int)

## Se emite cuando se añade una orden a la cola de pedidos
## @param order: Dictionary - Datos de la orden (color, tipo, etc.)
signal order_added_to_queue(order: Dictionary)

## Se emite cuando una orden ha sido procesada (éxito o fallo)
## @param order: Dictionary - Datos de la orden original
## @param package_ref: Referencia al paquete procesado
## @param success: bool - true si se procesó correctamente
signal order_processed(order: Dictionary, package_ref, success: bool)

## Se emite cuando la cola de pedidos se vacía completamente
signal queue_cleared()

## Se emite cuando se recolecta un paquete exitosamente
## @param package_ref: Referencia al paquete recolectado
## @param points: int - Puntos obtenidos
signal package_collected(package_ref, points: int)

## Se emite cuando ocurre un error al procesar un paquete
## @param package_ref: Referencia al paquete con error
signal package_error(package_ref)

## Se emite cuando el contador de combo se actualiza
## @param combo_count: int - Número de aciertos consecutivos
## @param multiplier: int - Multiplicador actual de puntos
signal combo_updated(combo_count: int, multiplier: int)

## Se emite cuando se rompe la racha de combo
signal combo_broken()

## Se emite cuando cambia el número de vidas del jugador
## @param lives: int - Vidas restantes
signal lives_changed(lives: int)

## Se emite cuando cambia el nivel de saturación
## @param saturation: float - Valor de saturación (0.0 a 100.0)
signal saturation_changed(saturation: float)

## Se emite al activar un power-up
## @param power_up_type: String - Tipo de power-up activado
signal power_up_activated(power_up_type: String)

## Se emite al desactivar un power-up
## @param power_up_type: String - Tipo de power-up desactivado
signal power_up_deactivated(power_up_type: String)

## Se emite cuando el jugador gana el nivel
signal victory()

## Se emite cuando el jugador pierde el nivel
## @param reason: String - Razón de la derrota
signal defeat(reason: String)

## Se emite cuando cambia la puntuación
## @param score: int - Puntuación actual
signal score_updated(score: int)

## Se emite para volver al menú principal
signal return_to_menu()

## Se emite cuando cambia la velocidad de la cinta transportadora
## @param speed: float - Nueva velocidad
signal conveyor_speed_changed(speed: float)
