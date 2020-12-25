#include "CommonBuilderBlocks.as"

const u8 MENU_WIDTH = 9;
const u8 MENU_HEIGHT  = 4;
const string SELECTED_PROP = "selected block: ";

const string BUILD_CMD = "builder binder command";

enum BUILD_SUBCMD {
	BIND_BLOCK,
	SELECT_KEYBIND,
	CLOSE_MENU,
	BUILD_SUBCMD_COUNT
};

BuildBlock[][] blocks;

void onInit(CRules@ this)
{
	this.addCommandID(BUILD_CMD);
	addCommonBuilderBlocks(blocks, 0, "CTF");

}

void NewBuilderMenu()
{
	CPlayer@ player = getLocalPlayer();
	if (player !is null && player.isMyPlayer())
	{
		//select first keybind to begin with
		string propname = SELECTED_PROP + player.getUsername();
		getRules().set_u8(propname, 0);
		ShowBuilderMenu(player);
	}

}

void ShowBuilderMenu(CPlayer@ player)
{
	//hide main menu and other gui
	Menu::CloseAllMenus();
	getHUD().ClearMenus(true);

	CRules@ rules = getRules();
	Vec2f center = getDriver().getScreenCenterPos();
	string description = getTranslatedString("Builder Block Hotkey Binder");

	CGridMenu@ menu = CreateGridMenu(center, null, Vec2f(MENU_WIDTH, MENU_HEIGHT), description);
	if (menu !is null)
	{
		menu.deleteAfterClick = false;

		CBitStream params;

		params.write_u8(CLOSE_MENU);
		params.write_string(player.getUsername());

		menu.AddKeyCommand(KEY_ESCAPE, rules.getCommandID(BUILD_CMD), params);
		menu.SetDefaultCommand(rules.getCommandID(BUILD_CMD), params);

		for (uint i = 0; i < blocks[0].length; i++)
		{
			BuildBlock@ b = blocks[0][i];
			string block_desc = getTranslatedString(b.description);

			CBitStream params;
			params.write_u8(BIND_BLOCK);
			params.write_string(player.getUsername());
			params.write_u8(i);

			CGridButton@ button = menu.AddButton(b.icon, block_desc, rules.getCommandID(BUILD_CMD), Vec2f(1, 1), params);

		}

		if (menu.getButtonsCount() % MENU_WIDTH != 0)
		{
			menu.FillUpRow();
		}

		CGridButton@ separator = menu.AddTextButton(getTranslatedString("Select a keybind below, then select the block you want"), Vec2f(MENU_WIDTH, 1));
		if (separator !is null)
		{
			separator.clickable = false;
			separator.SetEnabled(false);
		}

		//get current block keybinds
		ConfigFile@ cfg = openBlockBindingsConfig();

		array<u8> blockBinds = {
			read_block(cfg, "block_1", 0),
			read_block(cfg, "block_2", 1),
			read_block(cfg, "block_3", 2),
			read_block(cfg, "block_4", 3),
			read_block(cfg, "block_5", 4),
			read_block(cfg, "block_6", 5),
			read_block(cfg, "block_7", 6),
			read_block(cfg, "block_8", 7),
			read_block(cfg, "block_9", 8)
		};

		string propname = SELECTED_PROP + player.getUsername();
		u8 selected = rules.get_u8(propname);

		for (int i = 0; i < 9; i++)
		{
			CBitStream params;
			params.write_u8(SELECT_KEYBIND);
			params.write_string(player.getUsername());
			params.write_u8(i);

			BuildBlock@ b = blocks[0][blockBinds[i]];

			CGridButton@ button = menu.AddButton(b.icon, getTranslatedString("Select key {KEY_NUM}").replace("{KEY_NUM}", (i + 1) + ""), rules.getCommandID(BUILD_CMD), Vec2f(1, 1), params);
			button.selectOneOnClick = true;

			if (selected == i)
			{
				button.SetSelected(1);
			}
		}

	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd != this.getCommandID(BUILD_CMD))
	{
		return;
	}

	string name;
	u8 subcmd;

	if(!params.saferead_u8(subcmd)) return;
	if(!params.saferead_string(name)) return;

	CPlayer@ caller = getPlayerByUsername(name);

	//check validity so far
	if (caller is null || !caller.isMyPlayer() || subcmd >= BUILD_SUBCMD_COUNT)
	{
		return;
	}

	if (subcmd == BIND_BLOCK)
	{
		string propname = SELECTED_PROP + caller.getUsername();
		u8 selected = this.get_u8(propname);

		//must select keybind first
		if (selected == -1)
		{
			return;
		}

		u8 block;
		if(!params.saferead_u8(block)) return;

		string key = "block_" + (selected + 1);

		//get block bindings cfg file
		ConfigFile@ cfg = openBlockBindingsConfig();

		//bind block
		cfg.add_string(key, "" + block);
		cfg.saveFile("BlockBindings.cfg");

		//update keybinds in menu
		ShowBuilderMenu(caller);
	}
	else if (subcmd == SELECT_KEYBIND)
	{
		u8 block;
		if(!params.saferead_u8(block)) return;

		string propname = SELECTED_PROP + caller.getUsername();
		this.set_u8(propname, block);
	}
	else if (subcmd == CLOSE_MENU)
	{
		getHUD().ClearMenus(true);
	}

	CBlob@ blob = caller.getBlob();
	if (blob !is null)
	{
		blob.Tag("reload blocks");
	}
}
