// show menu that only allows to join spectator

const int BUTTON_SIZE = 4;

void onInit(CRules@ this)
{
	this.addCommandID("pick teams");
	this.addCommandID("pick spectator");
	this.addCommandID("pick none");

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
		params.write_u16(local.getNetworkID());
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

void ReadChangeTeam(CRules@ this, CBitStream @params, int team)
{
	CPlayer@ player = getPlayerByNetworkId(params.read_u16());
	if (player is getLocalPlayer())
	{
		player.client_ChangeTeam(team);
		getHUD().ClearMenus();
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("pick teams"))
	{
		ReadChangeTeam(this, params, -1);
	}
	else if (cmd == this.getCommandID("pick spectator"))
	{
		ReadChangeTeam(this, params, this.getSpectatorTeamNum());
	}
	else if (cmd == this.getCommandID("pick none"))
	{
		getHUD().ClearMenus();
	}
}
