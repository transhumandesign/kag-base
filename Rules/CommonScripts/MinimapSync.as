//Handle Minimap Sync on client join
//we could _probably_ rely on synced properties but they can cause quite a mess at startup

#include "MinimapHook.as"

//WARNING: rather this than pollute addcommandid namespace + deal with
//         initialisation order gotchas on net
u8 init_cmd = 20;

//script local "should send now" flag
bool needs_sync = false;

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
		this.SendCommand(init_cmd, bt);
		//done for now
		needs_sync = false;
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
			needs_sync = true;
		}
		else if(isClient() && from_server)
		{
			//recv minimap props
			bool legacy_minimap = false;
			bool show_gold = true;

			//note: error printed only; we want to write defaults still
			if(!bt.saferead_bool(legacy_minimap)) error("MiniMap Sync: failed to read legacy_minimap");
			if(!bt.saferead_bool(show_gold))      error("MiniMap Sync: failed to read show_gold");

			//write values
			map.legacyTileMinimap = legacy_minimap;

			//write props
			this.set_bool("legacy_minimap", legacy_minimap);
			this.set_bool("show_gold", show_gold);

			//re-build the minimap
			map.MakeMiniMap();
		}
	}
}