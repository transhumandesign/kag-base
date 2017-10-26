//// CTF COSTS ////
string ctf_costs_config_file = "CTFCosts.cfg";
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
	s32 filled_bucket = 10;
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

void ReadCost(ConfigFile cfg, string cfg_name, s32 &in cost_var)
{
	cost_var = cfg.read_s32(cfg_name, cost_var);
}
void InitCosts()
{
	//load config
	ConfigFile cfg = ConfigFile();
	if (getRules().exists("ctf_costs_config"))
		ctf_costs_config_file = getRules().get_string("ctf_costs_config");

	
	cfg.loadFile(ctf_costs_config_file);

	//Building.as
	ReadCost(cfg, "cost_buildershop_wood"   , CTFCosts::buildershop_wood);
	ReadCost(cfg, "cost_quarters_wood"      , CTFCosts::quarters_wood);
	ReadCost(cfg, "cost_knightshop_wood"    , CTFCosts::knightshop_wood);
	ReadCost(cfg, "cost_archershop_wood"    , CTFCosts::archershop_wood);
	ReadCost(cfg, "cost_boatshop_wood"      , CTFCosts::boatshop_wood);
	ReadCost(cfg, "cost_boatshop_gold"      , CTFCosts::boatshop_gold);
	ReadCost(cfg, "cost_vehicleshop_wood"   , CTFCosts::vehicleshop_wood);
	ReadCost(cfg, "cost_vehicleshop_gold"   , CTFCosts::vehicleshop_gold);
	ReadCost(cfg, "cost_storage_stone"      , CTFCosts::storage_stone);
	ReadCost(cfg, "cost_storage_wood"       , CTFCosts::storage_wood);
	ReadCost(cfg, "cost_tunnel_stone"       , CTFCosts::tunnel_stone);
	ReadCost(cfg, "cost_tunnel_wood"        , CTFCosts::tunnel_wood);
	ReadCost(cfg, "cost_tunnel_gold"        , CTFCosts::tunnel_gold);

	//ArcherShop.as
	ReadCost(cfg, "cost_arrows"             , CTFCosts::arrows);
	ReadCost(cfg, "cost_waterarrows"        , CTFCosts::waterarrows);
	ReadCost(cfg, "cost_firearrows"         , CTFCosts::firearrows);
	ReadCost(cfg, "cost_bombarrows"         , CTFCosts::bombarrows);

	//KnightShop.as
	ReadCost(cfg, "cost_bomb"               , CTFCosts::bomb);
	ReadCost(cfg, "cost_waterbomb"          , CTFCosts::waterbomb);
	ReadCost(cfg, "cost_mine"               , CTFCosts::mine);
	ReadCost(cfg, "cost_keg"                , CTFCosts::keg);

	//BuilderShop.as
	ReadCost(cfg, "cost_lantern_wood"       , CTFCosts::lantern_wood);
	ReadCost(cfg, "cost_bucket_wood"        , CTFCosts::bucket_wood);
	ReadCost(cfg, "cost_filled_bucket"      , CTFCosts::filled_bucket);
	ReadCost(cfg, "cost_sponge"             , CTFCosts::sponge);
	ReadCost(cfg, "cost_boulder_stone"      , CTFCosts::boulder_stone);
	ReadCost(cfg, "cost_trampoline_wood"    , CTFCosts::trampoline_wood);
	ReadCost(cfg, "cost_saw_wood"           , CTFCosts::saw_wood);
	ReadCost(cfg, "cost_saw_stone"          , CTFCosts::saw_stone);
	ReadCost(cfg, "cost_drill_stone"        , CTFCosts::drill_stone);
	ReadCost(cfg, "cost_drill"              , CTFCosts::drill);

	//BoatShop.as
	ReadCost(cfg, "cost_dinghy"             , CTFCosts::dinghy);
	ReadCost(cfg, "cost_dinghy_wood"        , CTFCosts::dinghy_wood);
	ReadCost(cfg, "cost_longboat"           , CTFCosts::longboat);
	ReadCost(cfg, "cost_longboat_wood"      , CTFCosts::longboat_wood);
	ReadCost(cfg, "cost_warboat"            , CTFCosts::warboat);

	//VehicleShop.as
	ReadCost(cfg, "cost_catapult"                   , CTFCosts::catapult);
	ReadCost(cfg, "cost_ballista"                   , CTFCosts::ballista);
	ReadCost(cfg, "cost_ballista_ammo"              , CTFCosts::ballista_ammo);
	ReadCost(cfg, "cost_ballista_ammo_upgrade_gold" , CTFCosts::ballista_ammo_upgrade_gold);

	//Quarters.as
	ReadCost(cfg, "cost_beer"               , CTFCosts::beer);
	ReadCost(cfg, "cost_meal"               , CTFCosts::meal);
	ReadCost(cfg, "cost_egg"                , CTFCosts::egg);
	ReadCost(cfg, "cost_burger"             , CTFCosts::burger);

	//CommonBuilderBlocks.as
	ReadCost(cfg, "cost_workshop_wood"      , CTFCosts::workshop_wood);

//###################

	//load config
	if (getRules().exists("war_costs_config"))
		war_costs_config_file = getRules().get_string("war_costs_config");

	cfg.loadFile(war_costs_config_file);

	//Workbench.as
	ReadCost(cfg, "cost_lantern_wood"       , WARCosts::lantern_wood);
	ReadCost(cfg, "cost_bucket_wood"        , WARCosts::bucket_wood);
	ReadCost(cfg, "cost_sponge_wood"        , WARCosts::sponge_wood);
	ReadCost(cfg, "cost_trampoline_wood"    , WARCosts::trampoline_wood);
	ReadCost(cfg, "cost_crate_wood"         , WARCosts::crate_wood);
	ReadCost(cfg, "cost_drill_stone"        , WARCosts::drill_stone);
	ReadCost(cfg, "cost_saw_wood"           , WARCosts::saw_wood);
	ReadCost(cfg, "cost_dinghy_wood"        , WARCosts::dinghy_wood);
	ReadCost(cfg, "cost_boulder_stone"      , WARCosts::boulder_stone);

	//Scrolls
	ReadCost(cfg, "cost_crappiest_scroll"   , WARCosts::crappiest_scroll);
	ReadCost(cfg, "cost_crappy_scroll"      , WARCosts::crappy_scroll);
	ReadCost(cfg, "cost_medium_scroll"      , WARCosts::medium_scroll);
	ReadCost(cfg, "cost_big_scroll"         , WARCosts::big_scroll);
	ReadCost(cfg, "cost_super_scroll"       , WARCosts::super_scroll);

	//CommonBuilderBlocks.as
	ReadCost(cfg, "cost_factory_wood"       , WARCosts::factory_wood);
	ReadCost(cfg, "cost_workbench_wood"     , WARCosts::workbench_wood);

//###################

	cfg.loadFile(builder_costs_config_file);

	ReadCost(cfg, "cost_stone_block"        , BuilderCosts::stone_block);
	ReadCost(cfg, "cost_back_stone_block"   , BuilderCosts::back_stone_block);
	ReadCost(cfg, "cost_stone_door"         , BuilderCosts::stone_door);
	ReadCost(cfg, "cost_wood_block"         , BuilderCosts::wood_block);
	ReadCost(cfg, "cost_back_wood_block"    , BuilderCosts::back_wood_block);
	ReadCost(cfg, "cost_wooden_door"        , BuilderCosts::wooden_door);
	ReadCost(cfg, "cost_trap_block"         , BuilderCosts::trap_block);
	ReadCost(cfg, "cost_ladder"             , BuilderCosts::ladder);
	ReadCost(cfg, "cost_wooden_platform"    , BuilderCosts::wooden_platform);
	ReadCost(cfg, "cost_spikes"             , BuilderCosts::spikes);
}
