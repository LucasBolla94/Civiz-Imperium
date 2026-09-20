extends RefCounted
var required: Dictionary = {}
var delivered: Dictionary = {}

func ready() -> bool:
	for resource in required:
		if delivered.get(resource, 0) < required[resource]: return false
	return true

func missing(resource: String) -> int:
	return maxi(0, required.get(resource, 0) - delivered.get(resource, 0))

func receive(resource: String, amount: int) -> int:
	var accepted := mini(amount, missing(resource))
	delivered[resource] = delivered.get(resource, 0) + accepted
	return accepted

func text(data) -> String:
	var parts: PackedStringArray = []
	for resource in required:
		parts.append("%d/%d %s" % [delivered.get(resource, 0), required[resource], data.RESOURCES[resource].name])
	return " · ".join(parts)
