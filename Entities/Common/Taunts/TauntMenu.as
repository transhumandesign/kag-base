#include "WheelMenuCommon.as"
#include "TauntsCommon.as"

#define CLIENT_ONLY

const int GLOBAL_COOLDOWN = 120;
const int TEAM_COOLDOWN = 60;
const bool CAN_REPEAT_TAUNT = true;
const bool CLICK_CATEGORY = false;
const bool SHOW_IN_CHAT = true;

string menu_selected = "CATEGORIES";
string last_taunt;
int cooldown_time = 0;

void onInit(CRules@ rules)
{
	//You should never do this in a client only script, moved to EmoteBinderMenu.as
	//rules.addCommandID("display taunt");

	string filename = "TauntEntries.cfg";
	string cachefilename = "../Cache/" + filename;
	ConfigFile cfg;

	//attempt to load from cache first
	bool loaded = false;
	if (CFileMatcher(cachefilename).getFirst() == cachefilename && cfg.loadFile(cachefilename))
	{
		loaded = true;
	}
	else if (cfg.loadFile(filename))
	{
		loaded = true;
	}

	if (!loaded)
	{
		return;
	}

	//init main menu
	WheelMenu@ menu = get_wheel_menu(menu_selected);
	menu.option_notice = getTranslatedString("Select category");

	string[] names;
	cfg.readIntoArray_string(names, "CATEGORIES");

	if (names.length % 2 != 0)
	{
		error("TauntEntries.cfg is not in the form of visible_name; token;");
		return;
	}

	for (uint i = 0; i < names.length; i += 2)
	{
		WheelMenuEntry entry(names[i+1]);
		entry.visible_name = getTranslatedString(names[i]);
		menu.entries.push_back(@entry);

		//init each submenu
		WheelMenu@ submenu = get_wheel_menu(entry.name);
		submenu.option_notice = getTranslatedString("Select phrase");

		string[] more_names;
		cfg.readIntoArray_string(more_names, entry.name);

		if (more_names.length % 2 != 0)
		{
			error("TauntEntries.cfg is not in the form of visible_name; token;");
			return;
		}

		for (uint j = 0; j < more_names.length; j += 2)
		{
			WheelMenuEntry subentry(more_names[j+1]);
			subentry.visible_name = getTranslatedString(more_names[j]);
			submenu.entries.push_back(@subentry);
		}
	}
}

void onTick(CRules@ rules)
{
	CBlob@ blob = getLocalPlayerBlob();

	if (blob is null)
	{
		set_active_wheel_menu(null);
		return;
	}

	WheelMenu@ menu = get_wheel_menu(menu_selected);

	if (cooldown_time > 0) //spam cooldown
	{
		cooldown_time--;

		if (blob.isKeyJustPressed(key_taunts))
		{
			Sound::Play("NoAmmo.ogg");
		}
	}
	else if (blob.isKeyPressed(key_taunts) && get_active_wheel_menu() is null) //activate taunt menu
	{
		set_active_wheel_menu(@menu);
	}
	else if (blob.isKeyJustReleased(key_taunts) && get_active_wheel_menu() is menu) //exit taunt menu
	{
		if (menu_selected != "CATEGORIES")
		{
			WheelMenuEntry@ selected = menu.get_selected();
			if (selected !is null)
			{
				//same taunt spam prevention
				if (CAN_REPEAT_TAUNT || selected.visible_name != last_taunt)
				{
					bool globalTaunt = isGlobalTauntCategory(menu_selected);
					last_taunt = selected.visible_name;
					cooldown_time = globalTaunt ? GLOBAL_COOLDOWN : TEAM_COOLDOWN;

					if (SHOW_IN_CHAT)
					{
						client_SendChat(selected.visible_name, globalTaunt ? 0 : 1);
					}
					else
					{
						CBitStream params;
						params.write_u16(blob.getNetworkID());
						params.write_string(selected.visible_name);
						params.write_bool(globalTaunt);
						rules.SendCommand(rules.getCommandID("display taunt"), params, true);
					}
				}
				else
				{
					Sound::Play("NoAmmo.ogg");
				}
			}
		}

		menu_selected = "CATEGORIES";
		set_active_wheel_menu(null);
	}
	else if ( //select category
		get_active_wheel_menu() is menu && menu_selected == "CATEGORIES" &&
		(!CLICK_CATEGORY || blob.isKeyJustPressed(key_action1))
	) {
		WheelMenuEntry@ selected = menu.get_selected();
		if (selected !is null)
		{
			menu_selected = selected.name;
			WheelMenu@ submenu = get_wheel_menu(menu_selected);
			set_active_wheel_menu(@submenu);
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("display taunt"))
	{
		CPlayer@ player = getLocalPlayer();
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		string taunt = params.read_string();
		bool globalTaunt = params.read_bool();

		if (caller is null || !cl_chatbubbles)
		{
			return;
		}

		//only show team taunts to teammates
		if (globalTaunt || (player !is null && player.getTeamNum() == caller.getTeamNum()))
		{
			caller.Chat(taunt);
		}
	}
}
