// show menu that only allows to join spectator

#include "SwitchFromSpec.as"

const int BUTTON_SIZE = 4;

void onInit(CRules@ this)
{
	this.addCommandID("pick teams");
	this.addCommandID("pick none");

	AddIconToken("$BLUE_TEAM$", "GUI/TeamIcons.png", Vec2f(96, 96), 0);
	AddIconToken("$RED_TEAM$", "GUI/TeamIcons.png", Vec2f(96, 96), 1);
	AddIconToken("$TEAMGENERIC$", "GUI/TeamIcons.png", Vec2f(96, 96), 2);
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
		menu.AddKeyCommand(KEY_ESCAPE, this.getCommandID("pick none"), exitParams);
		menu.SetDefaultCommand(this.getCommandID("pick none"), exitParams);

		string icon, name;

		for (int i = 0; i < this.getTeamsCount(); i++)
		{
			CBitStream params;
			params.write_u16(getLocalPlayer().getNetworkID());
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
					params.write_u16(getLocalPlayer().getNetworkID());
					params.write_u8(this.getSpectatorTeamNum());
					CGridButton@ button2 = menu.AddButton("$SPECTATOR$", getTranslatedString("Spectator"), this.getCommandID("pick teams"), Vec2f(BUTTON_SIZE / 2, BUTTON_SIZE), params);
				}
				icon = "$RED_TEAM$";
				name = "Red Team";
			}
			else
			{
				icon = "$TEAMGENERIC$";
				name = "Generic";
			}

			CGridButton@ button =  menu.AddButton(icon, getTranslatedString(name), this.getCommandID("pick teams"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
	}
}

// the actual team changing is done in the player management script -> onPlayerRequestTeamChange()

void ReadChangeTeam(CRules@ this, CBitStream @params)
{
	CPlayer@ player = getPlayerByNetworkId(params.read_u16());
	u8 team = params.read_u8();

	if (player is getLocalPlayer())
	{
		if (CanSwitchFromSpec(this, player, team))
		{
			ChangeTeam(player, team);
		}
		else
		{
			client_AddToChat("Game is currently full. Please wait for a new slot before switching teams.", ConsoleColour::GAME);
			Sound::Play("NoAmmo.ogg");
		}
	}
}

void ChangeTeam(CPlayer@ player, u8 team)
{
	player.client_ChangeTeam(team);
	getHUD().ClearMenus();
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("pick teams"))
	{
		ReadChangeTeam(this, params);
	}
	else if (cmd == this.getCommandID("pick none"))
	{
		getHUD().ClearMenus();
	}
}