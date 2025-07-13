extends Control

@onready var ConstantSizedGUI = $ConstantSizedGUI
@onready var HardFluxIndicator = $ConstantSizedGUI/HardFluxIndicator
@onready var SoftFluxIndicator = $ConstantSizedGUI/HardFluxIndicator/SoftFluxIndicator
@onready var FluxPip = $ConstantSizedGUI/HardFluxIndicator/FluxPip
@onready var HullIntegrityIndicator = $ConstantSizedGUI/HullIntegrityIndicator
@onready var ShipTargetIcon = $ShipTargetIcon
@onready var ManualControlIndicator = $ManualControlIndicator
@onready var DebugLabelList = $ConstantSizedGUI/DebugLabelList
@onready var ShipNameDebugText = $ConstantSizedGUI/DebugLabelList/ShipNameDebugText
@onready var GroupDebugText = $ConstantSizedGUI/DebugLabelList/GroupDebugText
@onready var TargetDebugText = $ConstantSizedGUI/DebugLabelList/TargetDebugText

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
