extends Object
class_name ImapTemplate

var radius: int
var Map: Imap
enum TemplateType {
	OCCUPANCY_TEMPLATE, # Occupancy indicates the space a unit occupies and its zone of influence.
	THREAT_TEMPLATE, # Threat denotes its attack abilities such as the strength of its weapons and accuracy.
}

var list: Dictionary = {
	TemplateType.OCCUPANCY_TEMPLATE: [],
	TemplateType.THREAT_TEMPLATE: [],
}
