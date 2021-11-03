//TODO: display emote names when hovered (would require a complete list which EmoteEntries.cfg is not)
//		update emotes instantly

#include "EmotesCommon.as";

const array<u8> EXCLUDED_EMOTES = {
	Emotes::dots,
	Emotes::pickup
};
const u8 MENU_WIDTH = 9;
const u8 MENU_HEIGHT = Maths::Ceil((Emotes::emotes_total - EXCLUDED_EMOTES.length - 1) / MENU_WIDTH) + 4;
const string SELECTED_PROP = "selected emote: ";

const string EMOTE_CMD = "emote command";
enum EMOTE_SUBCMD {
	BIND_EMOTE,
	SELECT_KEYBIND,
	CLOSE_MENU,
	EMOTE_SUBCMD_COUNT
};

void onInit(CRules@ this)
{
	this.addCommandID(EMOTE_CMD);
	this.addCommandID("display taunt");

	//load emote icons
	for (u16 i = 0; i < Emotes::emotes_total; i++)
	{
		AddIconToken(getIconName(i), "Emoticons.png", Vec2f(32, 32), i);
	}
}

void NewEmotesMenu()
{
	CPlayer@ player = getLocalPlayer();
	if (player !is null && player.isMyPlayer())
	{
		//select first keybind to begin with
		string propname = SELECTED_PROP + player.getUsername();
		getRules().set_u8(propname, 0);

		ShowEmotesMenu(player);
	}
}

void ShowEmotesMenu(CPlayer@ player)
{
	//hide main menu and other gui
	Menu::CloseAllMenus();
	getHUD().ClearMenus(true);

	CRules@ rules = getRules();
	Vec2f center = getDriver().getScreenCenterPos();
	string description = getTranslatedString("Emote Hotkey Binder");

	//display main grid menu
	CGridMenu@ menu = CreateGridMenu(center, null, Vec2f(MENU_WIDTH, MENU_HEIGHT), description);
	if (menu !is null)
	{
		menu.deleteAfterClick = false;

		//press escape to close
		CBitStream params;

		params.write_u8(CLOSE_MENU);
		params.write_string(player.getUsername());

		menu.AddKeyCommand(KEY_ESCAPE, rules.getCommandID(EMOTE_CMD), params);
		menu.SetDefaultCommand(rules.getCommandID(EMOTE_CMD), params);

		//display emote grid
		for (int i = 0; i < Emotes::emotes_total; i++)
		{
			if (EXCLUDED_EMOTES.find(i) > -1)
			{
				continue;
			}

			CBitStream params;
			params.write_u8(BIND_EMOTE);
			params.write_string(player.getUsername());
			params.write_u8(i);
			CGridButton@ button = menu.AddButton(getIconName(i), description, rules.getCommandID(EMOTE_CMD), Vec2f(1, 1), params);
		}

		//fill in extra slots in emote grid
		if (menu.getButtonsCount() % MENU_WIDTH != 0)
		{
			menu.FillUpRow();
		}

		//separator with info
		CGridButton@ separator = menu.AddTextButton(getTranslatedString("Select a keybind below, then select the emote you want"), Vec2f(MENU_WIDTH, 1));
		separator.clickable = false;
		separator.SetEnabled(false);

		//get current emote keybinds
		ConfigFile@ cfg = openEmoteBindingsConfig();

		array<u8> emoteBinds = {
			read_emote(cfg, "emote_1", Emotes::attn),
			read_emote(cfg, "emote_2", Emotes::smile),
			read_emote(cfg, "emote_3", Emotes::frown),
			read_emote(cfg, "emote_4", Emotes::mad),
			read_emote(cfg, "emote_5", Emotes::laugh),
			read_emote(cfg, "emote_6", Emotes::wat),
			read_emote(cfg, "emote_7", Emotes::troll),
			read_emote(cfg, "emote_8", Emotes::disappoint),
			read_emote(cfg, "emote_9", Emotes::ladder),
			read_emote(cfg, "emote_10", Emotes::flex),
			read_emote(cfg, "emote_11", Emotes::down),
			read_emote(cfg, "emote_12", Emotes::smug),
			read_emote(cfg, "emote_13", Emotes::left),
			read_emote(cfg, "emote_14", Emotes::okhand),
			read_emote(cfg, "emote_15", Emotes::right),
			read_emote(cfg, "emote_16", Emotes::thumbsup),
			read_emote(cfg, "emote_17", Emotes::up),
			read_emote(cfg, "emote_18", Emotes::thumbsdown)
		};

		string propname = SELECTED_PROP + player.getUsername();
		u8 selected = rules.get_u8(propname);

		//display row of current emote keybinds
		for (int i = 0; i < 18; i++)
		{
			CBitStream params;
			params.write_u8(SELECT_KEYBIND);
			params.write_string(player.getUsername());
			params.write_u8(i);
			CGridButton@ button = menu.AddButton(getIconName(emoteBinds[i]), getTranslatedString("Select key {KEY_NUM}").replace("{KEY_NUM}", (i + 1) + ""), rules.getCommandID(EMOTE_CMD), Vec2f(1, 1), params);
			button.selectOneOnClick = true;
			// button.hoverText = "     Key " + (i + 1) + "\n";

			//reselect keybind if one was selected before
			if (selected == i)
			{
				button.SetSelected(1);
			}
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID(EMOTE_CMD))
	{
		string name;
		u8 subcmd;

		if(!params.saferead_u8(subcmd)) return;
		if(!params.saferead_string(name)) return;

		CPlayer@ caller = getPlayerByUsername(name);

		//check validity so far
		if (caller is null || !caller.isMyPlayer() || subcmd >= EMOTE_SUBCMD_COUNT)
		{
			return;
		}

		if (subcmd == BIND_EMOTE)
		{
			string propname = SELECTED_PROP + caller.getUsername();
			u8 selected = this.get_u8(propname);

			//must select keybind first
			if (selected == -1)
			{
				return;
			}

			u8 emote;
			if(!params.saferead_u8(emote)) return;

			string key = "emote_" + (selected + 1);

			//get emote bindings cfg file
			ConfigFile@ cfg = openEmoteBindingsConfig();

			//bind emote
			cfg.add_string(key, "" + emote);
			cfg.saveFile("EmoteBindings.cfg");

			//update keybinds in menu
			ShowEmotesMenu(caller);
		}
		else if (subcmd == SELECT_KEYBIND)
		{
			u8 emote;
			if(!params.saferead_u8(emote)) return;

			string propname = SELECTED_PROP + caller.getUsername();
			this.set_u8(propname, emote);
		}
		else if (subcmd == CLOSE_MENU)
		{
			getHUD().ClearMenus(true);
		}

		//trigger a reload of the blob's emote bindings either way
		CBlob@ cblob = caller.getBlob();
		if (cblob !is null)
		{
			cblob.Tag("reload emotes");
		}
	}
	
}

string getIconName(u8 emoteIndex)
{
	return "$EMOTE" + (emoteIndex + 1) + "$";
}
