// Rules script to drop trader if team is lacking one
// Tag("traders on parachutes"); for them to spawn on chutes

//28 May 2015 - we're not using this now, traders are spritelayers in the
//trading post - just easier to avoid dealing with killing them tbh

#define SERVER_ONLY

#include "MakeCrate.as";
#include "TradingCommon.as";

const string spawnBlobName = "tradingpost";
const bool doParaSpawn = false;
bool spawned = false;

void onRestart(CRules@ this)
{
	spawned = false;
}

void onTick(CRules@ this)
{
	//if (!this.isMatchRunning())
	//  return;

	if (!spawned || getGameTime() % (this.isMatchRunning() ? 303 : 120) == 0) // we don't have to do this each tick
	{
		TeamSpawnTrader(0, doParaSpawn);
		TeamSpawnTrader(1, doParaSpawn);
		TeamSpawnTrader(255, doParaSpawn);
		spawned = true;
	}
}

void TeamSpawnTrader(int teamNum, const bool paraSpawn)
{
	CBlob@[] spawns;
	getBlobsByName("tradingpost", @spawns);
	for (uint i = 0; i < spawns.length; i++)
	{
		CBlob@ post = spawns[i];

		if (post.getTeamNum() == teamNum && !post.hasTag("has trader"))
		{
			bool hasfloor = hasFloorTiles(post);
			if (hasfloor && !isTraderAround(post.getPosition()))
			{
				SpawnTrader(post.getPosition(), -1, paraSpawn);
				post.Tag("has trader");
			}
		}
		else
		{
			if (isTraderAround(post.getPosition()))
			{
				post.Tag("has trader");
			}
			else
			{
				post.Untag("has trader");
			}
		}
	}
}

bool hasFloorTiles(CBlob@ post)
{
	CMap@ map = post.getMap();

	Vec2f pos = post.getPosition();

	f32 tilesize = map.tilesize;
	f32 floordist = tilesize * 2.0f;

	return map.isTileSolid(pos + Vec2f(-tilesize / 2.0f, floordist)) &&
	       map.isTileSolid(pos + Vec2f(+tilesize / 2.0f, floordist));
}

bool isTraderConscious(CBlob@ trader)
{
	if (trader.isInInventory())
	{
		if (trader.getInventoryBlob().hasTag("parachute"))
		{
			return true;
		}
		else
		{
			false;
		}
	}

	return (!trader.hasTag("dead"));	  //cant put in inv
}

bool isTraderAround(Vec2f pos)
{
	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(pos, 64.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.getName() == "trader")
			{
				return true;
			}
		}
	}
	return false;
}

CBlob@ SpawnTrader(Vec2f position, int teamNum,  bool parachute)
{
	// spawn in crate/parachute
	Vec2f dropPos = position;

	if (parachute)
	{
		dropPos = getDropPosition(position);
	}
	else
	{
		dropPos = position;
	}

	CBlob@ trader = server_CreateBlob("trader", teamNum, dropPos);

	if (trader !is null)
	{
		trader.setSexNum(XORRandom(2));   // sex change
	}

	if (parachute)
	{
		CBlob@ crate = server_MakeCrateOnParachute("", "", 2, teamNum, dropPos);
		crate.server_PutInInventory(trader);
		crate.Tag("destroy on touch");
	}

	return trader;
}

void GatherTraders(CBlob@[]@ traders)
{
	getBlobsByName("trader", @traders);
	// crate ones
	CBlob@[] crates;
	getBlobsByName("crate", @crates);
	for (uint i = 0; i < crates.length; i++)
	{
		CBlob@ crate = crates[i];
		if (crate.getInventory() !is null)
		{
			CBlob@ trader = crate.getInventory().getItem("trader");
			if (trader !is null)
			{
				traders.push_back(trader);
			}
		}
	}
}
