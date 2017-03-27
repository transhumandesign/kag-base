#include "CTF_PopulateSpawnList.as"
#include "HallCommon.as"

const int BUTTON_SIZE = 2;
u16 LAST_PICK = 0;
bool MENU_ALREADY = false;

void onInit(CRules@ this)
{
	this.addCommandID("pick default");
	this.addCommandID("pick spawn");
}

void BuildRespawnMenu(CRules@ this, CPlayer@ player)
{
	getHUD().ClearMenus(true); // kill all even modal

	const int teamNum = player.getTeamNum();
	const u16 localID = getLocalPlayer().getNetworkID();

    CBlob@ oldrespawn = getBlobByNetworkID(LAST_PICK);
    if(oldrespawn !is null) //don't use last pick if it's under raid
    {
        if(isUnderRaid(oldrespawn))
        {
            LAST_PICK = 0;

        }

    }

	if (teamNum != this.getSpectatorTeamNum())
	{

		if (!MENU_ALREADY)
		{
			MENU_ALREADY = true;
			player.client_RequestSpawn(LAST_PICK);	// spawn even without pick
		}

		CBlob@[] respawns;
		PopulateSpawnList(@respawns, teamNum);

		SortByPosition(@respawns, teamNum);

		// if there are no posts just respawn
		if (respawns.length <= 1)
		{
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
				CGridButton@ button2 = menu.AddButton("$" + respawnName + "$", "Spawn at " + respawn.getInventoryName(), this.getCommandID("pick spawn"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);				
                if (button2 !is null)
				{
					button2.selectOneOnClick = true;

                    if(isUnderRaid(respawn))
                    {
                        button2.SetEnabled(false);
                        button2.SetHoverText("respawn is contested");

                    }

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

void onTick(CRules@ this)
{
	/*if(getNet().isClient()) //if you can fix the infinite spawning, feel free to uncomment :)
	{
		CPlayer@ player = getLocalPlayer();
		CControls@ controls = getControls();
		if(player !is null && controls !is null && 	//got what we need
			player.getBlob() is null)				//player blob dead
		{
			if(controls.ActionKeyPressed( AK_ACTION1 ) && !getHUD().hasMenus())
			{
				BuildRespawnMenu(this, player);
			}
		}
	}*/

	CPlayer@ p = getLocalPlayer();

	if (p is null || !p.isMyPlayer()) { return; }

    string propname = "ctf spawn time " + p.getUsername();
    if(this.exists(propname))
    {
        u8 spawn = this.get_u8(propname);
        if(spawn < 2)
        {
            getHUD().ClearMenus(true);
            return;

        }

    }

}

//hook after the change has been decided
void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	if (player !is null && player.isMyPlayer())  //please stop ;(
	{
		BuildRespawnMenu(this, player);

	}
}

// local player requests a spawn right after death
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim !is null && victim.isMyPlayer() && !this.isGameOver())
	{
		BuildRespawnMenu(this, victim);
	}
}

//now we know for sure that we don't have menus
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (blob !is null && player !is null && player.isMyPlayer())
	{
		getHUD().ClearMenus(true); // kill all even modal

		MENU_ALREADY = false;
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
		//getHUD().ClearMenus(true); // kill all even modal
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

	}
}

void SortByPosition(CBlob@[]@ spawns, const int teamNum)
{
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
}
