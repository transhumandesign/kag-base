//Report.as
// report logic
// wip

#define CLIENT_ONLY

const int r = 50;
bool isModerating;

void onInit(CRules@ this)
{
	isModerating = false;
}

bool onClientProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	//server security object
	CSecurity@ security = getSecurity();

	if((text_in == "!moderate" || text_in == "!m") && player.isMod())
	{
		moderate(this, player);

		return false; //false so it doesn't show as normal public chat
	}
	// reporting logic
	else if (text_in.substr(0, 1) == "!")
	{
		// check if we have tokens
		string[]@ tokens = text_in.split(" ");

		if (tokens.length > 1)
		{
			string baddieUsername = tokens[1];
			CPlayer@ baddie = getPlayerByUsername(baddieUsername);
			
			if ((tokens[0] == "!report" || tokens[0] == "!r") && !security.isPlayerIgnored(player) && player is getLocalPlayer())
			{
				if(baddie !is null && !player.isMod())
				{
					//if he exists start more reporting logic
					report(this, player, baddie);
					client_AddToChat("You have reported: " + baddieUsername, SColor(255, 255, 0, 0));
				}
				else {
					client_AddToChat("Player not found", SColor(255, 255, 0, 0));
				}
			}
			// else if((tokens[0] == "!moderate" || tokens[0] == "!m") && player.isMod())
			// {
			// 	if(baddie !is null)
			// 	{
			// 		if(player.isMod() && player is getLocalPlayer())
			// 		{
			// 			if(baddie.hasTag("reported"))
			// 			{
			// 				client_AddToChat("You're moderating " + baddieUsername, SColor(255, 255, 0, 0));
			// 			}
			// 			else
			// 			{
			// 				client_AddToChat("The person you're moderating has not been reported, but you may do so anyway.", SColor(255, 255, 0, 0));
			// 			}

			// 			moderate(this, player, baddie);
			// 		}
			// 	}
			// }

			return false; //false so it doesn't show as normal chat
		}
	}

	return true;
}

void report(CRules@ this, CPlayer@ moderator, CPlayer@ baddie)
{
	string baddieUsername = baddie.getUsername();
	string baddieCharacterName = baddieUsername; //¯\_(ツ)_/¯

	//tag player as reported
	baddie.Tag("reported");

    //get all players in server
    CBlob@[] players;
	getBlobsByTag("player", @players);

	//print message to mods
	for (u8 i = 0; i < players.length; i++)
	{
		if(players[i].getPlayer().isMod())
		{
			print("Reporting " + baddieUsername);
			print("Reporting " + baddie.getUsername());
			print("Reporting " + baddie.getTeamNum());
			client_AddToChat("Report has been made of: " + baddieUsername, SColor(255, 255, 0, 0));
			Sound::Play("ReportSound.ogg", moderator.getBlob().getPosition());
		}
	}
}

//Change to spectator cam on moderate
void moderate(CRules@ this, CPlayer@ moderator)
{
	if (moderator is getLocalPlayer())
	{
		moderator.client_ChangeTeam(this.getSpectatorTeamNum());
		getHUD().ClearMenus();
	}
	isModerating = true;
	moderator.Tag("moderator");
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	print("changed team");
	if(oldteam == this.getSpectatorTeamNum())
	{
		if(player.hasTag("moderator"))
		{
			player.Untag("moderator");
		}
	}
}

CPlayer@ closestMatch(const string& in username)
{
	int ocurrances = 0;
	CBlob@[] players;
	getBlobsByTag("player", @players);

	string[] usernames;
	string[] possibleMatches;

	for(int i = 0; i < players.length(); i++)
	{
		usernames[i] = players[i].getPlayer().getUsername();
	}

	for(int i = 0; i < usernames.length(); i++)
	{
		if (usernames[i].findFirst(username, 0) > 0)
		{
			ocurrances++;
			possibleMatches[i] = usernames[i];
		}
	}

	if(possibleMatches.length() == 1)
	{
		return getPlayerByUsername(possibleMatches[1]);
	}

	return null;
}
