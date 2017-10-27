// item descriptions
string desc_bomb = "Bombs for Knight only.";
string desc_waterbomb = "Water bomb for Knight. Can extinguish fires and stun enemies.";
string desc_mine = "An explosive mine. Triggered by contact with an enemy.";
string desc_keg = "Highly explosive powder keg for Knight only.";
string desc_satchel = "Fire satchel for Knight only."; //OLD

string desc_arrows = "Arrows for Archer and mounted bow.";
string desc_waterarrows = "Water arrows for Archer. Can extinguish fires and stun enemies.";
string desc_firearrows = "Fire arrows used to set wooden structures on fire.";
string desc_bombarrows = "Bomb arrows for Archer.";

string desc_ram = "A siege engine designed to break open walls and fortifications."; //OLD
string desc_catapult = "A stone throwing, ridable siege engine, requiring a crew of two.";
string desc_ballista = "A bolt-firing pinpoint accurate siege engine, requiring a crew of two. Allows respawn and class change.";
string desc_ballista_ammo = "Piercing bolts for ballista.";
string desc_ballista_ammo_upgrade_gold = "For Ballista\nTurns its piercing bolts into a shaped explosive charge.";

string desc_stone = "Raw stone material.";
string desc_wood = "Raw wood material.";

string desc_lantern = "Lanterns help with mining in the dark, and lighten the mood.";
string desc_bucket = "Bucket for storing water. Useful for fighting fires.";
string desc_filled_bucket = "A wooden bucket pre-filled with water for fighting fires.";
string desc_sponge = "Water absorbing sponge. Useful for unflooding tunnels and reducing water stuns.";
string desc_boulder = "A stone boulder useful for crushing enemies.";
string desc_trampoline = "A trampoline used for bouncing and jumping over enemy walls.";
string desc_saw = "A mill saw turns tree logs into wood material.";
string desc_drill = "A mining drill. Increases speed of digging and gathering resources, but gains only half the possible resources.";
string desc_crate = "An empty wooden crate for storing and transporting inventory.";

string desc_tradingpost = "A trading post. Requires a trader to reside inside.";
string desc_excalibur = "Excalibur is the legendary sword of King Arthur, attributed with magical powers to conquer all enemies.";
string desc_ladder = "A simple wooden ladder for climbing over defenses.";



string desc_heart = "A health regenerating heart.";
string desc_sack = "A sack for storing more inventory on your back."; //OLD
string desc_tree_bushy = "A seedling of an oak tree ready for planting.";
string desc_tree_pine = "A seedling of a pine tree ready for planting.";
string desc_flower = "A decorative flower seedling.";
string desc_grain = "Grain used as food.";
string desc_wooden_door = "Wooden swing door.";
string desc_spikes  = "Stone spikes used as a defense around fortifications.";

string desc_mounted_bow = "A stationary arrow-firing death machine.";
string desc_dinghy = "A small boat with two rowing positions and a large space for cargo.";
string desc_longboat = "A fast rowing boat used for quickly getting across water.";
string desc_warboat = "A slow armoured boat which acts also as a water base for respawn and class change.";
string desc_tunnel = "A tunnel for quick transportation.";


string desc_factory = "A generic factory. Requires Research Room, technology upgrade and big enough population to produce items.";
string desc_kitchen = "Kitchen produces food which heal wounds.";
string desc_nursery = "A plant nursery with grain, oak and pine tree seeds.";
string desc_barracks = "Barracks allow changing class to Archer or Knight.";
string desc_storage = "A storage than can hold materials and items and share them with other storages.";

string desc_militarybasics = "Bombs for Knights & arrows for Archers.\nAutomatically distributed on respawn.";
string desc_explosives = "Items used for blowing stuff up.";
string desc_pyro = "Items used for lighting things on fire.";
string desc_stonetech = "When team is in possession of stone construction technology it allows builders to make stone walls, doors, traps and spikes.";
string desc_dorm = "Dorm increases population count and allows spawning and healing inside. Requires a migrant.";
string desc_research = "Research room.";
string desc_buildershop = "Builder workshop for building utilities and changing class to Builder";
string desc_knightshop = "Knight workshop for building explosives and changing class to Knight";
string desc_archershop = "Archer workshop for building arrows and changing class to Archer";
string desc_vehicleshop = "Siege workshop for building wheeled siege engines";
string desc_boatshop = "Naval workshop for building boats";
string desc_quarters = "Place of merriment and healing";
string desc_storagecache = "A Cache for storing your materials, items and armaments.";

//Quarters.as
string desc_beer = "A refreshing mug of beer.";
string desc_meal = "A hearty meal to get you back on your feet.";
string desc_egg = "A suspiciously undercooked egg, maybe it will hatch.";
string desc_burger = "A burger to go.";

