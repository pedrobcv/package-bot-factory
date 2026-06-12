# Package Bot Factory

Una fábrica de paquetes donde clasificas paquetes usando tubos de succión en un juego táctil para móviles (Godot 4.4.1).

## Concepto del juego

El jugador gestiona una cinta transportadora con paquetes de colores que caen desde arriba. Tocando los tubos de succión en orden, el jugador crea una cola de pedidos. Cuando un paquete del color correcto llega al tubo, se succiona automáticamente. El objetivo es completar la cantidad objetivo de paquetes antes de que la saturación llegue al máximo o se acaben las vidas.

## Mecánica táctil de cola de tubos

Los 5 tubos en la parte inferior representan los colores disponibles (azul, amarillo, rojo, verde, morado). El jugador toca los tubos para añadir órdenes a la cola de procesamiento. El siguiente paquete que coincida con el color del primer tubo en la cola se succionará automáticamente.

## Cómo ejecutar

1. Abrir Godot 4.4.1
2. Importar/clonar este proyecto
3. Presionar F5 (o Play)

La escena principal está configurada como `res://scenes/main/Main.tscn`.

## Cómo agregar niveles

Los niveles se definen como recursos `.tres` en `res://resources/levels/`:

1. Crear un nuevo archivo `level_11.tres` (o el número que corresponda)
2. Estructura del recurso:
   ```gdscript
   [gd_resource type="Resource" format=3]
   
   [resource]
   level_number = 11
   target_packages = 45
   conveyor_speed = 90.0
   spawn_interval = 1.2
   colors = ["azul", "rojo", "verde", "amarillo", "morado"]
   types = [0, 1, 2, 3, 4, 5]
   powerups = ["slow_motion", "double_points"]
   max_lives = 3
   max_saturation = 100.0
   max_queue_size = 5
   allow_cancel = true
   difficulty_multiplier = 2.2
   ```
3. Si no existe archivo `.tres`, se usan los valores por defecto en `LevelManager.gd`.

## Cómo cambiar paquetes

Los tipos de paquetes se definen en `res://resources/package_types/` como recursos `.tres`:

```gdscript
[gd_resource type="Resource" format=3]

[resource]
name = "MiPaquete"
color = "azul"
type = 0
points = 15
speed_multiplier = 1.0
penalty = 0
```

Los tipos de paquete disponibles son:
- `0`: NORMAL - Paquete estándar
- `1`: GOLDEN - Otorga 50 puntos
- `2`: BOMB - Explota si llega al fondo
- `3`: FAST - Se mueve más rápido
- `4`: HEAVY - Se mueve más lento
- `5`: FROZEN - Congela el tubo

## Cómo cambiar power-ups

Los power-ups se definen en `res://resources/powerups/` como recursos `.tres`:

```gdscript
[gd_resource type="Resource" format=3]

[resource]
type = "slow_motion"
duration = 5.0
color = Color("#00bcd4")
letter = "S"
```

Tipos de power-up disponibles:
- `slow_motion`: Ralentiza paquetes (5s)
- `auto_correct`: Corrige color de tubo (8s)
- `perfect_suction`: Sin penalización (6s)
- `bomb_cleaner`: Elimina bombas (instantáneo)
- `double_points`: Duplica puntos (7s)
- `preview`: Muestra próximo color (10s)

## Cómo reemplazar placeholders por assets finales

Los assets placeholder están en `res://assets/placeholders/`. Para reemplazarlos:

1. **Robot**: Reemplazar dibujo `_draw()` con sprites en `res://assets/placeholders/robot/`
2. **Paquetes**: Reemplazar `_draw()` con TextureRect en la escena Package.tscn
3. **Tubos**: Reemplazar `_draw()` con TextureRect o sprites en SuctionTube.tscn
4. **Cinta transportadora**: Reemplazar animación procedural con sprites animados
5. **Power-ups**: Cambiar `_draw()` por sprites con animaciones
6. **Audio**: Agregar archivos `.ogg` en `res://assets/audio/sfx/` y `res://assets/audio/music/`
7. **UI**: Reemplazar placeholders de botones/labels con TextureButton y texturas

## Estructura del proyecto

```
package-bot-factory/
├── assets/
│   ├── audio/
│   │   ├── music/       # Música de fondo (.ogg)
│   │   └── sfx/         # Efectos de sonido (.ogg)
│   └── placeholders/    # Sprites placeholder
│       ├── conveyor/
│       ├── packages/
│       ├── powerups/
│       ├── robot/
│       ├── tubes/
│       └── ui/
├── docs/
│   └── game_design.md   # Documento de diseño del juego
├── resources/
│   ├── levels/          # Recursos de nivel (.tres)
│   ├── package_types/   # Definiciones de paquetes (.tres)
│   └── powerups/        # Definiciones de power-ups (.tres)
├── scenes/
│   ├── game/            # Escenas de gameplay
│   │   ├── ConveyorBelt.tscn
│   │   ├── GameWorld.tscn
│   │   ├── Package.tscn
│   │   ├── PackageSpawner.tscn
│   │   ├── PowerUp.tscn
│   │   ├── Robot.tscn
│   │   └── SuctionTube.tscn
│   ├── main/            # Escena principal
│   │   └── Main.tscn
│   └── ui/              # Escenas de interfaz
│       ├── GameHUD.tscn
│       ├── LevelSelect.tscn
│       ├── LoseScreen.tscn
│       ├── PauseMenu.tscn
│       ├── StartMenu.tscn
│       └── WinScreen.tscn
├── scripts/
│   ├── core/            # Autoloads (GameManager, SignalBus, etc.)
│   │   ├── AudioManager.gd
│   │   ├── Constants.gd
│   │   ├── GameManager.gd
│   │   ├── LevelManager.gd
│   │   ├── SaveManager.gd
│   │   └── SignalBus.gd
│   ├── gameplay/        # Lógica de gameplay
│   │   ├── ComboManager.gd
│   │   ├── ConveyorBelt.gd
│   │   ├── Package.gd
│   │   ├── PackageSpawner.gd
│   │   ├── PowerUp.gd
│   │   ├── PowerUpManager.gd
│   │   ├── RobotController.gd
│   │   ├── SaturationSystem.gd
│   │   ├── SuctionQueue.gd
│   │   └── SuctionTube.gd
│   └── ui/              # Lógica de interfaz
│       ├── GameHUD.gd
│       ├── LevelSelect.gd
│       ├── LoseScreen.gd
│       ├── PauseMenu.gd
│       ├── StartMenu.gd
│       └── WinScreen.gd
├── icon.png
├── project.godot
└── README.md
```

## Controles móviles

- **Tocar un tubo**: Añade una orden de ese color a la cola
- **Tocar power-up**: Activa el power-up
- **No hay joystick ni botones de movimiento**: La interacción es completamente táctil tocando los tubos y power-ups
- **Botón de pausa**: Esquina superior derecha durante la partida
