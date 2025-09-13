// show menu that only allows to join spectator

const int BUTTON_SIZE = 4;

void onInit(CRules@ this)
{
	AddIconToken("$TEAMS$", "GUI/MenuItems.png", Vec2f(32, 32), 1);
	AddIconToken("$SPECTATOR$", "GUI/MenuItems.png", Vec2f(32, 32), 19);
}

void Callback_PickTeams(CBitStream@ params)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	player.client_ChangeTeam(-1);
	getHUD().ClearMenus();
}

void Callback_PickSpectator(CBitStream@ params)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	player.client_ChangeTeam(getRules().getSpectatorTeamNum());
	getHUD().ClearMenus();
}

void Callback_PickNone(CBitStream@ params)
{
	getHUD().ClearMenus();
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
		menu.AddKeyCallback(KEY_ESCAPE, "TeamMenuJustSpectator.as", "Callback_PickNone", exitParams);
		menu.SetDefaultCallback("TeamMenuJustSpectator.as", "Callback_PickNone", exitParams);

		CBitStream params;
		if (local.getTeamNum() == this.getSpectatorTeamNum())
		{
			CGridButton@ button = menu.AddButton("$TEAMS$", getTranslatedString("Auto-pick teams"), "TeamMenuJustSpectator.as", "Callback_PickTeams", Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
		else
		{
			CGridButton@ button = menu.AddButton("$SPECTATOR$", getTranslatedString("Spectator"), "TeamMenuJustSpectator.as", "Callback_PickSpectator", Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
	}
}