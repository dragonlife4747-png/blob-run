extends Node

const L10n = preload("res://scripts/l10n.gd")
## Persistent player profile: coins, stars, upgrades, skins, daily mission, settings.

const SAVE_PATH := "user://profile.json"

const UPGRADES := {
	"start": {
		"name": "Start Mass", "desc": "Begin every run bigger", "max": 5,
		"costs": [150, 300, 600, 1000, 1600], "step": 4.0, "unit": "mass",
	},
	"magnet": {
		"name": "Magnet", "desc": "Pull in orbs from far away", "max": 4,
		"costs": [200, 420, 760, 1200], "step": 1.0, "unit": "lvl",
	},
	"speed": {
		"name": "Lane Speed", "desc": "Switch lanes faster", "max": 4,
		"costs": [180, 360, 650, 1000], "step": 1.0, "unit": "lvl",
	},
	"shield": {
		"name": "Shield", "desc": "Survive one hit per run", "max": 2,
		"costs": [400, 900], "step": 1.0, "unit": "hit",
	},
}

const SKINS := [
	{"name": "Slime", "price": 0, "base": Color(0.18, 0.92, 0.78), "rim": Color(1.0, 0.55, 0.20)},
	{"name": "Bubblegum", "price": 250, "base": Color(1.0, 0.40, 0.66), "rim": Color(1.0, 0.86, 0.35)},
	{"name": "Glacier", "price": 400, "base": Color(0.55, 0.82, 1.0), "rim": Color(0.85, 0.98, 1.0)},
	{"name": "Toxic", "price": 600, "base": Color(0.62, 1.0, 0.22), "rim": Color(0.12, 0.62, 0.28)},
	{"name": "Galaxy", "price": 900, "base": Color(0.42, 0.30, 0.95), "rim": Color(0.95, 0.45, 0.95)},
	{"name": "Gold", "price": 1500, "base": Color(1.0, 0.78, 0.22), "rim": Color(1.0, 0.96, 0.72)},
]

const MISSIONS := [
	{"id": "pools", "text": "Finish {n} levels", "target": 3, "reward": 120},
	{"id": "coins", "text": "Earn {n} coins", "target": 200, "reward": 100},
	{"id": "good", "text": "Pass {n} bonus gates", "target": 12, "reward": 90},
	{"id": "stars", "text": "Collect {n} stars", "target": 5, "reward": 150},
	{"id": "eaten", "text": "Absorb {n} blobs", "target": 20, "reward": 110},
]

var coins := 0
var best_mass := 0
var unlocked := 1
var tutorial_done := false
var lang := "en"
var lang_set := false
var daily_best := 0
var daily_date := ""
var stars := {}
var upgrades := {"start": 0, "magnet": 0, "speed": 0, "shield": 0}
var skin := 0
var owned_skins := [0]
var music_on := true
var sfx_on := true
var haptics_on := true
var mission := {}
var scores: Array = []


func _ready() -> void:
	load_profile()


# ---------------------------------------------------------------- persistence
func apply_locale_default() -> void:
	lang = "fa" if OS.get_locale_language().begins_with("fa") else "en"
	lang_set = true
	L10n.fa = (lang == "fa")


func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		apply_locale_default()
		_roll_mission()
		save_profile()
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var d: Dictionary = data
	coins = int(d.get("coins", 0))
	best_mass = int(d.get("best_mass", 0))
	unlocked = maxi(1, int(d.get("unlocked", 1)))
	tutorial_done = bool(d.get("tutorial_done", false))
	lang = String(d.get("lang", "en"))
	lang_set = bool(d.get("lang_set", false))
	if not lang_set:
		# first launch: follow the phone language
		apply_locale_default()
	else:
		L10n.fa = (lang == "fa")
	daily_best = int(d.get("daily_best", 0))
	daily_date = String(d.get("daily_date", ""))
	if daily_date != Time.get_date_string_from_system():
		daily_date = Time.get_date_string_from_system()
		daily_best = 0
	stars = d.get("stars", {})
	upgrades = d.get("upgrades", upgrades)
	skin = int(d.get("skin", 0))
	owned_skins = d.get("owned_skins", [0])
	if not (skin in owned_skins):
		skin = 0
	music_on = bool(d.get("music_on", true))
	sfx_on = bool(d.get("sfx_on", true))
	haptics_on = bool(d.get("haptics_on", true))
	mission = d.get("mission", {})
	scores = d.get("scores", [])
	var today := Time.get_date_string_from_system()
	if mission.is_empty() or String(mission.get("date", "")) != today:
		_roll_mission()
	save_profile()


