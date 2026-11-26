#define SERVER_ONLY

#include "Hitters.as";

u16[] ids;
u16 limit = 15; //ticks between hitting
string[] names_to_decay = {"wooden_door", "ladder"};

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	ids.clear();
	FetchExisting();
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
    string name = blob.getName();
	if (names_to_decay.find(name) != -1)
	{
		ids.push_back(blob.getNetworkID());
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
    string name = blob.getName();
	if (names_to_decay.find(name) != -1)
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
		
		CShape@ shape = b.getShape();
		if (shape is null) continue;
		
		ShapeConsts@ consts = shape.getConsts();
		if (consts is null) continue;

		Vec2f[] postocheck;

		postocheck.push_back(pos);

		if (!consts.waterPasses)
		{
			// check left, top and right
			postocheck.push_back(pos + Vec2f(map.tilesize, 0));
			postocheck.push_back(pos + Vec2f(-map.tilesize, 0));
			postocheck.push_back(pos + Vec2f(0, -map.tilesize));
		}

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

void FetchExisting()
{
	if (getMap() !is null)
	{
		CBlob@[] blobs;
		
		for (uint i = 0; i < names_to_decay.length; i++)
		{
			getBlobsByName(names_to_decay[i], @blobs);
		}
		
		for (uint j = 0; j < blobs.length; j++)
		{
			ids.push_back(blobs[j].getNetworkID());;
		}
	}
}
