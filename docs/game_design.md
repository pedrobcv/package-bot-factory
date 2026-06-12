# Documento de Diseño del Juego: Package Bot Factory

## Versión 1.0

---

## 1. Concepto General

**Package Bot Factory** es un juego táctil para dispositivos móviles donde el jugador gestiona una fábrica de paquetes automatizada. El jugador debe clasificar paquetes de colores que viajan por una cinta transportadora, usando tubos de succión para recolectarlos en el orden correcto.

### Inspiración

- Juegos de gestión de colas (como los de cocina temporal)
- Puzzles de emparejamiento de colores
- Juegos idle/clicker con mecánica de fábrica

### Plataforma objetivo

- Móvil (Android/iOS)
- Resolución: 720x1280 (vertical)
- Input: Táctil exclusivamente

### Público objetivo

- Casual gamers
- Edad: 8+
- Sesiones cortas de 2-5 minutos

---

## 2. Mecánica Principal

### 2.1 Flujo de juego

1. Los paquetes aparecen en la parte superior de la pantalla y caen por la cinta transportadora.
2. El jugador toca los tubos de succión en la parte inferior para crear una cola de órdenes.
3. Cada tubo tiene un color. Tocar un tubo añade una orden de ese color a la cola.
4. Cuando un paquete que coincide con el color del primer tubo en la cola llega a la zona de succión, se succiona automáticamente.
5. Si el color no coincide, ocurre un error (penalización).
6. El jugador gana al completar la cantidad objetivo de paquetes.

### 2.2 Condiciones de derrota

- **Sin vidas**: Se pierde una vida por cada error (paquete que llega al fondo o error de color). Al llegar a 0 vidas, derrota.
- **Saturación máxima**: Los paquetes que llegan al fondo sin ser recolectados aumentan la saturación. Al 100%, derrota.

### 2.3 Condiciones de victoria

- Alcanzar la cantidad objetivo de paquetes correctamente clasificados en el nivel.

---

## 3. Sistema de Cola de Tubos

### 3.1 Descripción

El sistema de cola de tubos (SuctionQueue) es el núcleo del juego. Los tubos no procesan paquetes inmediatamente; en su lugar, el jugador construye una secuencia de órdenes tocando los tubos en el orden deseado.

### 3.2 Funcionamiento

1. **Añadir orden**: Tocar un tubo añade una orden a la cola (si no está llena).
2. **Procesar orden**: Cuando un paquete llega a la zona de succión, se compara su color con el de la primera orden en la cola.
   - Coincidencia: El paquete se succiona, la orden se elimina de la cola.
   - No coincidencia: Error, la orden permanece.
3. **Cancelar orden**: Si `allow_cancel` está activado, se puede cancelar la última orden (no implementado en UI actual).
4. **Cola vacía**: Si la cola está vacía cuando llega un paquete, este pasa de largo (aumenta saturación).

### 3.3 Configuración por nivel

- `max_queue_size`: Tamaño máximo de la cola (2-5 según dificultad)
- `allow_cancel`: Si se permite cancelar órdenes (true desde nivel 6)

---

## 4. Sistema de Paquetes

### 4.1 Tipos de paquetes

| Tipo | ID | Efecto |
|------|----|--------|
| NORMAL | 0 | Paquete estándar, 10 puntos base |
| GOLDEN | 1 | 50 puntos, brilla en dorado |
| BOMB | 2 | Explota si llega al fondo (pierde vida + saturación extra) |
| FAST | 3 | Se mueve 1.5x más rápido |
| HEAVY | 4 | Se mueve 0.7x más lento |
| FROZEN | 5 | Al procesarse, congela el tubo unos segundos |

### 4.2 Colores disponibles

