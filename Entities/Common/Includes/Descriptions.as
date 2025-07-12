// Descriptions.as
//	"human friendly" descriptions for objects, which are localised at script compile time.
//
// TODO: consider if we need to have these re-initialised somehow,
//	as the user can change locale after this is run and the strings
//	cannot be changed after-the-fact.
//	It's good for performance to just translate once though.

namespace Descriptions
{
	const string
	bomb                       = getTranslatedString("Bombs for Knight only."),
	waterbomb                  = getTranslatedString("Water bomb for Knight. Can extinguish fires and stun enemies."),
	mine                       = getTranslatedString("An explosive mine. Triggered by contact with an enemy."),
	keg                        = getTranslatedString("Highly explosive powder keg for Knight only."),
	satchel                    = getTranslatedString("Fire satchel for Knight only."), //OLD

	arrows                     = getTranslatedString("Arrows for Archer and mounted bow."),
	waterarrows                = getTranslatedString("Water arrows for Archer. Can extinguish fires and stun enemies."),
	firearrows                 = getTranslatedString("Fire arrows used to set wooden structures on fire."),
	bombarrows                 = getTranslatedString("Bomb arrows for Archer."),

	ram                        = getTranslatedString("A siege engine designed to break open walls and fortifications."), //OLD
	catapult                   = getTranslatedString("A stone throwing, ridable siege engine, requiring a crew of two."),
	ballista                   = getTranslatedString("A bolt-firing pinpoint accurate siege engine, requiring a crew of two."),
	ballista_ammo              = getTranslatedString("Piercing bolts for ballista."),
	ballista_bomb_ammo         = getTranslatedString("Explosive bolts for ballista."),
	outpost                    = getTranslatedString("A deployable respawn point that allows class change. Has a storage and a tunnel that allows fast travel."),
	bomber                     = getTranslatedString("Air vehicle, can carry two people and some cargo."),

	stone                      = getTranslatedString("Raw stone material."),
	wood                       = getTranslatedString("Raw wood material."),

	lantern                    = getTranslatedString("Lanterns help with mining in the dark, and lighten the mood."),
	bucket                     = getTranslatedString("Bucket for storing water. Useful for fighting fires."),
	filled_bucket              = getTranslatedString("A wooden bucket pre-filled with water for fighting fires."),
	sponge                     = getTranslatedString("Water absorbing sponge. Useful for unflooding tunnels and reducing water stuns."),
	boulder                    = getTranslatedString("A stone boulder useful for crushing enemies."),
	trampoline                 = getTranslatedString("A trampoline used for bouncing and jumping over enemy walls."),
	saw                        = getTranslatedString("A circular saw that turns tree logs into wood material."),
	drill                      = getTranslatedString("A mining drill. Increases speed of digging and gathering resources, but gains only half the possible resources."),
	crate                      = getTranslatedString("An empty wooden crate for storing and transporting inventory."),
	food                       = getTranslatedString("For healing. Don't think about this too much."),

	tradingpost                = getTranslatedString("A trading post. Requires a trader to reside inside."),
	excalibur                  = getTranslatedString("Excalibur is the legendary sword of King Arthur, attributed with magical powers to conquer all enemies."),
	ladder                     = getTranslatedString("A simple wooden ladder for climbing over defenses."),


	heart                      = getTranslatedString("A health regenerating heart."),
	sack                       = getTranslatedString("A sack for storing more inventory on your back."), //OLD
	tree_bushy                 = getTranslatedString("A seedling of an oak tree ready for planting."),
	tree_pine                  = getTranslatedString("A seedling of a pine tree ready for planting."),
	flower                     = getTranslatedString("A decorative flower seedling."),
	grain                      = getTranslatedString("Grain used as food."),
	wooden_door                = getTranslatedString("Wooden swing door."),
	spikes                     = getTranslatedString("Stone spikes used as a defense around fortifications."),

	mounted_bow                = getTranslatedString("A stationary arrow-firing death machine."),
	dinghy                     = getTranslatedString("A small boat with two rowing positions and a large space for cargo."),
	longboat                   = getTranslatedString("A fast rowing boat used for quickly getting across water."),
	warboat                    = getTranslatedString("A slow armoured boat which acts also as a water base for respawn and class change."),
	tunnel                     = getTranslatedString("A tunnel for quick transportation."),


	factory                    = getTranslatedString("A generic factory. Requires Research Room, technology upgrade and big enough population to produce items."), //OLD
	kitchen                    = getTranslatedString("Kitchen produces food which heal wounds."), //OLD
	nursery                    = getTranslatedString("A plant nursery with grain, oak and pine tree seeds."), //OLD
	barracks                   = getTranslatedString("Barracks allow changing class to Archer or Knight."), //OLD
	storage                    = getTranslatedString("A storage than can hold materials and items and share them with other storages."), //OLD

	militarybasics             = getTranslatedString("Bombs for Knights & arrows for Archers.\nAutomatically distributed on respawn."),
	explosives                 = getTranslatedString("Items used for blowing stuff up."),
	pyro                       = getTranslatedString("Items used for lighting things on fire."),
	stonetech                  = getTranslatedString("When team is in possession of stone construction technology it allows builders to make stone walls, doors, traps and spikes."), //OLD
	dorm                       = getTranslatedString("Dorm increases population count and allows spawning and healing inside. Requires a migrant."), //OLD
	research                   = getTranslatedString("Research room."), //OLD
	buildershop                = getTranslatedString("Builder workshop for building utilities and changing class to Builder"),
	knightshop                 = getTranslatedString("Knight workshop for building explosives and changing class to Knight"),
	archershop                 = getTranslatedString("Archer workshop for building arrows and changing class to Archer"),
	vehicleshop                = getTranslatedString("Siege workshop for building wheeled siege engines"),
	boatshop                   = getTranslatedString("Naval workshop for building boats"),
	quarters                   = getTranslatedString("Place of merriment and healing"),
	storagecache               = getTranslatedString("A Cache for storing your materials, items and armaments."),
	quarry               	   = getTranslatedString("A Quarry intended to mine stone, fueled by wood."),

	//Quarters.as
	beer                       = getTranslatedString("A refreshing mug of beer."),
	meal                       = getTranslatedString("A hearty meal to get you back on your feet."),
	egg                        = getTranslatedString("A suspiciously undercooked egg, maybe it will hatch."),
	burger                     = getTranslatedString("A burger to go."),

	//Magic Scrolls
	scroll_carnage             = getTranslatedString("This magic scroll when cast will turn all nearby enemies into a pile of bloody gibs."),
	scroll_drought             = getTranslatedString("This magic scroll will evaporate all water in a large surrounding orb.");
}