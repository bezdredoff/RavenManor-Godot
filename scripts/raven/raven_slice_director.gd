extends RefCounted

## Story order uses stable RM-* progression IDs. Narrative wording/meaning is
## mirrored in data/raven/season1_narrative.json and docs/NARRATIVE_GAMEPLAY_INTEGRATION.md.
const STEPS := [
	{"id":"arrival","kind":"vn","scene":"arrival","title":"Сцена: возвращение и наследство"},
	{"id":"access","kind":"map","title":"Освободить дверь спальни","body":"Пройдите в жилой коридор и расчистите физически заклинившую/заваленную дверь спальни (RM-HS-005). Ванная не является условием доступа."},
	{"id":"level1","kind":"match3","level":"RM-LVL-001","title":"Match-3: Разобрать спальню"},
	{"id":"restore1","kind":"restore","title":"Сделать спальню пригодной для жизни","body":"RM-HS-002 / RM-REST-001: потратить 2 очка подготовленной работы и привести спальню в жилое состояние."},
	{"id":"bedroom","kind":"vn","scene":"bedroom","title":"Сцена: знакомая спальня"},
	{"id":"level2","kind":"match3","level":"RM-LVL-002","title":"Match-3: Найти источник протечки"},
	{"id":"trace","kind":"vn","scene":"trace","title":"Сцена: нужен специалист"},
	{"id":"level3","kind":"match3","level":"RM-LVL-003","title":"Match-3: Подготовить сантехнику"},
	{"id":"restore2","kind":"restore","title":"Починить ванную со специалистом","body":"Игрок подготовил доступ и детали. После появления специалиста RM-REST-002 стоит 4 очка; реальный сантехнический ремонт выполняет мастер, а не Match-3."},
	{"id":"clue","kind":"clue","title":"Осмотреть вещь из детства","body":"Вернуться к найденной при расчистке вещи и записать RM-CLUE-01-CHILDHOOD-OBJECT. Она запускает фрагмент памяти, но не раскрывает сверхъестественную природу жителей."},
	{"id":"night","kind":"vn","scene":"night","title":"Первая ночь: доставка и память"},
	{"id":"complete","kind":"vn","scene":"complete","title":"Утро: кухня, Роуэн и оранжерея"},
	{"id":"done","kind":"done","title":"RM-VS-01 завершён","body":"Бытовой первый этап завершён и сохранён. Следующий сюжетный крючок — кухня и визит Роуэна к саду/оранжерее; причина возвращающейся памяти остаётся тайной."}
]


static func next_step(state: Dictionary) -> Dictionary:
	if not state.storyBeatsSeen.has("RM-BEAT-01-01"): return STEPS[0]
	if not state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"): return STEPS[1]
	if not state.firstClearLevels.has("RM-LVL-001"): return STEPS[2]
	if not state.completedRestorations.has("RM-REST-001"): return STEPS[3]
	if not state.storyBeatsSeen.has("RM-BEAT-01-02"): return STEPS[4]
	if not state.firstClearLevels.has("RM-LVL-002"): return STEPS[5]
	if not state.storyBeatsSeen.has("RM-BEAT-01-03"): return STEPS[6]
	if not state.firstClearLevels.has("RM-LVL-003"): return STEPS[7]
	if not state.completedRestorations.has("RM-REST-002"): return STEPS[8]
	if not state.recordedClues.has("RM-CLUE-01-CHILDHOOD-OBJECT"): return STEPS[9]
	if not state.storyBeatsSeen.has("RM-BEAT-01-04"): return STEPS[10]
	if not state.storyBeatsSeen.has("RM-BEAT-01-05"): return STEPS[11]
	return STEPS[12]


static func events_for(step_id: String) -> Array[Dictionary]:
	match step_id:
		"access": return [
			{"type":"hotspot_state","hotspotId":"RM-HS-005","state":"cleared"},
			{"type":"story_flag_set","flagId":"RM-FLAG-BEDROOM-ACCESS-CLEARED"},
			{"type":"door_unlock","doorId":"RM-DOOR-CORRIDOR-BEDROOM"}]
		"restore1": return [
			{"type":"restoration_purchase","restorationId":"RM-REST-001"},
			{"type":"hotspot_state","hotspotId":"RM-HS-002","state":"restored"}]
		"restore2": return [
			{"type":"story_flag_set","flagId":"service.plumber_available"},
			{"type":"restoration_purchase","restorationId":"RM-REST-002"}]
		"clue": return [
			{"type":"hotspot_state","hotspotId":"RM-HS-004","state":"recorded"},
			{"type":"clue_recorded","clueId":"RM-CLUE-01-CHILDHOOD-OBJECT"}]
	return []