func save_profile() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"coins": coins,
		"best_mass": best_mass,
		"unlocked": unlocked,
		"tutorial_done": tutorial_done,
		"lang": lang,
		"lang_set": lang_set,
		"daily_best": daily_best,
		"daily_date": daily_date,
		"stars": stars,
		"upgrades": upgrades,
		"skin": skin,
		"owned_skins": owned_skins,
		"music_on": music_on,
		"sfx_on": sfx_on,
		"haptics_on": haptics_on,
		"mission": mission,
		"scores": scores,
	}, "\t"))
	f.close()


# ---------------------------------------------------------------- upgrades
func up_level(key: String) -> int:
	return int(upgrades.get(key, 0))


func up_cost(key: String) -> int:
	var info: Dictionary = UPGRADES[key]
	var lvl := up_level(key)
	var costs: Array = info["costs"]
	if lvl >= int(info["max"]):
		return -1
	return int(costs[mini(lvl, costs.size() - 1)])


func buy_upgrade(key: String) -> bool:
	var cost := up_cost(key)
	if cost < 0 or coins < cost:
		return false
	coins -= cost
	upgrades[key] = up_level(key) + 1
	save_profile()
	return true


func start_mass_bonus() -> float:
	return float(up_level("start")) * float(UPGRADES["start"]["step"])


func lane_speed() -> float:
	return 15.0 + float(up_level("speed")) * 2.6


func magnet_radius() -> float:
	return 0.0 if up_level("magnet") == 0 else 2.2 + float(up_level("magnet")) * 1.5


func shields() -> int:
	return up_level("shield")


# ---------------------------------------------------------------- skins
func skin_data() -> Dictionary:
	return SKINS[clampi(skin, 0, SKINS.size() - 1)]


func owns_skin(i: int) -> bool:
	return i in owned_skins


func buy_skin(i: int) -> bool:
	if owns_skin(i):
		return false
	var price := int(SKINS[i]["price"])
	if coins < price:
		return false
	coins -= price
	owned_skins.append(i)
	skin = i
	save_profile()
	return true


func select_skin(i: int) -> void:
	if owns_skin(i):
		skin = i
		save_profile()


# ---------------------------------------------------------------- progress
func stars_for(level: int) -> int:
	return int(stars.get(str(level), 0))


func total_stars() -> int:
	var t := 0
	for k in stars.keys():
		t += int(stars[k])
	return t


func set_stars(level: int, value: int) -> void:
	var key := str(level)
	if value > int(stars.get(key, 0)):
		stars[key] = value
		save_profile()


func finish_level(level: int, earned_stars: int, final_mass: int, coins_gained: int) -> void:
	coins += coins_gained
	best_mass = maxi(best_mass, final_mass)
	unlocked = maxi(unlocked, level + 1)
	set_stars(level, earned_stars)
	scores.append({"level": level, "mass": final_mass, "stars": earned_stars})
	scores.sort_custom(func(a, b): return int(a["mass"]) > int(b["mass"]))
	if scores.size() > 5:
		scores.resize(5)
	mission_add("pools", 1)
	mission_add("coins", coins_gained)
	mission_add("stars", earned_stars)
	save_profile()


# ---------------------------------------------------------------- missions
func _roll_mission() -> void:
	var pick: Dictionary = MISSIONS[randi() % MISSIONS.size()]
	mission = {
		"id": pick["id"], "target": pick["target"], "reward": pick["reward"],
		"progress": 0, "claimed": false, "date": Time.get_date_string_from_system(),
	}


func is_fa() -> bool:
	return lang == "fa"


func set_lang(code: String) -> void:
	lang = code
	lang_set = true
	L10n.fa = (lang == "fa")
	save_profile()


func mission_template() -> String:
	if mission.is_empty():
		return ""
	for x in MISSIONS:
		if x["id"] == mission.get("id", ""):
			return String(x.get("text", ""))
	return ""


func mission_text() -> String:
	if mission.is_empty():
		return ""
	var m: Dictionary = {}
	for x in MISSIONS:
		if x["id"] == mission.get("id", ""):
			m = x
	return String(m.get("text", "")).replace("{n}", str(int(mission.get("target", 0))))


func mission_add(kind: String, amount: int) -> void:
	if mission.is_empty() or String(mission.get("id", "")) != kind:
		return
	mission["progress"] = mini(int(mission.get("target", 0)), int(mission.get("progress", 0)) + amount)
	save_profile()


func mission_done() -> bool:
	return not mission.is_empty() and int(mission.get("progress", 0)) >= int(mission.get("target", 1))


func claim_mission() -> bool:
	if not mission_done() or bool(mission.get("claimed", false)):
		return false
	mission["claimed"] = true
	coins += int(mission.get("reward", 0))
	save_profile()
	return true


# ---------------------------------------------------------------- settings
func toggle_music() -> void:
	music_on = not music_on
	save_profile()


func toggle_sfx() -> void:
	sfx_on = not sfx_on
	save_profile()


func toggle_haptics() -> void:
	haptics_on = not haptics_on
	save_profile()
