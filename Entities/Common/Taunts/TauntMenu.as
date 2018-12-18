#include "WheelMenuCommon.as"

#define CLIENT_ONLY

string menu_selected = "categories";

void onInit(CRules@ rules)
{
	ConfigFile cfg;
	if (!cfg.loadFile("../Cache/TauntEntries.cfg")
	 && !cfg.loadFile("TauntEntries.cfg"))
	{
		return;
	}

	//init main menu
	WheelMenu@ menu = get_wheel_menu(menu_selected);
	menu.option_notice = getTranslatedString("Select category");

	string[] names;
	cfg.readIntoArray_string(names, "categories");

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
		submenu.option_notice = getTranslatedString("Select " + entry.name);

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

	if (blob.isKeyJustPressed(key_taunts))
	{
		set_active_wheel_menu(@menu);
	}
	else if (blob.isKeyJustReleased(key_taunts) && get_active_wheel_menu() is menu)
	{
		if (menu_selected != "categories")
		{
			WheelMenuEntry@ selected = menu.get_selected();
			if (selected !is null)
			{
				blob.Chat(selected.visible_name);
			}
		}

		menu_selected = "categories";
		set_active_wheel_menu(null);
	}
	else if (get_active_wheel_menu() is menu && menu_selected == "categories") //category selected
	{
		WheelMenuEntry@ selected = menu.get_selected();
		if (selected !is null)
		{
			menu_selected = selected.name;
			WheelMenu@ submenu = get_wheel_menu(menu_selected);
			set_active_wheel_menu(@submenu);
		}
	}
}