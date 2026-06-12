extends Node

## Main - Nodo raíz de la escena principal
## Maneja cambios de escena via SignalBus

func _ready():
	if not SignalBus.change_scene.is_connected(_on_change_scene):
		SignalBus.change_scene.connect(_on_change_scene)
	if not SignalBus.return_to_menu.is_connected(_on_return_to_menu):
		SignalBus.return_to_menu.connect(_on_return_to_menu)

func _on_change_scene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)

func _on_return_to_menu():
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