- azul (#3498db)
- amarillo (#f1c40f)
- rojo (#e74c3c)
- verde (#2ecc71)
- morado (#9b59b6)

Los colores disponibles por nivel se configuran en los datos del nivel.

### 4.3 Comportamiento

- Los paquetes se mueven verticalmente hacia abajo a velocidad configurable.
- Al llegar a la zona de succión (~200px de Y), notifican al SuctionQueue.
- Al llegar al fondo (~1400px de Y), emiten señal de perdido.
- Tienen animación de spawn (aparecen con rebote).

---

## 5. Sistema de Niveles

### 5.1 Estructura

10 niveles con dificultad progresiva. Cada nivel está definido por un recurso `.tres` o valores por defecto en LevelManager.

### 5.2 Parámetros de nivel

| Parámetro | Descripción | Rango |
|-----------|-------------|-------|
| target_packages | Paquetes a clasificar | 10-40 |
| conveyor_speed | Velocidad de caída (px/s) | 40-85 |
| spawn_interval | Intervalo entre paquetes (s) | 1.3-3.0 |
| available_colors | Colores en el nivel | 2-5 |
| available_types | Tipos de paquete | 1-6 |
| available_powerups | Power-ups disponibles | 0-5 |
| max_lives | Vidas máximas | 3 |
| max_saturation | Saturación máxima | 100.0 |
| max_queue_size | Tamaño de cola | 2-5 |
| allow_cancel | Cancelar órdenes | false/true |
| difficulty_multiplier | Multiplicador general | 1.0-2.0 |

### 5.3 Progresión de dificultad

- Nivel 1-3: Introducción (2-3 colores, solo paquetes normales)
- Nivel 4-5: Velocidad aumenta, aparecen FAST y HEAVY
- Nivel 6+: 5 colores, todos los tipos, power-ups disponibles
- Nivel 7+: Cancelación de órdenes permitida
- Nivel 10: Máxima dificultad (2.0x multiplier)

---

## 6. Power-ups

### 6.1 Lista completa

| Power-up | Duración | Efecto |
|----------|----------|--------|
| slow_motion | 5s | Reduce velocidad de todos los paquetes |
| auto_correct | 8s | Corrige automáticamente el color del siguiente paquete |
| perfect_suction | 6s | No hay penalización por error |
| bomb_cleaner | Instantáneo | Elimina todas las bombas en pantalla |
| double_points | 7s | Duplica los puntos obtenidos |
| preview | 10s | Muestra el color del próximo paquete |

### 6.2 Spawning

- Los power-ups aparecen aleatoriamente durante la partida.
- Cada nivel configura qué power-ups están disponibles.
- Se instancian dinámicamente desde PowerUpManager.

---

## 7. Sistema de Puntuación

### 7.1 Puntos base

- Paquete normal: 10 puntos
- Paquete dorado: 50 puntos

### 7.2 Sistema de combos

- 2 aciertos consecutivos: x5 multiplicador
- 3 aciertos consecutivos: x10 multiplicador
- 4 aciertos consecutivos: x15 multiplicador

### 7.3 Penalizaciones

- Error de color: -5 puntos
- Combo roto al fallar: reinicia contador a 0

### 7.4 Estrellas

Al completar un nivel, se otorgan 1-3 estrellas según:
- 3 estrellas: Sin errores, todos los paquetes clasificados
- 2 estrellas: ≤2 errores, ≥80% paquetes clasificados
- 1 estrella: Nivel completado

---

## 8. Sistema de Derrota y Victoria

### 8.1 Derrota

- **Causa 1: Sin vidas** - Al cometer errores (paquetes al fondo, errores de color)
- **Causa 2: Saturación máxima** - Paquetes que llegan al fondo sin recolectar aumentan la barra

### 8.2 Victoria

- Completar la cantidad objetivo de paquetes correctamente clasificados
- Se muestra pantalla con puntaje, estadísticas y estrellas

### 8.3 Persistencia

- SaveManager guarda niveles desbloqueados y puntuaciones máximas
- Se usa ConfigFile en user://package_bot_factory.cfg

---

## 9. Arquitectura Técnica

### 9.1 Patrón de diseño

- **SignalBus**: Sistema central de señales (singleton autoload)
- **Autoloads**: GameManager, LevelManager, SaveManager, AudioManager, Constants
- **Comunicación desacoplada**: Los componentes se comunican mediante señales, no referencias directas

### 9.2 Autoloads

| Nombre | Propósito |
|--------|-----------|
| SignalBus | Bus central de señales del juego |
| GameManager | Estado del juego, puntuación, vidas, combos |
| LevelManager | Carga y validación de niveles |
| SaveManager | Persistencia de progreso |
| AudioManager | Reproducción de SFX y música |
| Constants | Constantes globales del juego |

### 9.3 Sistema de escenas

- **Main.tscn**: Escena raíz, contiene StartMenu
- **GameWorld.tscn**: Escena de juego, contiene todos los subsistemas
- Los managers (ComboManager, SaturationSystem, etc.) son hijos de GameWorld
- Las UI (HUD, pantallas) se añaden como CanvasLayer

---

## 10. Ideas Futuras

### 10.1 Skins del robot

- Diferentes skins del robot desbloqueables con logros o puntos
- Skins temáticos (espacial, steampunk, navideño)

### 10.2 Modos de juego adicionales

- **Modo contrarreloj**: Clasificar máximo de paquetes en 60s
- **Modo infinito**: Sin límite de paquetes (incremento de velocidad constante)
- **Modo desafío diario**: Nivel generado proceduralmente cada día

### 10.3 Sistema de logros

- Logros por combos, velocidad, nivel sin errores
- Logros ocultos ("toca el robot 100 veces")

### 10.4 Power-ups adicionales

- `magnet`: Atrae todos los paquetes del color del tubo (10s)
- `shield`: Protege de 1 error (hasta activarse)
- `speed_boost`: Aumenta velocidad de succión (8s)

### 10.5 Tabla de clasificación

- Puntuaciones máximas por nivel (local y online)
- Sistema de puntuación semanal
