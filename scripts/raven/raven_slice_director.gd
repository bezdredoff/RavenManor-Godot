extends RefCounted

const STEPS := [
	{"id":"access","kind":"map","title":"Освободить дверь спальни","body":"Нажмите на завал у двери (RM-HS-005), чтобы открыть ранний доступ в спальню."},
	{"id":"arrival","kind":"vn","scene":"arrival","title":"Сцена: возвращение"},
	{"id":"level1","kind":"match3","level":"RM-LVL-001","title":"Match-3: Пыльные коробки"},
	{"id":"restore1","kind":"restore","title":"Восстановить спальню","body":"RM-HS-002: починить кровать и расчистить комнату за 2 очка."},
	{"id":"bedroom","kind":"vn","scene":"bedroom","title":"Сцена: открытая спальня"},
	{"id":"level2","kind":"match3","level":"RM-LVL-002","title":"Match-3: Следы под обоями"},
	{"id":"trace","kind":"vn","scene":"trace","title":"Сцена: спрятанный след"},
	{"id":"level3","kind":"match3","level":"RM-LVL-003","title":"Match-3: Запертый водопровод"},
	{"id":"restore2","kind":"restore","title":"Восстановить ванную","body":"Специалист доступен. Восстановление RM-REST-002 стоит 4 очка."},
	{"id":"clue","kind":"clue","title":"Осмотреть найденную вещь","body":"Записать RM-CLUE-01-CHILDHOOD-OBJECT в журнал улик."},
	{"id":"night","kind":"vn","scene":"night","title":"Ночной эпизод"},
	{"id":"complete","kind":"vn","scene":"complete","title":"Финал вертикального среза"},
	{"id":"done","kind":"done","title":"RM-VS-01 завершён","body":"Весь маршрут сохранён. Можно перезагрузить страницу и продолжить с этого состояния."}
]


static func next_step(state: Dictionary) -> Dictionary:
	if not state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"): return STEPS[0]
	if not state.storyBeatsSeen.has("RM-BEAT-01-01"): return STEPS[1]
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
		"clue": return [{"type":"clue_recorded","clueId":"RM-CLUE-01-CHILDHOOD-OBJECT"}]
	return []
