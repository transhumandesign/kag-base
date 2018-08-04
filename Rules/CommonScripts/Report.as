//Report.as
// report logic
// wip

#define CLIENT_ONLY

// const int r = 50;
bool isModerating;

void onInit(CRules@ this)
{
	isModerating = false;
}

bool onClientProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	CSecurity@ security = getSecurity();												//server security object

	if((text_in == "!moderate" || text_in == "!m") && player.isMod())
	{
		moderate(this, player);

		return false;																	//false so it doesn't show as normal public chat
	}
	else if(text_in.substr(0, 1) == "!")												//reporting logic
	{
		string[]@ tokens = text_in.split(" ");											//check if we have tokens

		if (tokens.length > 1)
		{
			string baddieUsername = tokens[1];
			string match = closestMatch(baddieUsername);
			CPlayer@ baddie = getPlayerByUsername(match);

			//print(closestMatch(baddieUsername).getUsername());
			
			// print("the username used will be '" + match + "'");
			
			if((tokens[0] == "!report" || tokens[0] == "!r") && !security.isPlayerIgnored(player) && player is getLocalPlayer())
			{
				if(baddie !is null)
				{
					report(this, player, baddie);										//if he exists start more reporting logic
					client_AddToChat("You have reported: " + baddieUsername, SColor(255, 255, 0, 0));
				} else {
					client_AddToChat("Player not found", SColor(255, 255, 0, 0));
				}
			}

			return false;																//false so it doesn't show as normal chat
		}
	}

	return true;
}

void report(CRules@ this, CPlayer@ player, CPlayer@ baddie)
{
	baddie.Tag("reported");																//tag player as reported
	string baddieUsername = baddie.getUsername();
	string baddieCharacterName = baddieUsername;										//¯\_(ツ)_/¯

    CBlob@[] players;																	//get all players in server
	getBlobsByTag("player", @players);

	for (u8 i = 0; i < players.length; i++)												//print message to mods
	{
		if(players[i].getPlayer().isMod())
		{
			// print("Reporting " + baddieUsername);
			// print("Reporting " + baddie.getUsername());
			// print("Team number: " + baddie.getTeamNum());
			client_AddToChat("Report has been made of: " + baddieUsername, SColor(255, 255, 0, 0));
			Sound::Play("ReportSound.ogg", players[i].getPosition());
		}
	}
}

void moderate(CRules@ this, CPlayer@ moderator)											//Change to spectator cam on moderate
{
	if (moderator is getLocalPlayer())
	{
		moderator.client_ChangeTeam(this.getSpectatorTeamNum());
		getHUD().ClearMenus();
	}

	isModerating = true;
	moderator.Tag("moderator");
}

// void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
// {
// 	// print("changed team");
// 	if(oldteam == this.getSpectatorTeamNum())
// 	{
// 		if(player.hasTag("moderator"))
// 		{
// 			player.Untag("moderator");
// 		}
// 	}
// }

string closestMatch(const string username)
{
	CBlob@[] players;
	getBlobsByTag("player", @players);
	// print("there are " + formatInt(players.length(), "", 0) + "players");

	array<string> usernames;
	array<int> matches;

	for(int i = 0; i < players.length(); i++)
	{
		usernames.insertLast(players[i].getPlayer().getUsername());
		// print(players[i].getPlayer().getUsername());
	}

	// print("usernames: " + formatInt(usernames.length(), "", 0));

	for(int i = 0; i < usernames.length(); i++)
	{
		// print("searching");
		if (usernames[i].toLower().findFirst(username.toLower(), 0) >= 0)
		{
			// print("found");
			matches.insertLast(i);
		}
	}

	// print("matches: " + formatInt(matches.length(), "", 0));

	// print("closest match '" + usernames[matches[0]] + "'");
	return usernames[matches[0]];
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