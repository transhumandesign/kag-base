// report logic
// wip

#define CLIENT_ONLY

#include "Spectator.as";

bool isModerating;
string moderatorUsername;
string baddieUsername;
int specTeam;

void onInit(CRules@ this)
{
	isModerating = false;
	specTeam = this.getSpectatorTeamNum();
	// _moderator = null;
	// _baddie = null;
}

bool onClientProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if((text_in == "!moderate" || text_in == "!m") && player.isMod())
	{
		//should get last person to be reported...
		


		return false; //false so it doesn't show as normal public chat
	}
	// reporting logic
	else if (text_in.substr(0, 1) == "!")
	{
		// check if we have tokens
		string[]@ tokens = text_in.split(" ");

		//server security object
		CSecurity@ security = getSecurity();

		if (tokens.length > 1)
		{
			if ((tokens[0] == "!report" || tokens[0] == "!r") && !security.isPlayerIgnored(player) && player is getLocalPlayer())
			{
				//check if reported player exists
				string baddieUsername = tokens[1];
				string baddieCharacterName = baddieUsername; //no, but idk
				CPlayer@ baddie = getPlayerByUsername(baddieUsername);

				if(baddie !is null)
				{
					//if he exists start more reporting logic
					report(player, baddie);
					client_AddToChat("You have reported: " + baddieUsername, SColor(255, 255, 0, 0));
				}
				else {
					client_AddToChat("not found", SColor(255, 255, 0, 0));
				}
			}
			else if((tokens[0] == "!moderate" || tokens[0] == "!m") && player.isMod())
			{
				baddieUsername = tokens[1];
				string baddieCharacterName = baddieUsername;
				CPlayer@ baddie = getPlayerByUsername(baddieUsername);
				moderatorUsername = player.getUsername();

				if(baddie !is null)
				{
					if(baddie.hasTag("reported") && player.isMod())
					{
						client_AddToChat("You're moderating " + baddieUsername, SColor(255, 255, 0, 0));
						moderate(this, player, baddie);
					}
					else if(player.isMod())
					{
						client_AddToChat("The person you're moderating has not been reported, but you may do so anyway.", SColor(255, 255, 0, 0));
						moderate(this, player, baddie);
					}
				}
			}

			return false; //false so it doesn't show as normal chat
		}
	}

	return true;
}

void report(CPlayer@ moderator, CPlayer@ baddie)
{
	string baddieUsername = baddie.getUsername();
	string baddieCharacterName = baddieUsername; //¯\_(ツ)_/¯

	//tag player as reported
	baddie.Tag("reported");

    //get all players in server
    CBlob@[] allBlobs;
	getBlobs(@allBlobs);
	CPlayer@[] allPlayers;

    for (u32 i = 0; i < allBlobs.length; i++)
	{
		if(allBlobs[i].hasTag("player"))
		{
			allPlayers.insertLast(allBlobs[i].getPlayer());
		}
    }

	//print message to mods
	for (u32 i = 0; i < allPlayers.length; i++)
	{
		if(allPlayers[i].isMod())
		{
			print("You're mod");
			print("Reporting " + baddieUsername);
			print("Reporting " + baddie.getUsername());
			print("Reporting " + baddie.getCharacterName());
			print("Reporting " + baddie.getTeamNum());
			client_AddToChat("Report has been made of: " + baddieUsername, SColor(255, 255, 0, 0));
			Sound::Play("ReportSound.ogg", moderator.getBlob().getPosition());
		}
	}
}

void moderate(CRules@ this, CPlayer@ moderator, CPlayer@ baddie)
{
	string baddieUsername = baddie.getUsername();
	string baddieCharacterName = baddieUsername; //no, but idk

	CBlob@ moderatorBlob = moderator is null ? moderator.getBlob() : null;
	CBlob@ baddieBlob = baddie is null ? baddie.getBlob() : null;

	CCamera@ camera = getCamera();

	
	moderator.client_ChangeTeam(specTeam);
	onModerate(this, moderator, baddie);
	isModerating = true;
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	if(oldteam == specTeam)
	{
		isModerating = false;
	}
}

// void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
// {
// 	CCamera@ camera = getCamera();
// 	if (camera !is null && player !is null && player is getLocalPlayer())
// 	{
		
// 	}
// }

<<<<<<< HEAD
void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	isModerating = false;
}

void onRender(CRules@ this)
=======
//Change to spectator cam on death
void onModerate(CRules@ this, CPlayer@ moderator, CPlayer@ baddie)
>>>>>>> [...] can actually stop moderating
{
	CCamera@ camera = getCamera();
	CBlob@ moderatorBlob = moderator !is null ? moderator.getBlob() : null;
	CBlob@ baddieBlob = baddie !is null ? baddie.getBlob() : null;

	//Player died to someone
	if (camera !is null && moderator is getLocalPlayer())
	{	
		if (moderatorBlob !is null)
		{
			moderatorBlob.ClearButtons();
			moderatorBlob.ClearMenus();

		}

		if (baddieBlob !is null)
		{
			SetTargetPlayer(baddieBlob.getPlayer());
			camera.setPosition(baddieBlob.getPosition());
			camera.setTarget(baddieBlob);
			camera.mousecamstyle = 1; // follow
		}
		else
		{
			camera.setTarget(null);

		}

	}

}

void onRender(CRules@ this)
{
	//death effect
	CCamera@ camera = getCamera();
	if (camera !is null && getLocalPlayerBlob() is null && getLocalPlayer() !is null)
	{
		camera.setPosition(baddieBlob.getPosition());
	}

	if (targetPlayer() !is null && getLocalPlayerBlob() is null)
	{
		GUI::SetFont("menu");
		GUI::DrawText(
			getTranslatedString("Following {CHARACTERNAME} ({USERNAME})")
			.replace("{CHARACTERNAME}", targetPlayer().getCharacterName())
			.replace("{USERNAME}", targetPlayer().getUsername()),
			Vec2f(getScreenWidth() / 2 - 90, getScreenHeight() * (0.2f)),
			Vec2f(getScreenWidth() / 2 + 90, getScreenHeight() * (0.2f) + 30),
			SColor(0xffffffff), true, true
		);
	}
}