const string[] descriptions =
{
/* 00  */               "",
/* 01  */               "Bombs for Knight only.",   // bomb
/* 02  */               "Arrows for Archer and mounted bow.",         // arrows
/* 03  */               "",                     //
/* 04  */               "Highly explosive powder keg for Knight only.",                  // keg
/* 05  */               "A stone throwing, ridable siege engine, requiring a crew of two.", // catapult
/* 06  */               "A bolt-firing pinpoint accurate siege engine, requiring a crew of two. Allows respawn and class change.",     //ballista
/* 07  */               "Raw stone material.",                                        // stone
/* 08  */               "Raw wood material.",                                           // wood
/* 09  */               "Lanterns help with mining in the dark, and lighten the mood.",                         // lantern
/* 10  */               "A small boat with two rowing positions and a large space for cargo.",     // dinghy
/* 11  */               "A siege engine designed to break open walls and fortifications.",         // ram
/* 12  */               "A mill saw turns tree logs into wood material.",                             // saw
/* 13  */               "A trading post. Requires a trader to reside inside.", // tradingpost
/* 14  */               "Excalibur is the legendary sword of King Arthur, attributed with magical powers to conquer all enemies.",  // excalibur
/* 15  */               "Piercing bolts for ballista.", // mat_bolts
/* 16  */               "A simple wooden ladder for climbing over defenses.", // ladder
/* 17  */               "A stone boulder useful for crushing enemies.", // boulder
/* 18  */               "An empty wooden crate for storing and transporting inventory.", // crate
/* 19  */               "",
/* 20  */               "An explosive mine. Triggered by contact with an enemy.", // mine
/* 21  */               "Fire satchel for Knight only.", // satchel
/* 22  */               "A health regenerating heart.", // heart
/* 23  */               "A sack for storing more inventory on your back.", // sack
/* 24  */               "A seedling of an oak tree ready for planting.", // tree_bushy
/* 25  */               "A seedling of a pine tree ready for planting.", // tree_pine
/* 26  */               "A decorative flower seedling.", // flower
/* 27  */               "Grain used as food.", // grain
/* 28  */               "Wooden swing door.", // wooden_door
/* 29  */               "Stone spikes used as a defense around fortifications.", // spikes
/* 30  */               "A trampoline used for bouncing and jumping over enemy walls.", // trampoline
/* 31  */               "A stationary arrow-firing death machine.", // mounted_bow
/* 32  */               "Fire arrows used to set wooden structures on fire.", // fire arrows
/* 33  */               "A fast rowing boat used for quickly getting across water.", // longboat
/* 34  */               "A tunnel for quick transportation.", // tunnel
/* 35  */               "", //
/* 36  */               "Bucket for storing water. Useful for fighting fires.", //bucket
/* 37  */               "A slow armoured boat which acts also as a water base for respawn and class change.", // warboat
/* 38  */               "A generic factory. Requires Research Room, technology upgrade and big enough population to produce items.", //
/* 39  */               "Kitchen produces food which heal wounds.", //  kitchen
/* 40  */               "A plant nursery with grain, oak and pine tree seeds.", //  nursery
/* 41  */               "Barracks allow changing class to Archer or Knight.", //  barracks
/* 42  */               "A storage than can hold materials and items and share them with other storages.", //  storage
/* 43  */               "A mining drill. Increases speed of digging and gathering resources, but gains only half the possible resources.", //  drill
/* 44  */               "Bombs for Knights & arrows for Archers.\nAutomatically distributed on respawn.", //  military basics
/* 45  */               "Items used for blowing stuff up.", //  explosives
/* 46  */               "Items used for lighting things on fire.", //  pyro
/* 47  */               "When team is in possession of stone construction technology it allows builders to make stone walls, doors, traps and spikes.", //  stone tech
/* 48  */               "Dorm increases population count and allows spawning and healing inside. Requires a migrant.", //  dorm
/* 49  */               "Research room.", //  research
/* 50  */               "Water arrows for Archer. Can extinguish fires and stun enemies.",         // water arrows
/* 51  */               "Bomb arrows for Archer.",         // bomb arrows
/* 52  */               "Water bomb for Knight. Can extinguish fires and stun enemies.",         // water bomb
/* 53  */               "Water absorbing sponge. Useful for unflooding tunnels and reducing water stuns.",         // sponge

/* 54  */               "Builder workshop for building utilities and changing class to Builder",         // buildershop
/* 55  */               "Knight workshop for building explosives and changing class to Knight",         // Knightshop
/* 56  */               "Archer workshop for building arrows and changing class to Archer",         // Archershop
/* 57  */               "Siege workshop for building wheeled siege engines",         // vehicleshop
/* 58  */               "Naval workshop for building boats",         // boatshop
/* 59  */               "Place of merriment and healing",         // quarters/inn
/* 60  */               "A Cache for storing your materials, items and armaments.",         // storage cache
};
