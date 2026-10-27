extends RefCounted

# Port of src/ui/vnDialoguePaging.ts for the three supported whitespace locales.
# Font/layout measurement is supplied by the caller; authored words stay intact.
static func normalize(value: String) -> String:
	var whitespace := RegEx.create_from_string("\\s+")
	return whitespace.sub(value, " ", true).strip_edges()


static func continuation(value: String, has_more: bool) -> String:
	if not has_more:
		return value
	var trimmed := value.strip_edges(false, true)
	if trimmed.ends_with("…"):
		return trimmed
	if not trimmed.is_empty() and trimmed.right(1) in ".;:。；：":
		trimmed = trimmed.left(-1)
	return trimmed + "…"


static func sentences(value: String, locale: String) -> Array[String]:
	var result: Array[String] = []
	if OS.has_feature("web"):
		# Use the same browser ICU segmentation as the production web runtime.
		var script := "typeof Intl !== 'undefined' && typeof Intl.Segmenter === 'function' ? JSON.stringify(Array.from(new Intl.Segmenter(%s,{granularity:'sentence'}).segment(%s),e=>e.segment)) : null" % [JSON.stringify(locale), JSON.stringify(value)]
		var encoded: Variant = JavaScriptBridge.eval(script)
		var segments: Variant = JSON.parse_string(encoded) if encoded is String else null
		if segments is Array:
			for segment: String in segments:
				var cleaned := normalize(segment)
				if not cleaned.is_empty(): result.append(cleaned)
	if result.is_empty():
		# Same fallback as TypeScript when browser Intl is unavailable.
		var pattern := RegEx.create_from_string("[^.!?…]+(?:[.!?…]+[»”\"')\\]]*|$)")
		for found in pattern.search_all(value):
			var cleaned := normalize(found.get_string())
			if not cleaned.is_empty(): result.append(cleaned)
	return result if not result.is_empty() else [value]


static func _word_count(value: String) -> int:
	var meaningful := RegEx.create_from_string("[\\p{L}\\p{N}]")
	var count := 0
	for token in value.split(" ", false):
		if meaningful.search(token) != null: count += 1
	return count


static func _join(units: Array[String]) -> String:
	var result := ""
	for unit in units:
		var separator := " "
		if result.is_empty() or unit.left(1) in ",.;:!?…%)]}>»”'’" or result.right(1) in "([{<«“'’":
			separator = ""
		result += separator + unit
	return normalize(result)


static func _boundary(units: Array[String], fits: Callable, minimum_tail: int, allow_small: bool = false) -> Dictionary:
	for cut in range(units.size() - 1, 0, -1):
		var head := _join(units.slice(0, cut))
		var tail := _join(units.slice(cut))
		if head.is_empty() or tail.is_empty(): continue
		if head.right(1) in "([{<«“" or tail.left(1) in ",.;:!?…%)]}>»”": continue
		if not allow_small and _word_count(head) < 3: continue
		if minimum_tail > 0 and _word_count(tail) < minimum_tail: continue
		if fits.call(continuation(head, true)): return {"head": head, "tail": tail}
	return {}


static func paginate(value: String, fits: Callable, locale: String = "ru", sentence_units: Array[String] = []) -> Array[String]:
	var remaining := normalize(value)
	var pages: Array[String] = []
	if remaining.is_empty(): return [""]
	for iteration in range(256):
		if fits.call(remaining):
			pages.append(remaining)
			break
		var sentence_parts := sentence_units if pages.is_empty() and not sentence_units.is_empty() else sentences(remaining, locale)
		var split := _boundary(sentence_parts, fits, 4)
		if split.is_empty(): split = _boundary(sentence_parts, fits, 3)
		var words: Array[String] = []
		words.assign(remaining.split(" ", false))
		for options in [[4, false], [3, false], [3, true], [0, true]]:
			if split.is_empty(): split = _boundary(words, fits, options[0], options[1])
		if split.is_empty():
			# Source last resort: a genuinely unbreakable token or unusable fit.
			# TextServer returns extended grapheme boundaries, preserving emoji marks.
			var breaks := TextServerManager.get_primary_interface().string_get_character_breaks(remaining, locale)
			for index in range(breaks.size() - 1, 0, -1):
				var cut := breaks[index]
				var head := remaining.left(cut)
				var tail := remaining.substr(cut)
				if RegEx.create_from_string("[\\p{L}\\p{N}]").search_all(tail).size() < 4: continue
				if fits.call(continuation(head, true)):
					split = {"head": head, "tail": normalize(tail)}
					break
		if split.is_empty():
			pages.append(remaining)
			break
		pages.append(split.head)
		remaining = split.tail
	# Prevent one/two-word final tails when the next page can absorb a word.
	for index in range(pages.size() - 1, 0, -1):
		while _word_count(pages[index]) < 3:
			if not pages[index - 1].contains(" ") and not pages[index].contains(" "): break
			var previous := pages[index - 1].split(" ", false)
			if previous.size() <= 1: break
			var moved := previous[previous.size() - 1]
			previous.remove_at(previous.size() - 1)
			var candidate := _join([moved, pages[index]])
			if not fits.call(continuation(candidate, index < pages.size() - 1)): break
			pages[index - 1] = " ".join(previous)
			pages[index] = candidate
	return pages
