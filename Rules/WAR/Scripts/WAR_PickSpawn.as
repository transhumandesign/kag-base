#include "WAR_PopulateSpawnList.as"

const int BUTTON_SIZE = 2;
u16 LAST_PICK = 0;

void onInit(CRules@ this)
{
	this.addCommandID("pick default");
	this.addCommandID("pick spawn");
}

// local player requests a spawn right after death

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim !is null && victim.isMyPlayer())
	{
		getHUD().ClearMenus(true); // kill all even modal

		victim.client_RequestSpawn(LAST_PICK);	// spawn even without pick

		const int teamNum = victim.getTeamNum();
		const u16 localID = getLocalPlayer().getNetworkID();

		if (teamNum != this.getSpectatorTeamNum())
		{
			CBlob@[] respawns;
			PopulateSpawnList(@respawns, teamNum);

			SortByPosition(@respawns, teamNum);

			// if there are no posts just respawn

			if (respawns.length <= 1)
			{
				//  print("DEBUG: client_RequestSpawn");
				LAST_PICK = 0;
				return;
			}

			CGridMenu@ oldmenu = getGridMenuByName("Pick spawn");

			if (oldmenu !is null)
			{
				oldmenu.kill = true;
			}

			// build menu for spawns
			CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, getDriver().getScreenHeight() / 2.0f - BUTTON_SIZE - 46.0f), null, Vec2f((respawns.length) * BUTTON_SIZE, BUTTON_SIZE), "Pick spawn point");

			if (menu !is null)
			{
				menu.modal = true;
				menu.deleteAfterClick = false;
				CBitStream params;
				for (uint i = 0; i < respawns.length; i++)
				{
					CBlob@ respawn = respawns[i];
					const string respawnName = respawn.getName();
					params.ResetBitIndex();
					params.write_netid(localID);
					params.write_netid(respawn.getNetworkID());

					string text = getTranslatedString("Spawn at {NAME}").replace("{NAME}", getTranslatedString(respawn.getInventoryName()));
					CGridButton@ button2 = menu.AddButton("$" + respawnName + "$", text, this.getCommandID("pick spawn"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
					if (button2 !is null)
					{
						button2.selectOneOnClick = true;

						if (LAST_PICK == respawn.getNetworkID())
						{
							button2.SetSelected(1);
						}
					}
				}

				// default behaviour on clicking anywhere else
				if (respawns.length > 0)
				{
					params.ResetBitIndex();
					params.write_netid(localID);
					params.write_netid(LAST_PICK);
					menu.SetDefaultCommand(this.getCommandID("pick default"), params);
				}
			}
		}
	}
}

void ReadPickCmd(CRules@ this, CBitStream @params)
{
	CPlayer@ player = getPlayerByNetworkId(params.read_netid());
	const u16 pick = params.read_netid();

	LAST_PICK = pick; // global!

	if (player is getLocalPlayer())
	{
		if (player.getTeamNum() == this.getSpectatorTeamNum())
		{
			getHUD().ClearMenus(true);
		}
		else
		{
			player.client_RequestSpawn(pick);
		}
		getHUD().ClearMenus(true); // kill all even modal
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("pick spawn"))
	{
		ReadPickCmd(this, params);
	}
	else if (cmd == this.getCommandID("pick default"))
	{
		//CGridMenu@ menu = getGridMenuByName("Pick spawn point");
		//if (menu !is null) {
		//	menu.kill = true;
		//}
	}
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (blob !is null && player !is null && player.isMyPlayer())
	{
		getHUD().ClearMenus(true); // kill all even modal
	}
}

void SortByPosition(CBlob@[]@ spawns, const int teamNum)
{
	//printf("teamNum " + teamNum );
	// Selection Sort
	uint N = spawns.length;
	for (uint i = 0; i < N; i++)
	{
		uint minIndex = i;

		// Find the index of the minimum element
		for (uint j = i + 1; j < N; j++)
		{
			if (
			    (teamNum == 0 && spawns[j].getPosition().x < spawns[minIndex].getPosition().x)
			    ||
			    (teamNum == 1 && spawns[j].getPosition().x < spawns[minIndex].getPosition().x)
			)
			{
				minIndex = j;
			}
		}

		// Swap if i-th element not already smallest
		if (minIndex > i)
		{
			CBlob@ temp = spawns[i];
			@spawns[i] = spawns[minIndex];
			@spawns[minIndex] = temp;
		}
	}

	//for (uint i = 0; i < spawns.length; i++)
	//{
	//	printf("spawn " + spawns[i].getName() + " " + spawns[i].getPosition().x );
	//}
}