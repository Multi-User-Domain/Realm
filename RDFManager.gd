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
