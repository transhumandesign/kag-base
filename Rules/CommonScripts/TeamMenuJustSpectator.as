// show menu that only allows to join spectator

const int BUTTON_SIZE = 4;

void onInit(CRules@ this)
{
	this.addCommandID("pick teams"); // dumb client->client command, TODO: add func callbacks for cgridmenu in engine
	this.addCommandID("pick spectator"); // dumb client->client command, TODO: add func callbacks for cgridmenu in engine
	this.addCommandID("pick none"); // dumb client->client command, TODO: add func callbacks for cgridmenu in engine

	AddIconToken("$TEAMS$", "GUI/MenuItems.png", Vec2f(32, 32), 1);
	AddIconToken("$SPECTATOR$", "GUI/MenuItems.png", Vec2f(32, 32), 19);
}

void ShowTeamMenu(CRules@ this)
{
	CPlayer@ local = getLocalPlayer();
	if (local is null)
	{
		return;
	}

	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), null, Vec2f(BUTTON_SIZE, BUTTON_SIZE), "Change team");

	if (menu !is null)
	{
		CBitStream exitParams;
		menu.AddKeyCommand(KEY_ESCAPE, this.getCommandID("pick none"), exitParams);
		menu.SetDefaultCommand(this.getCommandID("pick none"), exitParams);

		CBitStream params;
		if (local.getTeamNum() == this.getSpectatorTeamNum())
		{
			CGridButton@ button = menu.AddButton("$TEAMS$", getTranslatedString("Auto-pick teams"), this.getCommandID("pick teams"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
		else
		{
			CGridButton@ button = menu.AddButton("$SPECTATOR$", getTranslatedString("Spectator"), this.getCommandID("pick spectator"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
	}
}

// the actual team changing is done in the player management script -> onPlayerRequestSpawn()
void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("pick teams") && isClient())
	{
		CPlayer@ player = getLocalPlayer();
		if (player is null) return;

		player.client_ChangeTeam(-1);
		getHUD().ClearMenus();
	}
	else if (cmd == this.getCommandID("pick spectator") && isClient())
	{
		CPlayer@ player = getLocalPlayer();
		if (player is null) return;

		player.client_ChangeTeam(this.getSpectatorTeamNum());
		getHUD().ClearMenus();
	}
	else if (cmd == this.getCommandID("pick none") && isClient())
	{
		getHUD().ClearMenus();
	}
}
