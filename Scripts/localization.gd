extends Node
signal language_changed
const PREFERENCE = "user://language.cfg"
var language := "en"
var rules: Array = []
var cache := {}

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(PREFERENCE) == OK: language = config.get_value("interface", "language", "en")
	if language not in ["en", "pt"]: language = "en"
	TranslationServer.set_locale(language)
	var file := FileAccess.open("res://Assets/Localization/en_pt.tsv", FileAccess.READ)
	var entries: Array = []
	while not file.eof_reached():
		var line := file.get_line().split("\t", true, 1)
		if line.size() == 2: entries.append([line[0].c_unescape(), line[1].c_unescape()])
	entries.sort_custom(func(a,b): return a[0].length() > b[0].length())
	for entry in entries:
		var pattern := RegEx.new()
		pattern.compile(template_pattern(entry[0]))
		var placeholder := RegEx.new()
		placeholder.compile("%(?:[0-9.]*[dfs]|%)")
		var replacement: String = entry[1]
		var count := 0
		var matches := placeholder.search_all(replacement)
		var parts: Array = []
		for found in matches:
			count += 0 if found.get_string() == "%%" else 1
			parts.append("%" if found.get_string() == "%%" else "$%d" % count)
		for index in range(matches.size()-1, -1, -1):
			var found = matches[index]
			replacement = replacement.substr(0,found.get_start()) + parts[index] + replacement.substr(found.get_end())
		rules.append({"pattern":pattern,"replacement":replacement})

func template_pattern(value: String) -> String:
	var output := ""
	var index := 0
	while index < value.length():
		var character := value[index]
		if character == "%":
			var end := index + 1
			while end < value.length() and value[end] in "0123456789.": end += 1
			if end < value.length() and value[end] in "dsf%":
				output += "(.+?)" if value[end] == "s" else ("%" if value[end] == "%" else "([0-9]+(?:[.,][0-9]+)?)")
				index = end + 1
				continue
		output += ("\\" if character in "\\.^$|?*+()[]{}" else "") + character
		index += 1
	if not value.is_empty():
		if value[0].to_lower() != value[0].to_upper(): output = "(?<![A-Za-zÀ-ÿ])" + output
		if value[-1].to_lower() != value[-1].to_upper(): output += "(?![A-Za-zÀ-ÿ])"
	return output

func text(source: String) -> String:
	if language == "pt" or source.is_empty(): return source
	if cache.has(source): return cache[source]
	var result := source
	for rule in rules: result = rule.pattern.sub(result, rule.replacement, true)
	if cache.size() >= 4096: cache.clear()
	cache[source] = result
	return result

func render(node: Node) -> void:
	# Keep canonical text beside the last presentation. Changing language never
	# mutates game data, resource IDs, resident names, or an already formatted value.
	var properties: Array[String] = []
	if node is Label or node is Button: properties.append("text")
	if node is Control: properties.append("tooltip_text")
	if node is Window: properties.append("title")
	if node is AcceptDialog: properties.append("dialog_text")
	if node.get_meta("l10n_skip",false): properties.clear()
	for property in properties:
		if property in node.get_meta("l10n_skip_properties",[]): continue
		var current: String = node.get(property)
		var key := "l10n_" + property
		if not node.has_meta(key) or current != node.get_meta(key + "_shown", ""):
			node.set_meta(key, current)
		var shown := text(node.get_meta(key))
		node.set(property, shown)
		node.set_meta(key + "_shown", shown)
	for child in node.get_children(): render(child)
	# Dialog action buttons are internal Godot children, outside get_children().
	if node is AcceptDialog: render(node.get_ok_button())
	if node is ConfirmationDialog: render(node.get_cancel_button())

func choose(value: String) -> void:
	if value not in ["en", "pt"]: return
	language = value
	TranslationServer.set_locale(value)
	cache.clear()
	var config := ConfigFile.new()
	config.set_value("interface", "language", value)
	config.save(PREFERENCE)
	language_changed.emit()

func selector() -> OptionButton:
	var control := OptionButton.new()
	control.add_item("English")
	control.add_item("Português")
	control.select(0 if language == "en" else 1)
	control.item_selected.connect(func(index): choose("en" if index == 0 else "pt"))
	var reference: WeakRef = weakref(control)
	language_changed.connect(func():
		var option = reference.get_ref()
		if option != null: option.select(0 if language == "en" else 1)
	)
	return control
