extends Node

#
#	Global variables
#	Autoloaded which means it's globally available
#	In Godot if it's not autoloaded then probably you're getting it from
#	nodes in the scene tree
#

const DEFAULT_DAMAGE_TYPE = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudcombat.ttl#PhysicalDamage"
const DEFAULT_HAND_SIZE = 2
const DEFAULT_ATTACK_DAMAGE = 3

const BUILT_IN_ACTIONS = {
	BASIC_ATTACK = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/basicAttack.json",
	POISON_ATTACK = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/poisonAttack.json",
	GENERATE_CARD = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/generateCard.json",
	HEALING_WORD = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/healingWord.json",
	HEAL_PARTY = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/healParty.json",
	LEECH_ATTACK = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/leechAttack.json",
	REGEN_SELF = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/regenSelf.json",
	FIRE_ATTACK = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/fireAttack.json",
	GENERATE_CARD_WINGED_PARASITE = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/generateWingedParasite.json"
}

const BUILT_IN_ATTACK_ACTIONS = [
	BUILT_IN_ACTIONS.BASIC_ATTACK,
	BUILT_IN_ACTIONS.POISON_ATTACK,
	BUILT_IN_ACTIONS.LEECH_ATTACK,
	BUILT_IN_ACTIONS.FIRE_ATTACK
]

const BUILT_IN_SPELL_ACTIONS = [
	BUILT_IN_ACTIONS.HEALING_WORD,
	BUILT_IN_ACTIONS.HEAL_PARTY,
	BUILT_IN_ACTIONS.REGEN_SELF
]

const BUILT_IN_EFFECTS = {
	POISON =  "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/effects/poison.json",
}

const GAME_PHASE = {
	PLAYER_SELECTION = 0,
	DECK_BUILDING = 1,
	BATTLE = 2,
	BATTLE_SUMMARY = 3
}

#
#	Ontology constants
#	When using Linked Data we will often be referring to the URI of resources on the web
#	More readable if these are enums rather than long strings
#

const MUD_LOGIC = {
	ACTOR_BINDING = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudlogic.ttl#ActorBinding",
	TARGET_BINDING = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudlogic.ttl#TargetBinding",
	WITNESS_BINDING = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudlogic.ttl#WitnessBinding",
	EVENT = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudlogic.ttl#Event"
}

const MUD_CHAR = {
	Character = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudchar.ttl#Character"
}

const MUD_COMBAT = {
	HealthPoints = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudcombat.ttl#HealthPoints",
	ManaPointsType = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudcombat.ttl#ManaPoints",
	hasHealthPoints = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudcombat.ttl#hasHealthPoints",
	hasManaPoints = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudcombat.ttl#hasManaPoints",
	maximumP = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudcombat.ttl#maximumP",
	currentP = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudcombat.ttl#currentP",
}

# to access: Globals.MUD_LOGIC.ACTOR_BINDING

#
#	Caching remote resources in local data to avoid needing to fetch
#

const DECK_CACHE = {
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/deck/coreOptionals.json": "res://assets/rdf/deck/coreOptionals.json"
}

const AVATAR_CACHE = {
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/avatar/ospreyWithers.json": "res://assets/rdf/avatar/ospreyWithers.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/avatar/sumeri.json": "res://assets/rdf/avatar/sumeri.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/avatar/arthurPendragon.json": "res://assets/rdf/avatar/arthurPendragon.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/avatar/igneusBalvadere.json": "res://assets/rdf/avatar/igneusBalvadere.json",
}

