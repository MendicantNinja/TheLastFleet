extends RefCounted
class_name Bullet

var owner_rid: RID
var shape_rid: RID
var shape_idx: int
var damage_type: data.weapon_damage_enum
var damage: float = 0.0
var current_position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var speed: int = 0
var lifetime: float = 0.0
var image_offset: int = 0
var layer: String = ""
