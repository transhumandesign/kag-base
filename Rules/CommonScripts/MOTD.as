//Message of the Day
// gets a base string from a config
// then appends the names of all mods that are online
// 		(or a message if none are online)

string config_filename = "MOTD.cfg";
string MOTD_base = "";
bool MOTD_display_mods = true; //TODO: not working properly

//(because players aren't loaded at onInit time, seems to not work on server)

void load_motd_strings()
{
	//load from cfg so it can be configured
	ConfigFile cfg = ConfigFile();
	cfg.loadFile(config_filename);

	MOTD_base = cfg.read_string("message", "");
	MOTD_display_mods = cfg.read_bool("display_mods", true);

	//sync
	getRules().set_string("_motd_base", MOTD_base);
	getRules().Sync("_motd_base", true);
	getRules().set_bool("_motd_display_mods", MOTD_display_mods);
	getRules().Sync("_motd_display_mods", true);
}

string get_motd()
{
	string motd = "";

	//anything to say?
	if(MOTD_base != "")
	{
		motd = MOTD_base + "\n";
	}

	//list mods?
	if(MOTD_display_mods)
	{
		string[] mods;
		for(int i = 0; i < getPlayersCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			if(getSecurity().checkAccess_Feature(p, "admin_color") || p.isRCON())
			{
				mods.push_back(p.getCharacterName());
			}
		}

		if(mods.length > 0)
		{
			motd += "Moderators present: "+join(mods, ", ");
		}
		else
		{
			motd += "(No moderators are currently present)";
		}
	}

	return motd;
}

//hooks + sync

void onInit(CRules@ this)
{
	if(getNet().isServer())
	{
		load_motd_strings();
	}
	if(getNet().isClient())
	{
		MOTD_base = this.get_string("_motd_base");
		MOTD_display_mods = this.get_bool("_motd_display_mods");
		client_AddToChat("Message of the Day:\n"+get_motd());
	}
}
