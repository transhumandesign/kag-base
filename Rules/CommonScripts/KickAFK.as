// kicks players that dont play for a given time
// by norill
// move people with kick immunity to spec instead of doing nothing -mazey

#define CLIENT_ONLY
#include "AdminLogic.as"

bool warned = false;
int warnTime = 0;
int lastMoveTime = 0;

const uint checkInterval = 90;
const uint totalToKickSeconds = 60 * 2 + 30;
const uint warnToKickSeconds = 60;
const uint idleToWarnSeconds = totalToKickSeconds - warnToKickSeconds;

void onTick(CRules@ this)
{
	if (getGameTime() % checkInterval != 0)
		return;

	CPlayer@ p = getLocalPlayer();
	CControls@ controls = getControls();
	if (p is null ||											//no player
		controls is null ||										//no controls
		p.getTeamNum() == getRules().getSpectatorTeamNum() ||	//or spectator
		getNet().isServer())								//or we're running the server
	{
		return;
	}

	bool kickImmunity = getSecurity().checkAccess_Feature(p, "kick_immunity");

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
				client_AddToChat("Move around or you will be " + (kickImmunity ? "moved to spectator" : "kicked") + " in "+warnToKickSeconds+" seconds!", SColor(255, 255, 100, 32));
				warned = true;
				warnTime = time;
			}
		}
	}

	if (warned && time - warnTime > warnToKickSeconds)
	{
		//so long, sucker
		client_AddToChat("You were " + (kickImmunity ? "moved to spectator" : "kicked") + " for being AFK too long.", SColor(255, 240, 50, 0));
		warned = false;
		if (!kickImmunity)
		{
			getNet().DisconnectClient();
		}
		else
		{
			joinNewSpecTeam(this, getLocalPlayer()); //Force-swap to spec team.
			client_AddToChat("You have just been swapped to spectator team, type !m to get back.", SColor(255,0,0,0));
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
	textOut = textIn;

	if (player is null) return true;

	// Return if it's not the local player
	if (not player.isMyPlayer()) return true;

	//but register a movement
	DidInput();

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