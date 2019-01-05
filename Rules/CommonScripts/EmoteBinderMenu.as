//TODO: display emote names when hovered (would require a complete list which EmoteEntries.cfg is not)
//		update emotes instantly

#include "EmotesCommon.as";

const array<u8> EXCLUDED_EMOTES = {
	Emotes::dots,
	Emotes::pickup
};
const u8 MENU_WIDTH = 9;
const u8 MENU_HEIGHT = Maths::Ceil((Emotes::emotes_total - EXCLUDED_EMOTES.length - 1) / MENU_WIDTH) + 2;

int selected = -1;

void onInit(CRules@ this)
{
	this.addCommandID("bind emote");
	this.addCommandID("select keybind");
	this.addCommandID("close menu");

	//load emote icons
	for (u16 i = 0; i < Emotes::emotes_total; i++)
	{
		AddIconToken(getIconName(i), "Emoticons.png", Vec2f(32, 32), i);
	}
}

void NewEmotesMenu()
{
	//ensure a keybind isn't selected
	selected = -1;
	ShowEmotesMenu();
}

void ShowEmotesMenu()
{
	CPlayer@ player = getLocalPlayer();
	if (player !is null)
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
			menu.AddKeyCommand(KEY_ESCAPE, rules.getCommandID("close menu"), params);
			menu.SetDefaultCommand(rules.getCommandID("close menu"), params);

			//display emote grid
			for (int i = 0; i < Emotes::emotes_total; i++)
			{
				if (EXCLUDED_EMOTES.find(i) > -1)
				{
					continue;
				}

				CBitStream params;
				params.write_u8(i);
				CGridButton@ button = menu.AddButton(getIconName(i), description, rules.getCommandID("bind emote"), Vec2f(1, 1), params);
			}
			
			//fill in extra slots in emote grid
			if (menu.getButtonsCount() % MENU_WIDTH != 0)
			{
				menu.FillUpRow();
			}

			//separator with info
			CGridButton@ separator = menu.AddTextButton("Select a keybind below, then select the emote you want", Vec2f(MENU_WIDTH, 1));
			separator.clickable = false;
			separator.SetEnabled(false);

			//get current emote keybinds
			ConfigFile cfg = ConfigFile();
			if (!cfg.loadFile("../Cache/EmoteBindings.cfg") &&
				!cfg.loadFile("EmoteBindings.cfg"))
			{
				return;
			}

			array<u8> emoteBinds = {
				read_emote(cfg, "emote_1", Emotes::attn),
				read_emote(cfg, "emote_2", Emotes::smile),
				read_emote(cfg, "emote_3", Emotes::frown),
				read_emote(cfg, "emote_4", Emotes::mad),
				read_emote(cfg, "emote_5", Emotes::laugh),
				read_emote(cfg, "emote_6", Emotes::wat),
				read_emote(cfg, "emote_7", Emotes::troll),
				read_emote(cfg, "emote_8", Emotes::disappoint),
				read_emote(cfg, "emote_9", Emotes::ladder)
			};
			
			//display row of current emote keybinds
			for (int i = 0; i < 9; i++)
			{
				CBitStream params;
				params.write_u8(i);
				CGridButton@ button = menu.AddButton(getIconName(emoteBinds[i]), "Select key " + (i + 1), rules.getCommandID("select keybind"), Vec2f(1, 1), params);
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
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("bind emote"))
	{
		//must select keybind first
		if (selected == -1)
		{
			return;
		}

		u8 emote = params.read_u8();
		string key = "emote_" + (selected + 1);

		//get emote bindings cfg file
		ConfigFile cfg = ConfigFile();
		if (!cfg.loadFile("../Cache/EmoteBindings.cfg") &&
			!cfg.loadFile("EmoteBindings.cfg"))
		{
			return;
		}

		//bind emote
		cfg.add_string(key, "" + emote);
		cfg.saveFile("EmoteBindings.cfg");

		//update keybinds in menu
		ShowEmotesMenu();
	}
	else if (cmd == this.getCommandID("select keybind"))
	{
		selected = params.read_u8();
	}
	else if (cmd == this.getCommandID("close menu"))
	{
		getHUD().ClearMenus(true);
	}
}

string getIconName(u8 emoteIndex)
{
	return "$EMOTE" + (emoteIndex + 1) + "$";
}
