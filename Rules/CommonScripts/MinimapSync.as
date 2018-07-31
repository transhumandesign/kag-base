//Handle Minimap Sync on client join
//we could _probably_ rely on synced properties but they can cause quite a mess at startup

#include "MinimapHook.as"

//WARNING: rather this than pollute addcommandid namespace + deal with
//         initialisation order gotchas on net
u8 init_cmd = 20;

//limit amount of re-sync
//someone will join with this zero and will take it on sync
//iterates one each restart so players who were already here
//will be "in sync" and will just get the restart sync;
//their requests will be ignored
u8 last_synced_i = 0;

//script local "should send now" flag
bool needs_sync = false;

//script local "should rebuild map" flag
bool needs_regen = true;

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	if (isClient() && !isServer())
	{
		needs_sync = true;
	}

	if(isServer())
	{
		//next generation
		//(avoid zero; people join with zero)
		last_synced_i = Maths::Max(last_synced_i + 1, 1);
	}
}

void onTick(CRules@ this)
{
	if (needs_sync)
	{
		CBitStream bt;
		if (isServer())
		{
			//send minimap props
			bt.write_bool(true);
			bt.write_bool(this.get_bool("legacy_minimap"));
			bt.write_bool(this.get_bool("show_gold"));
		}
		else if (isClient())
		{
			//ask for minimap info
			bt.write_bool(false);
		}
		bt.write_u8(last_synced_i);
		this.SendCommand(init_cmd, bt);
		//done for now
		needs_sync = false;
	}

	if(needs_regen)
	{
		getMap().MakeMiniMap();
		needs_regen = false;
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ bt)
{
	if (cmd == init_cmd)
	{
		CMap@ map = getMap();

		bool from_server = false;
		if(!bt.saferead_bool(from_server))
		{
			error("MiniMap Sync: failed to read direction flag");
			return;
		}

		//(do nothing for localhost)
		if (isServer() && !from_server)
		{
			u8 cl_last_synced_i = 0;
			if(!bt.saferead_u8(cl_last_synced_i)) error("MiniMap Sync: failed to read sync i");

			//from someone new, effectively
			if (last_synced_i != cl_last_synced_i)
			{
				needs_sync = true;
			}
		}
		//only read server messages
		else if(isClient() && from_server)
		{
			//recv minimap props
			bool legacy_minimap = false;
			bool show_gold = true;
			u8 old_last_synced_i = last_synced_i;

			//note: error printed only; we want to write defaults still
			if(!bt.saferead_bool(legacy_minimap)) error("MiniMap Sync: failed to read legacy_minimap");
			if(!bt.saferead_bool(show_gold))      error("MiniMap Sync: failed to read show_gold");
			if(!bt.saferead_u8(last_synced_i))    error("MiniMap Sync: failed to read sync i");

			//write values
			map.legacyTileMinimap = legacy_minimap;

			//write props
			this.set_bool("legacy_minimap", legacy_minimap);
			this.set_bool("show_gold", show_gold);

			//re-build the minimap
			//(prevents re-rebuilding)
			if(last_synced_i != old_last_synced_i)
			{
				needs_regen = true;
			}
		}
	}
}