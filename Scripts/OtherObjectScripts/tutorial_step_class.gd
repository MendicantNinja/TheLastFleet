extends Node


class_name TutorialStep

var text: String
var condition: Callable
var skippable: bool = false

func _init(name: String, text: String, condition: Callable, skippable: bool = false) -> void:
	self.name = name
	self.text = text
	self.condition = condition
	self.skippable = skippable
