// spawn resources

#define SERVER_ONLY

#include "ProductionCommon.as";
#include "RulesCore.as";
#include "WAR_Structs.as";

bool GiveGroundItems(CBlob@ blob, const string &in name)
{
	CMap@ map = getMap();
	CBlob@[] blobsInRadius;
	if (map.getBlobsInRadius(blob.getPosition(), blob.getRadius() * 2.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.getName() == name)
			{

				if (!blob.server_PutInInventory(b))
					b.setPosition(blob.getPosition());
				return true;
			}
		}
	}
	return false;
}


bool GiveStorageItem(CBlob@ blob, const string &in name)
{
	// find simply on ground first

	if (GiveGroundItems(blob, name))
		return true;

	// check in storages

	const s32 team = blob.getTeamNum();

	CBlob@[] bases;
	getBlobsByTag("storage", @bases);

	for (uint step = 0; step < bases.length; ++step)
	{
		CBlob@ base = bases[step];
		if (base.getTeamNum() == team)
		{
			if (base.hasBlob(name, 1))
			{
				CBlob@ item = base.server_PutOutInventory(name);
				if (item !is null)
				{
					if (!blob.server_PutInInventory(item))
						item.setPosition(blob.getPosition());
					return true;
				}
			}
		}
	}
	return false;
}

// find factory that makes this item and give it
// if not try to find it in base and factory storages

bool GiveFactoryItem(CBlob@ blob, const string &in name, const bool forceProduce = false)
{
	const s32 team = blob.getTeamNum();

	// find in factory storage

	if (GiveStorageItem(blob, name))
		return true;


	CBlob@[] factories;
	if (getBlobsByName("factory", @factories))
	{
		// find in storages

		for (uint step = 0; step < factories.length; ++step)
		{
			CBlob@ factory = factories[step];
			if (factory.getTeamNum() == team)
			{
				// check in perimeter
				{
					CMap@ map = getMap();
					CBlob@[] blobsInRadius;
					if (map.getBlobsInRadius(factory.getPosition(), factory.getRadius() * 3.0f, @blobsInRadius))
					{
						for (uint i = 0; i < blobsInRadius.length; i++)
						{
							CBlob @b = blobsInRadius[i];
							if (b.getName() == name)
							{
								if (!blob.server_PutInInventory(b))
								{
									b.setPosition(blob.getPosition());
								}

								return true;
							}
						}
					}
				}
			}
		}

		// produce

		if (forceProduce)
		{
			for (uint step = 0; step < factories.length; ++step)
			{
				CBlob@ factory = factories[step];
				if (factory.getTeamNum() == team && canProduce(factory, name))
				{
					CBitStream params;
					params.write_u16(blob.getNetworkID());
					params.write_string(name);
					factory.SendCommandOnlyServer(factory.getCommandID("factory give item"), params);
					return true;

				}
			}
		}
	}
	return false;
}

// base makes it

void MakeOrGiveItem(CBlob@ blob, const string &in name)
{
	const s32 team = blob.getTeamNum();

	// find in base storage

	if (GiveStorageItem(blob, name))
		return;

	// if not make it

	CBlob@ item = server_CreateBlob(name);
	if (item !is null)
	{
		if (!blob.server_PutInInventory(item))
			item.setPosition(blob.getPosition());
	}
}

CBlob@ MakeMaterial(CBlob@ blob,  const string &in name, const int quantity)
{
	CBlob@ mat = server_CreateBlobNoInit(name);

	if (mat !is null)
	{
		mat.Tag('custom quantity');
		mat.Init();

		mat.server_SetQuantity(quantity);

		if (not blob.server_PutInInventory(mat))
		{
			mat.setPosition(blob.getPosition());
		}
	}

	return mat;
}

void GiveSpawnResources(CRules@ this, CBlob@ blob, CPlayer@ player, WarPlayerInfo@ w_info)
{
	if (blob.getName() == "builder")
	{
		if (sv_test)
		{
			MakeMaterial(blob, "mat_stone", 250);
			MakeMaterial(blob, "mat_wood", 250);
			MakeMaterial(blob, "mat_gold", 250);
		}
		else
		{
			if (!GiveStorageItem(blob, "mat_wood"))
			{
				// make wood out of air
				if (w_info.canGetBuilderItems)
				{
					MakeMaterial(blob, "mat_wood", 30);
					w_info.canGetBuilderItems = false;
				}
			}

			GiveStorageItem(blob, "mat_stone");
		}
	}
	else if (blob.getName() == "archer")
	{
		// keep order reversed for proper picking default ammo
		if (!GiveFactoryItem(blob, "mat_arrows"))
		{
			// make arrows out of air
			if (w_info.canGetArcherItems)
			{
				MakeMaterial(blob, "mat_arrows", 30);
				w_info.canGetArcherItems = false;
			}
		}
		GiveFactoryItem(blob, "mat_waterarrows");
		GiveFactoryItem(blob, "mat_firearrows");
		GiveFactoryItem(blob, "mat_bombarrows");
	}
	else if (blob.getName() == "knight")
	{
		//GiveFactoryItem( blob, "food" );
		//GiveFactoryItem( blob, "satchel" );
		GiveFactoryItem(blob, "mat_waterbombs");
		GiveFactoryItem(blob, "mat_bombs");
	}
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (blob !is null && player !is null)
	{
		RulesCore@ core;
		this.get("core", @core);
		if (core !is null)
		{
			WarPlayerInfo@ w_info = cast < WarPlayerInfo@ > (core.getInfoFromPlayer(player));
			if (w_info !is null)
			{
				//if (    (w_info.canGetArcherItems && blob.getName() == "archer")
				//||	(w_info.canGetKnightItems && blob.getName() == "knight")
				//||	(w_info.canGetBuilderItems && blob.getName() == "builder")
				//	 )
				{
					GiveSpawnResources(this, blob, player, w_info);
				}
			}
		}
	}
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	if (victim !is null)
	{
		RulesCore@ core;
		this.get("core", @core);
		if (core !is null)
		{
			WarPlayerInfo@ w_info = cast < WarPlayerInfo@ > (core.getInfoFromPlayer(victim));
			if (w_info !is null)
			{
				w_info.canGetArcherItems = true;
				w_info.canGetKnightItems = true;
				w_info.canGetBuilderItems = true;
			}
		}
	}
}
