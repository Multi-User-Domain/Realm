extends Node

#
#	Global variables
#	Autoloaded which means it's globally available
#	In Godot if it's not autoloaded then probably you're getting it from
#	nodes in the scene tree
#

const DEFAULT_HAND_SIZE = 5

#
#	Ontology constants
#	When using Linked Data we will often be referring to the URI of resources on the web
#	More readable if these are enums rather than long strings
#

const MUD_LOGIC = {
	ACTOR_BINDING = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudlogic.ttl#ActorBinding",
	TARGET_BINDING = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudlogic.ttl#TargetBinding",
	WITNESS_BINDING = "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudlogic.ttl#WitnessBinding"
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
