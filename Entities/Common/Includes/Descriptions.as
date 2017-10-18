// item description

const string[] descriptions =
{
	/* 00  */               "",
	/* 01  */               getTranslatedString("Bombs for Knight only."),   // bomb
	/* 02  */               getTranslatedString("Arrows for Archer and mounted bow."),         // arrows
	/* 03  */               "",                     //
	/* 04  */               getTranslatedString("Highly explosive powder keg for Knight only."),                  // keg
	/* 05  */               getTranslatedString("A stone throwing, ridable siege engine, requiring a crew of two."), // catapult
	/* 06  */               getTranslatedString("A bolt-firing pinpoint accurate siege engine, requiring a crew of two. Allows respawn and class change."),     //ballista
	/* 07  */               getTranslatedString("Raw stone material."),                                        // stone
	/* 08  */               getTranslatedString("Raw wood material."),                                           // wood
	/* 09  */               getTranslatedString("Lanterns help with mining in the dark, and lighten the mood."),                         // lantern
	/* 10  */               getTranslatedString("A small boat with two rowing positions and a large space for cargo."),     // dinghy
	/* 11  */               getTranslatedString("A siege engine designed to break open walls and fortifications."),         // ram
	/* 12  */               getTranslatedString("A mill saw turns tree logs into wood material."),                             // saw
	/* 13  */               getTranslatedString("A trading post. Requires a trader to reside inside."), // tradingpost
	/* 14  */               getTranslatedString("Excalibur is the legendary sword of King Arthur, attributed with magical powers to conquer all enemies."),  // excalibur
	/* 15  */               getTranslatedString("Piercing bolts for ballista."), // mat_bolts
	/* 16  */               getTranslatedString("A simple wooden ladder for climbing over defenses."), // ladder
	/* 17  */               getTranslatedString("A stone boulder useful for crushing enemies."), // boulder
	/* 18  */               getTranslatedString("An empty wooden crate for storing and transporting inventory."), // crate
	/* 19  */               "",
	/* 20  */               getTranslatedString("An explosive mine. Triggered by contact with an enemy."), // mine
	/* 21  */               getTranslatedString("Fire satchel for Knight only."), // satchel
	/* 22  */               getTranslatedString("A health regenerating heart."), // heart
	/* 23  */               getTranslatedString("A sack for storing more inventory on your back."), // sack
	/* 24  */               getTranslatedString("A seedling of an oak tree ready for planting."), // tree_bushy
	/* 25  */               getTranslatedString("A seedling of a pine tree ready for planting."), // tree_pine
	/* 26  */               getTranslatedString("A decorative flower seedling."), // flower
	/* 27  */               getTranslatedString("Grain used as food."), // grain
	/* 28  */               getTranslatedString("Wooden swing door."), // wooden_door
	/* 29  */               getTranslatedString("Stone spikes used as a defense around fortifications."), // spikes
	/* 30  */               getTranslatedString("A trampoline used for bouncing and jumping over enemy walls."), // trampoline
	/* 31  */               getTranslatedString("A stationary arrow-firing death machine."), // mounted_bow
	/* 32  */               getTranslatedString("Fire arrows used to set wooden structures on fire."), // fire arrows
	/* 33  */               getTranslatedString("A fast rowing boat used for quickly getting across water."), // longboat
	/* 34  */               getTranslatedString("A tunnel for quick transportation."), // tunnel
	/* 35  */               "", //
	/* 36  */               getTranslatedString("Bucket for storing water. Useful for fighting fires."), //bucket
	/* 37  */               getTranslatedString("A slow armoured boat which acts also as a water base for respawn and class change."), // warboat
	/* 38  */               getTranslatedString("A generic factory. Requires Research Room, technology upgrade and big enough population to produce items."), //
	/* 39  */               getTranslatedString("Kitchen produces food which heal wounds."), //  kitchen
	/* 40  */               getTranslatedString("A plant nursery with grain, oak and pine tree seeds."), //  nursery
	/* 41  */               getTranslatedString("Barracks allow changing class to Archer or Knight."), //  barracks
	/* 42  */               getTranslatedString("A storage than can hold materials and items and share them with other storages."), //  storage
	/* 43  */               getTranslatedString("A mining drill. Increases speed of digging and gathering resources, but gains only half the possible resources."), //  drill
	/* 44  */               getTranslatedString("Bombs for Knights & arrows for Archers.\nAutomatically distributed on respawn."), //  military basics
	/* 45  */               getTranslatedString("Items used for blowing stuff up."), //  explosives
	/* 46  */               getTranslatedString("Items used for lighting things on fire."), //  pyro
	/* 47  */               getTranslatedString("When team is in possession of stone construction technology it allows builders to make stone walls, doors, traps and spikes."), //  stone tech
	/* 48  */               getTranslatedString("Dorm increases population count and allows spawning and healing inside. Requires a migrant."), //  dorm
	/* 49  */               getTranslatedString("Research room."), //  research
	/* 50  */               getTranslatedString("Water arrows for Archer. Can extinguish fires and stun enemies."),         // water arrows
	/* 51  */               getTranslatedString("Bomb arrows for Archer."),         // bomb arrows
	/* 52  */               getTranslatedString("Water bomb for Knight. Can extinguish fires and stun enemies."),         // water bomb
	/* 53  */               getTranslatedString("Water absorbing sponge. Useful for unflooding tunnels and reducing water stuns."),         // sponge

	/* 54  */               getTranslatedString("Builder workshop for building utilities and changing class to Builder"),         // buildershop
	/* 55  */               getTranslatedString("Knight workshop for building explosives and changing class to Knight"),         // Knightshop
	/* 56  */               getTranslatedString("Archer workshop for building arrows and changing class to Archer"),         // Archershop
	/* 57  */               getTranslatedString("Siege workshop for building wheeled siege engines"),         // vehicleshop
	/* 58  */               getTranslatedString("Naval workshop for building boats"),         // boatshop
	/* 59  */               getTranslatedString("Place of merriment and healing"),         // quarters/inn
	/* 60  */               getTranslatedString("A Cache for storing your materials, items and armaments."),         // storage cache
};
