class_name PetGachaStore
extends RefCounted
const COST_CRYSTALS := 0
const COMMON_RATE := 0.72
const RARE_RATE := 0.25
const HIDDEN_RATE := 0.03
const RARE_PITY := 4
const HIDDEN_SOFT_PITY_START := 13
const HIDDEN_HARD_PITY := 20
const IDS := ["cat","dog","hamster","rabbit","bear","hidden_cat"]
var storage := SaveStore.new()
var rng := RandomNumberGenerator.new()
var error := ""
var data: Dictionary:
    get: return storage.data

func _init() -> void:
    storage.path = "user://pet_gacha.json"
    storage.data = fresh()
    rng.randomize()

static func fresh() -> Dictionary:
    return {"version":1,"owned":{"cat":0,"dog":0,"hamster":0,"rabbit":0,"bear":0,"hidden_cat":0},"total":0,"rare_misses":0,"hidden_misses":0,"recent":[]}

static func integer(v: Variant, maximum := 2000000000) -> bool:
    return (v is int or v is float) and is_finite(float(v)) and v>=0 and v<=maximum and float(v)==floorf(float(v))

static func valid(d: Variant) -> bool:
    if not d is Dictionary or d.get("version")!=1 or not d.get("owned") is Dictionary or not d.get("recent") is Array: return false
    for key in ["total","rare_misses","hidden_misses"]:
        if not integer(d.get(key)): return false
    if d.rare_misses>=RARE_PITY or d.hidden_misses>=HIDDEN_HARD_PITY or d.rare_misses>d.total or d.hidden_misses>d.total: return false
    var total := 0
    if d.owned.size()!=IDS.size(): return false
    for id in IDS:
        if not integer(d.owned.get(id)): return false
        total += int(d.owned[id])
    if total!=int(d.total) or d.recent.size()!=mini(int(d.total),20): return false
    for i in range(d.recent.size()):
        var entry = d.recent[i]
        if not entry is Dictionary or entry.get("id") not in IDS or not integer(entry.get("draw")) or int(entry.draw)!=int(d.total)-d.recent.size()+i+1: return false
    return true

func load_collection() -> bool:
    error = ""
    if not FileAccess.file_exists(storage.path): return true
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(storage.path))!=OK or not valid(parser.data):
        storage.writable = false
        error = "收藏存档无法读取，已停止覆盖。请保留原文件后检查。"
        return false
    var normalized: Dictionary = parser.data
    normalized.version = 1
    for key in ["total","rare_misses","hidden_misses"]: normalized[key] = int(normalized[key])
    for id in IDS: normalized.owned[id] = int(normalized.owned[id])
    for entry in normalized.recent: entry.draw = int(entry.draw)
    storage.data = normalized
    storage.writable = true
    return true

func hidden_chance() -> float:
    var next := int(data.hidden_misses)+1
    if next>=HIDDEN_HARD_PITY: return 1.0
    return HIDDEN_RATE+maxi(0,next-HIDDEN_SOFT_PITY_START+1)*0.05

func roll_kind(roll: float) -> int:
    var hidden := hidden_chance()
    if roll<hidden: return 5
    if int(data.rare_misses)>=RARE_PITY-1 or roll<hidden+RARE_RATE: return rng.randi_range(2,4)
    return rng.randi_range(0,1)

func draw() -> Dictionary:
    if not storage.writable: return {"ok":false,"error":error}
    var kind := roll_kind(rng.randf())
    var candidate := data.duplicate(true)
    candidate.owned[IDS[kind]] += 1
    candidate.total += 1
    candidate.rare_misses = int(data.rare_misses)+1 if kind<2 else 0
    candidate.hidden_misses = 0 if kind==5 else int(data.hidden_misses)+1
    candidate.recent.append({"id":IDS[kind],"draw":candidate.total})
    if candidate.recent.size()>20: candidate.recent.pop_front()
    # Same atomic temp-file/rename transaction used by adventure saves. Award first, animate second.
    if not storage.commit(candidate):
        error = "收藏写入失败，本次未出货，请检查存储空间后重试。"
        return {"ok":false,"error":error}
    error = ""
    return {"ok":true,"kind":kind,"id":IDS[kind],"rarity":2 if kind==5 else 1 if kind>=2 else 0,"draw":data.total,"count":data.owned[IDS[kind]]}
