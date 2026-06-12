extends Node

## Constantes globales del proyecto Package Bot Factory
##
## Este autoload contiene todas las constantes del juego,
## incluyendo configuraciones de pantalla, tipos de paquetes,
## colores, puntuaciones y umbrales del sistema de combos.
## Se registra como "Constants" en Project Settings > Autoload.

# ------------------- Configuración de pantalla -------------------
const GAME_NAME: String = "Package Bot Factory"
const SCREEN_WIDTH: int = 720
const SCREEN_HEIGHT: int = 1280

# ------------------- Estados del juego -------------------
enum GameState {
	MENU,      # Pantalla de menú principal
	PLAYING,   # Jugando activamente
	PAUSED,    # Juego en pausa
	VICTORY,   # Nivel completado exitosamente
	DEFEAT     # Nivel perdido
}

# ------------------- Tipos de paquetes -------------------
enum PackageType {
	NORMAL,  # Paquete estándar sin efectos especiales
	GOLDEN,  # Paquete dorado que otorga puntuación extra
	BOMB,    # Explota si llega al fondo o se procesa incorrectamente
	FAST,    # Se mueve más rápido en la cinta transportadora
	HEAVY,   # Llega más lento pero ocupa más recursos
	FROZEN   # Congela momentáneamente el tubo que lo procesa
}

# ------------------- Colores disponibles -------------------
## Mapa de nombres de color a colores reales de Godot
const COLOR_MAP: Dictionary = {
	"azul":   Color(0.20, 0.40, 0.90),
	"amarillo": Color(1.00, 0.80, 0.00),
	"rojo":   Color(0.85, 0.15, 0.15),
	"verde":  Color(0.15, 0.70, 0.15),
	"morado": Color(0.60, 0.20, 0.80)
}

## Lista ordenada de colores disponibles para tubos y paquetes
const TUBE_COLORS: Array = ["azul", "amarillo", "rojo", "verde", "morado"]

# ------------------- Puntuación -------------------
## Puntos base por recolectar un paquete normal
const BASE_SCORE: int = 10

## Puntos extra por recolectar un paquete dorado
const GOLDEN_SCORE: int = 50

## Penalización por error (paquete incorrecto en tubo, etc.)
const ERROR_PENALTY: int = -5

## Umbrales de combo y multiplicadores asociados
## clave = cantidad de aciertos consecutivos, valor = multiplicador de puntos
const COMBO_THRESHOLDS: Dictionary = {
	2: 5,   # 2 aciertos: x5
	3: 10,  # 3 aciertos: x10
	4: 15   # 4 aciertos: x15
}

# ------------------- Límites del juego -------------------
## Vidas máximas por nivel
const MAX_LIVES: int = 3

## Saturación máxima del medidor (porcentaje)
const MAX_SATURATION: float = 100.0
