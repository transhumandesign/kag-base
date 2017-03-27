#define SERVER_ONLY

#include "Hitters.as";

u16[] ids;
u16 limit = 15; //ticks between hitting

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	ids.clear();
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
    string name = blob.getName();
	if (name == "wooden_door" || name == "ladder")
	{
		ids.push_back(blob.getNetworkID());
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
    string name = blob.getName();
	if (name == "wooden_door" || name == "ladder")
	{
		u16 id = blob.getNetworkID();
		for (uint i = 0; i < ids.length; i++)
		{
			if (ids[i] == id)
			{
				ids.erase(i);
				break;
			}
		}
	}
}

void onTick(CRules@ this)
{
	//limit
	if(((getGameTime() * 997) % limit) != 0)
		return;

	CMap@ map = getMap();
	for (uint i = 0; i < ids.length; i++)
	{
		CBlob@ b = getBlobByNetworkID(ids[i]);
		if (b is null)
		{
			ids.erase(i--);
			continue;
		}

		Vec2f pos = b.getPosition();
		Vec2f[] postocheck =
		{
			pos + Vec2f(map.tilesize, 0),
			pos + Vec2f(-map.tilesize, 0),
			pos + Vec2f(0, -map.tilesize)
		};
		bool water = false;
		for (uint j = 0; j < postocheck.length; j++)
		{
			Vec2f wpos = postocheck[j];
			if (map.isInWater(wpos))
			{
				water = true;
				break;
			}
		}
		if(water && !b.isAttached())
		{
			b.server_Hit(b, pos, Vec2f(), 0.5f, Hitters::water, true);
		}
	}
}
