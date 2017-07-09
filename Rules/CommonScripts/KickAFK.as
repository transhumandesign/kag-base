// kicks players that dont play for a given time
// by norill

#define CLIENT_ONLY

bool warned = false;

const uint checkInterval = 90;
const uint idleToWarnSeconds = 60 * 1 + 30;
const uint warnToKickSeconds = 60;
uint warnTime;

void onTick(CRules@ this)
{
	int time = getGameTime();
	if (time % checkInterval != 0)
		return;

	CPlayer@ p = getLocalPlayer();
    CControls@ controls = getControls();
	if (controls is null || p is null || p.getBlob() is null || getNet().isServer() || getSecurity().checkAccess_Feature(p, "kick_immunity"))
		return;

	if (controls.lastKeyPressTime == 0)
	{
		controls.lastKeyPressTime = time;
		return;
	}

	int diff = time - controls.lastKeyPressTime - idleToWarnSeconds * 30;
	if (diff > 0)
	{
		if (!warned && diff <= checkInterval)
		{
			client_AddToChat("Seems like you are currently away from your keyboard.", SColor(255, 255, 100, 32));
			client_AddToChat("Move around or you will be kicked in "+warnToKickSeconds+" seconds!", SColor(255, 255, 100, 32));
			warned = true; //you have been warned
			warnTime = time;
		}
	}
	else if (warned)
	{
		client_AddToChat("AFK Kick avoided.", SColor(255, 20, 120, 0));
		warned = false;
	}

	if (warned && time - warnTime > warnToKickSeconds * 30)
	{
		//so long, sucker
		client_AddToChat("You were kicked for being AFK too long.", SColor(255, 240, 50, 0));
		warned = false;
		getNet().DisconnectClient();
	}
}

void onRestart(CRules@ this)
{
	warned = false;
}

void onInit(CRules@ this)
{
	warned = false;
}
