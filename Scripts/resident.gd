extends RefCounted
## Stable identity independent of the scene node, workplace and future family rules.
var id := 0
var appearance_id := 0
var display_name := ""
var profession := "idle"
var experience: Dictionary = {}
var energy := 100.0
var nutrition := 100.0
var starvation := 0.0
var residence_id := 0
var is_king := false
var is_adult := true
var tool := ""
var durability := 0

func gain_xp(activity: String, amount: float) -> void:
	experience[activity] = experience.get(activity, 0.0) + amount

func efficiency(data) -> float:
	return 1.0 + minf(data.XP_MAX_BONUS, float(experience.get(profession, 0)) / data.XP_STEP * 0.05)

func snapshot() -> Dictionary:
	return {"id": id, "appearance_id": appearance_id, "name": display_name, "profession": profession, "experience": experience.duplicate(), "energy": energy, "nutrition": nutrition, "starvation": starvation, "residence_id": residence_id, "king": is_king, "adult": is_adult, "tool": tool, "durability": durability}