const PORTRAIT_CACHE = {
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/ospreyWithers.png": "res://assets/portrait/ospreyWithers.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/dryad.png": "res://assets/portrait/dryad.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/ghost.png": "res://assets/portrait/ghost.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/waylan.png": "res://assets/portrait/waylan.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/kingArthur.png": "res://assets/portrait/kingArthur.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/igneusBalvadere.png": "res://assets/portrait/igneusBalvadere.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/gromm.png": "res://assets/portrait/card/gromm.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/skeletalWarrior.png": "res://assets/portrait/card/skeletalWarrior.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/zombie.png": "res://assets/portrait/card/zombie.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/bogMonster.png": "res://assets/portrait/card/bogMonster.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/elf.png": "res://assets/portrait/card/elf.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/mysteriousProtector.png": "res://assets/portrait/card/mysteriousProtector.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/oldRanger.png": "res://assets/portrait/card/oldRanger.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/forestWitch.png": "res://assets/portrait/card/forestWitch.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/garethHeartspear.png": "res://assets/portrait/card/garethHeartspear.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/heleswynn.png": "res://assets/portrait/card/heleswynn.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/monasticHolds.png": "res://assets/portrait/card/monasticHolds.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/industry.png": "res://assets/portrait/card/industry.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/tamTupence.png": "res://assets/portrait/card/tamTupence.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/meetingPlace.png": "res://assets/portrait/card/meetingPlace.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/cove.png": "res://assets/portrait/card/cove.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/dungeon.png": "res://assets/portrait/card/dungeon.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/dwarfWarrior.png": "res://assets/portrait/card/dwarfWarrior.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/graveyard.png": "res://assets/portrait/card/graveyard.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/knight.png": "res://assets/portrait/card/knight.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/knight2.png": "res://assets/portrait/card/knight2.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/peasant.png": "res://assets/portrait/card/peasant.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/merlin.png": "res://assets/portrait/card/merlin.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/courtWitch.png": "res://assets/portrait/card/courtWitch.png",
    "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/dwarfHunter.png": "res://assets/portrait/card/dwarfHunter.png",

	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/flameImp.png": "res://assets/portrait/card/flameImp.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/lesserThrall.png": "res://assets/portrait/card/lesserThrall.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/lycanthropeAlpha.png": "res://assets/portrait/card/lycanthropeAlpha.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/lycanthropePup.png": "res://assets/portrait/card/lycanthropePup.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/swarmMother.png": "res://assets/portrait/card/swarmMother.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/card/wingedParasite.png": "res://assets/portrait/card/wingedParasite.png",

	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/event/travellerArrives.png": "res://assets/portrait/event/travellerArrives.png",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/event/unexpectedDiscovery.png": "res://assets/portrait/event/unexpectedDiscovery.png",
}

const ACTION_CACHE = {
	
}

const EVENT_CACHE = {
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/events/travellerArrives.json": "res://assets/rdf/events/travellerArrives.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/events/unexpectedDiscovery.json": "res://assets/rdf/events/unexpectedDiscovery.json",
}

const CARD_CACHE = {
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/monsters/flameImp.json": "res://assets/rdf/monsters/flameImp.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/monsters/lesserThrall.json": "res://assets/rdf/monsters/lesserThrall.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/monsters/lycanthropeAlpha.json": "res://assets/rdf/monsters/lycanthropeAlpha.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/monsters/lycanthropePup.json": "res://assets/rdf/monsters/lycanthropePup.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/monsters/swarmMother.json": "res://assets/rdf/monsters/swarmMother.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/monsters/wingedParasite.json": "res://assets/rdf/monsters/wingedParasite.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/monsters/zombie.json": "res://assets/rdf/monsters/zombie.json",

	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/basicAttack.json": "res://assets/rdf/actions/basicAttack.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/poisonAttack.json": "res://assets/rdf/actions/poisonAttack.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/generateWingedParasite.json": "res://assets/rdf/actions/generateWingedParasite.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/leechAttack.json": "res://assets/rdf/actions/leechAttack.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/regenSelf.json": "res://assets/rdf/actions/regenSelf.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/fireAttack.json": "res://assets/rdf/actions/fireAttack.json",
	"https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/actions/healingWord.json": "res://assets/rdf/actions/healingWord.json"
}

const CACHES = [
	DECK_CACHE,
	AVATAR_CACHE,
	PORTRAIT_CACHE,
	ACTION_CACHE,
	EVENT_CACHE,
	CARD_CACHE
]
