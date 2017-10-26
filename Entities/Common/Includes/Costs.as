//// CTF COSTS ////
string ctf_costs_config_file = "CTFShopCosts.cfg";
namespace CTFCosts
{
	//Building.as
	s32 buildershop_wood = 50;
	s32 quarters_wood = 50;
	s32 knightshop_wood = 50;
	s32 archershop_wood = 50;
	s32 boatshop_wood = 100;
	s32 boatshop_gold = 50;
	s32 vehicleshop_wood = 100;
	s32 vehicleshop_gold = 50;
	s32 storage_stone = 50;
	s32 storage_wood = 50;
	s32 tunnel_stone = 100;
	s32 tunnel_wood = 50;
	s32 tunnel_gold = 50;

	//ArcherShop.as
	s32 arrows = 15;
	s32 waterarrows = 20;
	s32 firearrows = 30;
	s32 bombarrows = 50;

	//KnightShop.as
	s32 bomb = 25;
	s32 waterbomb = 30;
	s32 mine = 60;
	s32 keg = 120;
	
	//BuilderShop.as
	s32 lantern_wood = 10;
	s32 bucket_wood = 10;
	s32 sponge = 15;
	s32 boulder_stone = 35;
	s32 trampoline_wood = 150;
	s32 saw_wood = 150;
	s32 saw_stone = 100;
	s32 drill_stone = 100;
	s32 drill = 25;

	//BoatShop.as
	s32 dinghy = 25;
	s32 dinghy_wood = 100;
	s32 longboat = 50;
	s32 longboat_wood = 200;
	s32 warboat = 250;

	//VehicleShop.as
	s32 catapult = 80;
	s32 ballista = 200;
	s32 ballista_ammo = 100;
	s32 ballista_ammo_upgrade_gold = 100;

	//Quarters.as
	s32 beer = 5;
	s32 meal = 10;
	s32 egg = 30;
	s32 burger = 20;

	//CommonBuilderBlocks.as
	s32 workshop_wood = 150;
}

//// TTH COSTS ////
string war_costs_config_file = "WARCosts.cfg";
namespace WARCosts
{
	//Workbench.as
	s32 lantern_wood = 10;
	s32 bucket_wood = 10;
	s32 sponge_wood = 50;
	s32 trampoline_wood = 150;
	s32 crate_wood = 30;
	s32 drill_stone = 100;
	s32 saw_wood = 150;
	s32 dinghy_wood = 100;
	s32 boulder_stone = 30;

	//Scrolls
	s32 crappiest_scroll = 60;
	s32 crappy_scroll = 100;
	s32 medium_scroll = 200;
	s32 big_scroll = 300;
	s32 super_scroll = 500;

	//Builder Menu
	s32 factory_wood = 150;
	s32 workbench_wood = 120;
}

//// BUILDER COSTS ////
string builder_costs_config_file = "BuilderCosts.cfg";
namespace BuilderCosts
{
	s32 stone_block = 10;
	s32 back_stone_block = 2;
	s32 stone_door = 50;
	s32 wood_block = 10;
	s32 back_wood_block = 2;
	s32 wooden_door = 30;
	s32 trap_block = 25;
	s32 ladder = 10;
	s32 wooden_platform = 15;
	s32 spikes = 30;
}

