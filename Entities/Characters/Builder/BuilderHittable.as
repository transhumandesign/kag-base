
//names of stuff which should be able to be hit by
//team builders, drills etc

const string[] builder_alwayshit =
{
	//handmade
	"workbench",
	"fireplace",
	"ladder",

	//faketiles
	"spikes",
	"trap_block",
	"bridge",
	"flowers",

	//buildings
	"factory",
	"tunnel",
	"building",
	"quarters",
	"storage",
	"quarry"
};

//fragments of names, for semi-tolerant matching
// (so we don't have to do heaps of comparisions
//  for all the shops)
const string[] builder_alwayshit_fragment =
{
	"shop",
	"door",
	"platform"
};

bool BuilderAlwaysHit(CBlob@ blob)
{
	if (blob.hasTag("builder always hit"))
	{
		return true;
	}

	string name = blob.getName();
	for(uint i = 0; i < builder_alwayshit.length; ++i)
	{
		if (builder_alwayshit[i] == name)
			return true;
	}
	for(uint i = 0; i < builder_alwayshit_fragment.length; ++i)
	{
		if (name.find(builder_alwayshit_fragment[i]) != -1)
			return true;
	}
	return false;
}

bool isUrgent( CBlob@ this, CBlob@ b )
{
			//enemy players
	return (b.getTeamNum() != this.getTeamNum() || b.hasTag("dead")) && b.hasTag("player") ||
			//tagged
			b.hasTag("builder urgent hit") ||
			//trees
			b.getName().find("tree") != -1 ||
			//spikes
			b.getName() == "spikes" ||
			//ladder
			b.getName() == "ladder";
}

bool isWoodenTile(CMap@ map, u16 type)
{
	return map.isTileWood(type) ||
			map.isTileGrass(type) ||
			type == CMap::tile_wood_back ||
			type == 207; // 207 is damaged wood tile back
}

bool isStructureTile(CMap@ map, u16 type)
{
	return map.isTileWood(type) || // wood tile
			(type >= CMap::tile_wood_back && type <= 207) || // wood backwall
			map.isTileCastle(type) || // castle block
			(type >= CMap::tile_castle_back && type <= 79) || // castle backwall
			type == CMap::tile_castle_back_moss; // castle mossbackwall
}

// when hit blob in this list, builder uses axe instead of pickaxe
bool isWooden(CBlob@ attacked)
{
	string attacked_name = attacked.getName();

	return (attacked.hasTag("wooden") || attacked_name.toLower().find("tree") != -1 || attacked.hasTag("scenary")) &&
			attacked_name != "mine" &&
			attacked_name != "drill";
}

// when hit blob in this list, builder can hits faster
bool isStructure(CBlob@ attacked)
{
	string attacked_name = attacked.getName();

	return attacked.hasTag("builder fast hit") ||
			attacked_name == "bridge" ||
			attacked_name == "wooden_platform" ||
			attacked.hasTag("door") ||
			attacked_name == "ladder" ||
			attacked_name == "spikes";
}