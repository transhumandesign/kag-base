#include "CTFShopCommon.as"

//ArcherShop.as
s32 cost_arrows = 15;
s32 cost_waterarrows = 20;
s32 cost_firearrows = 30;
s32 cost_bombarrows = 50;

//KnightShop.as
s32 cost_bomb = 25;
s32 cost_waterbomb = 30;
s32 cost_keg = 120;
s32 cost_mine = 60;

//BoatShop.as
s32 cost_dinghy = 25;
s32 cost_longboat = 50;
s32 cost_warboat = 250;

//Quarters.as
s32 cost_beer = 5;
s32 cost_meal = 10;
s32 cost_egg = 30;
s32 cost_burger = 20;

//VehicleShop.as
s32 cost_catapult = 80;
s32 cost_ballista = 200;
s32 cost_ballista_ammo = 100;
s32 cost_ballista_ammo_upgrade_gold = 100;

//load config
if (getRules().exists("ctf_costs_config"))
{
	cost_config_file = getRules().get_string("ctf_costs_config");
}

ConfigFile cfg = ConfigFile();
cfg.loadFile(cost_config_file);

//ArcherShop.as
cost_arrows = cfg.read_s32("cost_arrows", cost_arrows);
cost_waterarrows = cfg.read_s32("cost_waterarrows", cost_waterarrows);
cost_firearrows = cfg.read_s32("cost_firearrows", cost_firearrows);
cost_bombarrows = cfg.read_s32("cost_bombarrows", cost_bombarrows);

//KnightShop.as
s32 cost_bomb = cfg.read_s32("cost_bomb", cost_bomb);
s32 cost_waterbomb = cfg.read_s32("cost_waterbomb", cost_waterbomb);
s32 cost_keg = cfg.read_s32("cost_keg", cost_keg);
s32 cost_mine = cfg.read_s32("cost_mine", cost_mine);

//BoatShop.as
s32 cost_dinghy = cfg.read_s32("cost_dinghy", cost_dinghy);
s32 cost_longboat = cfg.read_s32("cost_longboat", cost_longboat);
s32 cost_warboat = cfg.read_s32("cost_warboat", cost_warboat);

//Quarters.as
s32 cost_beer = cfg.read_s32("cost_beer", cost_beer);
s32 cost_meal = cfg.read_s32("cost_meal", cost_meal);
s32 cost_egg = cfg.read_s32("cost_egg", cost_egg);
s32 cost_burger = cfg.read_s32("cost_burger", cost_burger);

//VehicleShop.as
s32 cost_catapult = cfg.read_s32("cost_catapult", cost_catapult);
s32 cost_ballista = cfg.read_s32("cost_ballista", cost_ballista);
s32 cost_ballista_ammo = cfg.read_s32("cost_ballista_ammo", cost_ballista_ammo);
s32 cost_ballista_ammo_upgrade_gold = cfg.read_s32("cost_ballista_ammo_upgrade_gold", cost_ballista_ammo_upgrade_gold);