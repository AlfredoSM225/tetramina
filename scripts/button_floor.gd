extends StaticBody2D

@export var puerta_objetivo: Puerta
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play("Unpressed")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	sprite.play("Pressed")
	if puerta_objetivo:
		puerta_objetivo.set_abierta(true)


func _on_area_2d_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	sprite.play("Unpressed")
	if puerta_objetivo:
		puerta_objetivo.set_abierta(false)




func _on_area_2d_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	sprite.play("Pressed")
	if puerta_objetivo:
		puerta_objetivo.set_abierta(true)
