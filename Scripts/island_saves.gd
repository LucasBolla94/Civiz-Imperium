extends Node
## Immutable island revisions + an atomic catalog publish progress and its image together.
const SAVE = preload("res://Scripts/save_game.gd")
const THUMBNAIL = preload("res://Scripts/island_thumbnail.gd")
const LIMIT = 5
var directory := "user://islands_v006"
var catalog := {"version":6,"slots":[{},{},{},{},{}],"migrated":false}
var active_id := ""
var pending_name := ""
var pending_index := -1
var error := ""
var writable := true
var fail_writes := false # Fault injection for atomic-write regression tests.
var fail_catalog_write := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	open_catalog()
	if writable: migrate(SAVE.PATH)

func token() -> String: return Crypto.new().generate_random_bytes(16).hex_encode()
func catalog_path() -> String: return directory.path_join("catalog.save")

func read_record(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {}
	if file.get_length()<4: return {}
	var size := file.get_32()
	if size<1 or size>file.get_length()-4 or size>134217728: return {}
	file.seek(0)
	var envelope = file.get_var(false)
	if not envelope is Dictionary or not envelope.get("payload") is PackedByteArray: return {}
	if envelope.get("digest") != envelope.payload.hex_encode().sha256_text(): return {}
	var record = bytes_to_var(envelope.payload)
	return record if record is Dictionary else {}

func atomic_write(path: String, data: Dictionary) -> bool:
	if fail_writes: return false
	if fail_catalog_write and path==catalog_path(): return false
	var payload := var_to_bytes(data)
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return false
	file.store_var({"version":6,"payload":payload,"digest":payload.hex_encode().sha256_text()})
	file.flush()
	var status := file.get_error()
	file.close()
	if status != OK or read_record(path+".tmp") != data: return false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak") and DirAccess.remove_absolute(path+".bak") != OK: return false
		if DirAccess.rename_absolute(path,path+".bak") != OK: return false
	if DirAccess.rename_absolute(path+".tmp",path) != OK:
		if FileAccess.file_exists(path+".bak"): DirAccess.rename_absolute(path+".bak",path)
		return false
	return true

func valid_catalog(data: Dictionary) -> bool:
	if data.get("version") != 6 or not data.get("slots") is Array or data.slots.size() != LIMIT or not data.get("migrated") is bool: return false
	var ids := {}
	for slot in data.slots:
		if not slot is Dictionary: return false
		if slot.is_empty(): continue
		if not slot.get("id") is String or slot.id.length()!=32 or not slot.id.is_valid_hex_number(): return false
		if ids.has(slot.id) or not slot.get("name") is String: return false
		if not slot.get("file") is String or slot.file.get_file()!=slot.file or not slot.file.begins_with(slot.id+"_"): return false
		ids[slot.id]=true
	return true

func open_catalog() -> void:
	error = ""
	writable = true
	DirAccess.make_dir_recursive_absolute(directory)
	var loaded := read_record(catalog_path())
	if valid_catalog(loaded): catalog=loaded; return
	if FileAccess.file_exists(catalog_path()) or FileAccess.file_exists(catalog_path()+".bak"):
		loaded=read_record(catalog_path()+".bak")
		if valid_catalog(loaded):
			catalog=loaded
			error="Catálogo recuperado da cópia de segurança."
			# Preserve the known-good backup until a new catalog is successfully written.
			if FileAccess.file_exists(catalog_path()):
				DirAccess.rename_absolute(catalog_path(),catalog_path()+".damaged-"+token())
			return
		writable=false
		error="Não foi possível ler as ilhas. Seus arquivos foram preservados."
	else: catalog={"version":6,"slots":[{},{},{},{},{}],"migrated":false}

func valid_name(value: String) -> bool:
	var clean := value.strip_edges()
	if clean.is_empty() or clean.length()>40: return false
	for character in clean:
		if character.unicode_at(0)<32 or character in "/\\": return false
	return true

func begin_new(index: int, value: String) -> bool:
	if not writable or index<0 or index>=LIMIT or not catalog.slots[index].is_empty(): return failure("Os cinco espaços estão ocupados. Apague uma ilha para criar outra.")
	if not valid_name(value): return failure("Use um nome de 1 a 40 caracteres, sem barras ou quebras de linha.")
	active_id=""
	pending_index=index
	pending_name=value.strip_edges()
	return true

func failure(message: String) -> bool:
	error=message
	return false

func active_index() -> int:
	for i in LIMIT:
		if catalog.slots[i].get("id","")==active_id and active_id!="": return i
	return -1

func store_island(index: int, id: String, name: String, data: Dictionary, imported := false) -> bool:
	if not writable or not SAVE.new().valid(data): return failure("Não foi possível salvar a partida.")
	var record := {"version":6,"id":id,"name":name,"data":data,"population":data.workers.size(),"level":data.village_level,"thumbnail":THUMBNAIL.render(data)}
	var filename := id+"_"+token()+".save"
	if not atomic_write(directory.path_join(filename),record): return failure("Não foi possível salvar a partida. O salvamento anterior foi preservado.")
	var verified := read_record(directory.path_join(filename))
	if verified != record: return failure("Não foi possível verificar o salvamento. Seus arquivos foram preservados.")
	var next := catalog.duplicate(true)
	next.slots[index]={"id":id,"name":name,"file":filename}
	if imported: next.migrated=true
	if not atomic_write(catalog_path(),next): return failure("Não foi possível salvar a partida. O salvamento anterior foi preservado.")
	catalog=next
	error=""
	prune_revisions()
	return true

func save_active(data: Dictionary) -> bool:
	var index := active_index()
	if index>=0:
		var slot: Dictionary=catalog.slots[index]
		return store_island(index,slot.id,slot.name,data)
	if pending_index>=0 and catalog.slots[pending_index].is_empty():
		var id := token()
		if not store_island(pending_index,id,pending_name,data): return false
		active_id=id
		pending_index=-1
		pending_name=""
		return true
	return failure("Escolha uma ilha no menu Jogar antes de salvar.")

func island(index: int) -> Dictionary:
	if index<0 or index>=LIMIT or catalog.slots[index].is_empty(): return {}
	var slot: Dictionary=catalog.slots[index]
	var record := read_record(directory.path_join(slot.file))
	if record.get("id")!=slot.id or record.get("name")!=slot.name or not SAVE.new().valid(record.get("data")): return {}
	if not record.get("thumbnail") is PackedByteArray: return {}
	if record.get("population")!=record.data.workers.size() or record.get("level")!=record.data.village_level: return {}
	return record

func activate(index: int) -> bool:
	if island(index).is_empty(): return failure("Não foi possível ler esta ilha. Seus arquivos foram preservados.")
	active_id=catalog.slots[index].id
	pending_index=-1
	return true

func load_active() -> Dictionary:
	var record := island(active_index())
	if record.is_empty(): failure("Não foi possível ler esta ilha. Seus arquivos foram preservados.")
	return record.get("data",{})

func delete_island(id: String) -> bool:
	var next := catalog.duplicate(true)
	var found := false
	for i in LIMIT:
		if next.slots[i].get("id","")==id: next.slots[i]={}; found=true
	if not writable or not found or not atomic_write(catalog_path(),next): return failure("Não foi possível apagar a ilha. Seus arquivos foram preservados.")
	catalog=next
	if active_id==id: active_id=""
	# The deletion receipt also replaces the backup, so recovery cannot resurrect a deleted import.
	atomic_write(catalog_path()+".bak",next)
	prune_revisions()
	return true

func migrate(legacy_path: String) -> bool:
	if catalog.migrated or not FileAccess.file_exists(legacy_path): return true
	var data := read_record(legacy_path)
	if not SAVE.new().valid(data): return failure("O salvamento antigo não pôde ser importado. O original foi preservado.")
	var index := -1
	for i in LIMIT:
		if catalog.slots[i].is_empty(): index=i; break
	if index<0: return failure("A importação precisa de um espaço livre. O salvamento antigo foi preservado.")
	return store_island(index,token(),get_node("/root/Localization").text("Ilha importada"),data,true)

func prune_revisions() -> void:
	var keep := {}
	for ledger in [catalog,read_record(catalog_path()+".bak")]:
		for slot in ledger.get("slots",[]):
			if not slot.is_empty(): keep[slot.file]=true
	for file in DirAccess.get_files_at(directory):
		# Only our own immutable revisions are eligible. Originals and damaged catalogs are untouched.
		if file.ends_with(".save") and file.length()==70 and file[32]=="_" and file.substr(0,32).is_valid_hex_number() and file.substr(33,32).is_valid_hex_number() and not keep.has(file):
			DirAccess.remove_absolute(directory.path_join(file))