void InitCosts()
{
	//load config
	ConfigFile cfg = ConfigFile();
	if (getRules().exists("ctf_costs_config"))
		ctf_costs_config_file = getRules().get_string("ctf_costs_config");

	
	cfg.loadFile(ctf_costs_config_file);

	//Building.as
	CTFCosts::buildershop_wood = cfg.read_s32("cost_buildershop_wood", CTFCosts::buildershop_wood);
	CTFCosts::quarters_wood = cfg.read_s32("cost_quarters_wood", CTFCosts::quarters_wood);
	CTFCosts::knightshop_wood = cfg.read_s32("cost_knightshop_wood", CTFCosts::knightshop_wood);
	CTFCosts::archershop_wood = cfg.read_s32("cost_archershop_wood", CTFCosts::archershop_wood);
	CTFCosts::boatshop_wood = cfg.read_s32("cost_boatshop_wood", CTFCosts::boatshop_wood);
	CTFCosts::boatshop_gold = cfg.read_s32("cost_boatshop_gold", CTFCosts::boatshop_gold);
	CTFCosts::vehicleshop_wood = cfg.read_s32("cost_vehicleshop_wood", CTFCosts::vehicleshop_wood);
	CTFCosts::vehicleshop_gold = cfg.read_s32("cost_vehicleshop_gold", CTFCosts::vehicleshop_gold);
	CTFCosts::storage_stone = cfg.read_s32("cost_storage_stone", CTFCosts::storage_stone);
	CTFCosts::storage_wood = cfg.read_s32("cost_storage_wood", CTFCosts::storage_wood);
	CTFCosts::tunnel_stone = cfg.read_s32("cost_tunnel_stone", CTFCosts::tunnel_stone);
	CTFCosts::tunnel_wood = cfg.read_s32("cost_tunnel_wood", CTFCosts::tunnel_wood);
	CTFCosts::tunnel_gold = cfg.read_s32("cost_tunnel_gold", CTFCosts::tunnel_gold);

	//ArcherShop.as
	CTFCosts::arrows = cfg.read_s32("cost_arrows", CTFCosts::arrows);
	CTFCosts::waterarrows = cfg.read_s32("cost_waterarrows", CTFCosts::waterarrows);
	CTFCosts::firearrows = cfg.read_s32("cost_firearrows", CTFCosts::firearrows);
	CTFCosts::bombarrows = cfg.read_s32("cost_bombarrows", CTFCosts::bombarrows);

	//KnightShop.as
	CTFCosts::bomb = cfg.read_s32("cost_bomb", CTFCosts::bomb);
	CTFCosts::waterbomb = cfg.read_s32("cost_waterbomb", CTFCosts::waterbomb);
	CTFCosts::mine = cfg.read_s32("cost_mine", CTFCosts::mine);
	CTFCosts::keg = cfg.read_s32("cost_keg", CTFCosts::keg);

	//BuilderShop.as
	CTFCosts::lantern_wood = cfg.read_s32("cost_lantern_wood", CTFCosts::lantern_wood);
	CTFCosts::bucket_wood = cfg.read_s32("cost_bucket_wood", CTFCosts::bucket_wood);
	CTFCosts::sponge = cfg.read_s32("cost_sponge", CTFCosts::sponge);
	CTFCosts::boulder_stone = cfg.read_s32("cost_boulder_stone", CTFCosts::boulder_stone);
	CTFCosts::trampoline_wood = cfg.read_s32("cost_trampoline_wood", CTFCosts::trampoline_wood);
	CTFCosts::saw_wood = cfg.read_s32("cost_saw_wood", CTFCosts::saw_wood);
	CTFCosts::saw_stone = cfg.read_s32("cost_saw_stone", CTFCosts::saw_stone);
	CTFCosts::drill_stone = cfg.read_s32("cost_drill_stone", CTFCosts::drill_stone);
	CTFCosts::drill = cfg.read_s32("cost_drill", CTFCosts::drill);

	//BoatShop.as
	CTFCosts::dinghy = cfg.read_s32("cost_dinghy", CTFCosts::dinghy);
	CTFCosts::dinghy_wood = cfg.read_s32("cost_dinghy_wood", CTFCosts::dinghy_wood);
	CTFCosts::longboat = cfg.read_s32("cost_longboat", CTFCosts::longboat);
	CTFCosts::longboat_wood = cfg.read_s32("cost_longboat_wood", CTFCosts::longboat_wood);
	CTFCosts::warboat = cfg.read_s32("cost_warboat", CTFCosts::warboat);

	//VehicleShop.as
	CTFCosts::catapult = cfg.read_s32("cost_catapult", CTFCosts::catapult);
	CTFCosts::ballista = cfg.read_s32("cost_ballista", CTFCosts::ballista);
	CTFCosts::ballista_ammo = cfg.read_s32("cost_ballista_ammo", CTFCosts::ballista_ammo);
	CTFCosts::ballista_ammo_upgrade_gold = cfg.read_s32("cost_ballista_ammo_upgrade_gold", CTFCosts::ballista_ammo_upgrade_gold);

	//Quarters.as
	CTFCosts::beer = cfg.read_s32("cost_beer", CTFCosts::beer);
	CTFCosts::meal = cfg.read_s32("cost_meal", CTFCosts::meal);
	CTFCosts::egg = cfg.read_s32("cost_egg", CTFCosts::egg);
	CTFCosts::burger = cfg.read_s32("cost_burger", CTFCosts::burger);

	//CommonBuilderBlocks.as
	CTFCosts::workshop_wood = cfg.read_s32("cost_workshop_wood", CTFCosts::workshop_wood);

//###################

	//load config
	if (getRules().exists("war_costs_config"))
		war_costs_config_file = getRules().get_string("war_costs_config");

	cfg.loadFile(war_costs_config_file);

	//Workbench.as
	WARCosts::lantern_wood = cfg.read_s32("cost_lantern_wood", WARCosts::lantern_wood);
	WARCosts::bucket_wood = cfg.read_s32("cost_bucket_wood", WARCosts::bucket_wood);
	WARCosts::sponge_wood = cfg.read_s32("cost_sponge_wood", WARCosts::sponge_wood);
	WARCosts::trampoline_wood = cfg.read_s32("cost_trampoline_wood", WARCosts::trampoline_wood);
	WARCosts::crate_wood = cfg.read_s32("cost_crate_wood", WARCosts::crate_wood);
	WARCosts::drill_stone = cfg.read_s32("cost_drill_stone", WARCosts::drill_stone);
	WARCosts::saw_wood = cfg.read_s32("cost_saw_wood", WARCosts::saw_wood);
	WARCosts::dinghy_wood = cfg.read_s32("cost_dinghy_wood", WARCosts::dinghy_wood);
	WARCosts::boulder_stone = cfg.read_s32("cost_boulder_stone", WARCosts::boulder_stone);

	//Scrolls
	WARCosts::crappiest_scroll = cfg.read_s32("cost_crappiest_scroll", WARCosts::crappiest_scroll);
	WARCosts::crappy_scroll = cfg.read_s32("cost_crappy_scroll", WARCosts::crappy_scroll);
	WARCosts::medium_scroll = cfg.read_s32("cost_medium_scroll", WARCosts::medium_scroll);
	WARCosts::big_scroll = cfg.read_s32("cost_big_scroll", WARCosts::big_scroll);
	WARCosts::super_scroll = cfg.read_s32("cost_super_scroll", WARCosts::super_scroll);

	//CommonBuilderBlocks.as
	WARCosts::factory_wood = cfg.read_s32("cost_factory_wood", WARCosts::factory_wood);
	WARCosts::workbench_wood = cfg.read_s32("cost_workbench_wood", WARCosts::workbench_wood);

//###################

	cfg.loadFile(builder_costs_config_file);

	BuilderCosts::stone_block = cfg.read_s32("cost_stone_block", BuilderCosts::stone_block);
	BuilderCosts::back_stone_block = cfg.read_s32("cost_back_stone_block", BuilderCosts::back_stone_block);
	BuilderCosts::stone_door = cfg.read_s32("cost_stone_door", BuilderCosts::stone_door);
	BuilderCosts::wood_block = cfg.read_s32("cost_wood_block", BuilderCosts::wood_block);
	BuilderCosts::back_wood_block = cfg.read_s32("cost_back_wood_block", BuilderCosts::back_wood_block);
	BuilderCosts::wooden_door = cfg.read_s32("cost_wooden_door", BuilderCosts::wooden_door);
	BuilderCosts::trap_block = cfg.read_s32("cost_trap_block", BuilderCosts::trap_block);
	BuilderCosts::ladder = cfg.read_s32("cost_ladder", BuilderCosts::ladder);
	BuilderCosts::wooden_platform = cfg.read_s32("cost_wooden_platform", BuilderCosts::wooden_platform);
	BuilderCosts::spikes = cfg.read_s32("cost_spikes", BuilderCosts::spikes);
}
