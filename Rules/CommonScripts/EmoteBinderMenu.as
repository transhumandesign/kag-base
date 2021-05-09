//TODO: display emote names when hovered (would require a complete list which EmoteEntries.cfg is not)
//		update emotes instantly

#include "EmotesCommon.as";

const array<string> EXCLUDED_EMOTES = {
	"dots",
	"pickup"
};
const u8 MENU_WIDTH = 9;
u8 MENU_HEIGHT;
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

	dictionary emotes;
	this.get("emotes", emotes);
	string[] tokens = emotes.getKeys();

	MENU_HEIGHT = Maths::Ceil((tokens.size() - EXCLUDED_EMOTES.length - 1) / MENU_WIDTH) + 4;

	//load emote icons
	for (u16 i = 0; i < tokens.size(); i++)
	{
		Emote@ emote;
		emotes.get(tokens[i], @emote);

		AddIconToken(getIconName(emote.token), emote.pack.filePath, Vec2f(32, 32), emote.index);
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

		dictionary emotes;
		rules.get("emotes", emotes);
		string[] tokens = emotes.getKeys();

		//display emote grid
		for (int i = 0; i < tokens.size(); i++)
		{
			Emote@ emote;
			if (!emotes.get(tokens[i], @emote) || EXCLUDED_EMOTES.find(emote.token) > -1)
			{
				continue;
			}

			CBitStream params;
			params.write_u8(BIND_EMOTE);
			params.write_string(player.getUsername());
			params.write_string(emote.token);
			CGridButton@ button = menu.AddButton(getIconName(emote.token), description, rules.getCommandID(EMOTE_CMD), Vec2f(1, 1), params);
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

		array<string> emoteBinds = {
			read_emote(cfg, emotes, "emote_1", "attn"),
			read_emote(cfg, emotes, "emote_2", "smile"),
			read_emote(cfg, emotes, "emote_3", "frown"),
			read_emote(cfg, emotes, "emote_4", "mad"),
			read_emote(cfg, emotes, "emote_5", "laugh"),
			read_emote(cfg, emotes, "emote_6", "wat"),
			read_emote(cfg, emotes, "emote_7", "troll"),
			read_emote(cfg, emotes, "emote_8", "disappoint"),
			read_emote(cfg, emotes, "emote_9", "ladder"),
			read_emote(cfg, emotes, "emote_10", "flex"),
			read_emote(cfg, emotes, "emote_11", "down"),
			read_emote(cfg, emotes, "emote_12", "smug"),
			read_emote(cfg, emotes, "emote_13", "left"),
			read_emote(cfg, emotes, "emote_14", "okhand"),
			read_emote(cfg, emotes, "emote_15", "right"),
			read_emote(cfg, emotes, "emote_16", "thumbsup"),
			read_emote(cfg, emotes, "emote_17", "up"),
			read_emote(cfg, emotes, "emote_18", "thumbsdown")
		};

		string propname = SELECTED_PROP + player.getUsername();
		u8 selected = rules.get_u8(propname);

		//display row of current emote keybinds
		for (int i = 0; i < emoteBinds.size(); i++)
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

			string token;
			if(!params.saferead_string(token)) return;

			string key = "emote_" + (selected + 1);

			//get emote bindings cfg file
			ConfigFile@ cfg = openEmoteBindingsConfig();

			//bind emote
			cfg.add_string(key, token);
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

string getIconName(string token)
{
	return "$EMOTE" + token + "$";
}
