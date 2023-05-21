extends Node2D

#
#	Service for interfacing with RDF
#	We should decide fairly quickly if we want to do this in a C# script so we can use an RDF library
#

func get_texture_from_jsonld(depiction_url):	
	if depiction_url == null:
		return load(Globals.PORTRAIT_CACHE["https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/ospreyWithers.png"])
	
	if depiction_url in Globals.PORTRAIT_CACHE.keys():
		return load(Globals.PORTRAIT_CACHE[depiction_url])
	
	print("ERR: requested portrait not in cache, remote portraits unsupported for Avatars")
	print(depiction_url)
	return load(Globals.PORTRAIT_CACHE["https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/ospreyWithers.png"])

func _load_from_cache(cache, urlid):
	if urlid in cache.keys():
		var save_file = File.new()
		save_file.open(cache[urlid], File.READ)
		return parse_json(save_file.get_as_text())
	return null

func load_event_from_jsonld(urlid):
	# TODO: read remote Event Urlid if not in cache
	return _load_from_cache(Globals.EVENT_CACHE, urlid)

func load_card_from_jsonld(urlid):
	return _load_from_cache(Globals.CARD_CACHE, urlid)

func obj_through_urlid(obj):
	"""
	:return: an expanded version of the object (if it's just a urlid')
	"""
	if len(obj.keys()) == 1 and "@id" in obj:
		obj = load_card_from_jsonld(obj["@id"])
	return obj
