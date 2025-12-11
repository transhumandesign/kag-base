#include "CTF_PopulateSpawnList.as"

const int BUTTON_SIZE = 2;
u16 LAST_PICK = 0;
u16 RESPAWNS_COUNT = 0;
bool REQUESTED_SPAWN = false;
bool SHOW_MENU = false;

CGridMenu@ getRespawnMenu()
{
	return getGridMenuByName(getTranslatedString("Pick spawn point"));
}

void RemoveRespawnMenu()
{
	CGridMenu@ menu = getRespawnMenu();
	if (menu !is null)
		menu.kill = true;
}

void BuildRespawnMenu(CRules@ this, CPlayer@ player, CBlob@[] respawns)
{
	RemoveRespawnMenu();

	if (player.getTeamNum() == this.getSpectatorTeamNum()) return;

	if (!REQUESTED_SPAWN)
	{
		REQUESTED_SPAWN = true;
		player.client_RequestSpawn(LAST_PICK); // spawn even without pick
	}

	// if there are no options then just respawn
	if (respawns.length <= 1)
	{
		LAST_PICK = 0;
		return;
	}

	SortByPosition(@respawns);

	// build menu for spawns
	const Vec2f menupos = getDriver().getScreenCenterPos() + Vec2f(0.0f, getDriver().getScreenHeight() / 2.0f - BUTTON_SIZE - 46.0f);
	CGridMenu@ menu = CreateGridMenu(menupos, null, Vec2f((respawns.length) * BUTTON_SIZE, BUTTON_SIZE), getTranslatedString("Pick spawn point"));
	if (menu !is null)
	{
		menu.modal = true;
		menu.deleteAfterClick = false;
		const u16 localID = player.getNetworkID();
		CBitStream params;
		for (uint i = 0; i < respawns.length; i++)
		{
			CBlob@ respawn = respawns[i];
			params.ResetBitIndex();
			params.write_u16(respawn.getNetworkID());
			const string msg = getTranslatedString("Spawn at {ITEM}").replace("{ITEM}", getTranslatedString(respawn.getInventoryName()));
			CGridButton@ button = menu.AddButton("$" + respawn.getName() + "$", msg, "CTF_PickSpawn.as", "Callback_PickSpawn", Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
			if (button !is null)
			{
				button.selectOneOnClick = true;

				if (LAST_PICK == respawn.getNetworkID())
				{
					button.SetSelected(1);
				}
			}
		}
	}
}

void onTick(CRules@ this)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null || !player.isMyPlayer()) return;

	if (SHOW_MENU)
	{
		const string propname = "ctf spawn time " + player.getUsername();
		if (this.exists(propname) && this.get_u8(propname) < 2 || this.isGameOver())
		{
			RemoveRespawnMenu();
			SHOW_MENU = false;
		}

		CBlob@[] respawns;
		PopulateSpawnList(@respawns, player.getTeamNum());
		if (RESPAWNS_COUNT != respawns.length || getRespawnMenu() is null)
		{
			RESPAWNS_COUNT = respawns.length;
			BuildRespawnMenu(this, player, respawns);
		}
	}
}

//hook after the change has been decided
void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	if (player !is null && player.isMyPlayer() && this.isMatchRunning())
	{
		SHOW_MENU = true;
		RESPAWNS_COUNT = -1;
	}
}

// local player requests a spawn right after death
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim !is null && victim.isMyPlayer() && !this.isGameOver())
	{
		SHOW_MENU = true;
		RESPAWNS_COUNT = -1;
	}
}

//now we know for sure that we don't have menus
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (blob !is null && player !is null && player.isMyPlayer())
	{
		getHUD().ClearMenus(true); // kill all even modal

		REQUESTED_SPAWN = false;
		SHOW_MENU = false;
	}
}

void Callback_PickSpawn(CBitStream@ params)
{
	CPlayer@ player = getLocalPlayer();
	u16 pick;
	if (!params.saferead_u16(pick)) return;

	LAST_PICK = pick; 

	if (player.getTeamNum() == getRules().getSpectatorTeamNum())
	{
		getHUD().ClearMenus(true);
	}
	else
	{
		player.client_RequestSpawn(pick);
	}
}

void SortByPosition(CBlob@[]@ spawns)
{
	// Selection Sort
	uint N = spawns.length;
	for (uint i = 0; i < N; i++)
	{
		uint minIndex = i;

		// Find the index of the minimum element
		for (uint j = i + 1; j < N; j++)
		{
			if (spawns[j].getPosition().x < spawns[minIndex].getPosition().x)
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
