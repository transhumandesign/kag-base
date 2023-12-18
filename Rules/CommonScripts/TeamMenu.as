// show menu that only allows to join spectator

#include "SwitchFromSpec.as"

const int BUTTON_SIZE = 4;

void onInit(CRules@ this)
{
	AddIconToken("$BLUE_TEAM$", "GUI/TeamIcons.png", Vec2f(96, 96), 0);
	AddIconToken("$RED_TEAM$", "GUI/TeamIcons.png", Vec2f(96, 96), 1);
	AddIconToken("$TEAMGENERIC$", "GUI/TeamIcons.png", Vec2f(96, 96), 2);
}

void Callback_PickTeams(CBitStream@ params)
{
	u8 team;
	if (!params.saferead_u8(team)) return;

	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	if (CanSwitchFromSpec(getRules(), player, team))
	{
		player.client_ChangeTeam(team);
		getHUD().ClearMenus();
	}
	else
	{
		client_AddToChat("Game is currently full. Please wait for a new slot before switching teams.", ConsoleColour::GAME);
		Sound::Play("NoAmmo.ogg");
	}
}

void Callback_PickNone(CBitStream@ params)
{
	getHUD().ClearMenus();
}

void ShowTeamMenu(CRules@ this)
{
	if (getLocalPlayer() is null)
	{
		return;
	}

	getHUD().ClearMenus(true);

	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), null, Vec2f((this.getTeamsCount() + 0.5f) * BUTTON_SIZE, BUTTON_SIZE), "Change team");

	if (menu !is null)
	{
		CBitStream exitParams;
		menu.AddKeyCallback(KEY_ESCAPE, "TeamMenu.as", "Callback_PickNone", exitParams);
		menu.SetDefaultCallback("TeamMenu.as", "Callback_PickNone", exitParams);

		string icon, name;

		for (int i = 0; i < this.getTeamsCount(); i++)
		{
			CBitStream params;
			params.write_u8(i);

			if (i == 0)
			{
				icon = "$BLUE_TEAM$";
				name = "Blue Team";
			}
			else if (i == 1)
			{
				// spectator
				{
					CBitStream params;
					params.write_u8(this.getSpectatorTeamNum());
					CGridButton@ button2 = menu.AddButton("$SPECTATOR$", getTranslatedString("Spectator"), "TeamMenu.as", "Callback_PickTeams", Vec2f(BUTTON_SIZE / 2, BUTTON_SIZE), params);
				}
				icon = "$RED_TEAM$";
				name = "Red Team";
			}
			else
			{
				icon = "$TEAMGENERIC$";
				name = "Generic";
			}

			CGridButton@ button =  menu.AddButton(icon, getTranslatedString(name), "TeamMenu.as", "Callback_PickTeams", Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
	}
}