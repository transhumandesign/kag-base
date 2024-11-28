// kicks players that dont play for a given time
// by norill
// move people with kick immunity to spec instead of doing nothing -mazey
// move people into spec if seeding servers -gingerbeard

#define CLIENT_ONLY

bool warned = false;
int warnTime = 0;
int lastMoveTime = 0;

const uint checkInterval = 90;
const uint totalToKickSeconds = 60 * 2 + 30;
const uint warnToKickSeconds = 60;
const uint idleToWarnSeconds = totalToKickSeconds - warnToKickSeconds;
const f32 seedingPercent = 0.5f;

const string[] ignoredSeedingGamemodes = { "Sandbox", "Challenge" };

void onTick(CRules@ this)
{
	if (getGameTime() % checkInterval != 0)
		return;

	CPlayer@ p = getLocalPlayer();
	CControls@ controls = getControls();
	if (p is null || controls is null || isServer())
		return;

	if (p.getTeamNum() == this.getSpectatorTeamNum())
		return;

	const bool kickImmunity = getSecurity().checkAccess_Feature(p, "kick_immunity");
	const bool seeding = getPlayerCount() <= sv_maxplayers * seedingPercent && ignoredSeedingGamemodes.find(this.gamemode_name) == -1;
	const bool kickToSpectator = kickImmunity || seeding;

	//not updated yet or numbers from last game?
	if(controls.lastKeyPressTime == 0 || controls.lastKeyPressTime > getGameTime())
	{
		controls.lastKeyPressTime = getGameTime();
	}

	if(getGameTime() - controls.lastKeyPressTime < checkInterval + 1 &&		//pressed recently?
		controls.lastKeyPressTime > (checkInterval * 2))					//pressed at least after the first little while
	{
		DidInput();
	}

	int time = Time_Local();
	int diff = time - lastMoveTime - idleToWarnSeconds;
	if (!warned)
	{
		if (diff > 0)
		{
			if(diff > totalToKickSeconds) {
				//something has "gone wrong"; (probably just lastMoveTime = 0)
				//pretend an input happened and move on
				lastMoveTime = time;
			}
			else
			{
				//you have been warned
				client_AddToChat("Seems like you are currently away from your keyboard.", SColor(255, 255, 100, 32));
				client_AddToChat("Move around or you will be " + (kickToSpectator ? "moved to spectator" : "kicked") + " in "+warnToKickSeconds+" seconds!", SColor(255, 255, 100, 32));
				warned = true;
				warnTime = time;
			}
		}
	}

	if (warned && time - warnTime > warnToKickSeconds)
	{
		//so long, sucker
		client_AddToChat("You were " + (kickToSpectator ? "moved to spectator" : "kicked") + " for being AFK too long.", SColor(255, 240, 50, 0));
		warned = false;
		if (!kickToSpectator)
		{
			getNet().DisconnectClient();
		}
		else
		{
			p.client_ChangeTeam(this.getSpectatorTeamNum());
		}
	}
}

void DidInput()
{
	lastMoveTime = Time_Local();
	RemoveWarning();
}

void RemoveWarning()
{
	if(warned)
	{
		client_AddToChat("AFK penalty avoided.", SColor(255, 20, 120, 0));
		warned = false;
	}
}

bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	if (player !is null && player.isMyPlayer())
	{
		DidInput();
	}

	return true;
}

void onRestart(CRules@ this)
{
	//(nothing - if they were afk last round we still want to boot em )
}

void onInit(CRules@ this)
{
	warned = false;
	warnTime = Time_Local();
	lastMoveTime = Time_Local();
}
