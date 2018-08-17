//Report.as
// report logic
// wip

#define CLIENT_ONLY

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
		string[]@ tokens = text_in.split(" ");

		if(tokens.length > 1)															//check if we have tokens
		{
			if((tokens[0] == "!report" || tokens[0] == "!r") && !security.isPlayerIgnored(player) && player is getLocalPlayer())
			{
				string baddieUsername = tokens[1];
				CPlayer@ baddie = getReportedPlayer(baddieUsername);

				if(baddie !is null)
				{
					if(!player.hasTag("reported" + baddie.getUsername()))
					{
						report(this, player, baddie);										//if he exists start more reporting logic
						client_AddToChat("You have reported: " + baddie.getCharacterName() + " (" + baddie.getUsername() + ")", SColor(255, 255, 0, 0));
					} else if(player.hasTag("reported" + baddie.getUsername()))
					{
						client_AddToChat("You have already reported this player recently.", SColor(255, 255, 0, 0));
					}
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
	if(!baddie.hasTag("reported") && !baddie.exists("reportCount") && !player.hasTag("reported" + baddie.getUsername()))
	{
		player.Tag("reported" + baddie.getUsername());
		baddie.Tag("reported");																//tag player as reported
		baddie.set_u8("reportCount", 1);
	} else if(!player.hasTag("reported" + baddie.getUsername()))
	{
		baddie.add_u8("reportCount", 1);
	} 
	
	string baddieUsername = baddie.getUsername();
	string baddieCharacterName = baddie.getCharacterName();								//¯\_(ツ)_/¯

    CBlob@[] players;																	//get all players in server
	getBlobsByTag("player", @players);

	for (u8 i = 0; i < players.length; i++)												//print message to mods
	{
		if(players[i].getPlayer().isMod())
		{
			// print("Reporting " + baddieUsername);
			// print("Reporting " + baddie.getUsername());
			// print("Team number: " + baddie.getTeamNum());
			client_AddToChat("Report has been made of: " + baddieCharacterName + " (" + baddieUsername + ")", SColor(255, 255, 0, 0));
			Sound::Play("ReportSound.ogg", players[i].getPosition());
		}
	}
}

void moderate(CRules@ this, CPlayer@ moderator)											//Change to spectator cam on moderate
{
	if (moderator is getLocalPlayer())
	{
		CCamera@ camera = getCamera();
		CMap@ map = getMap();

		moderator.client_ChangeTeam(this.getSpectatorTeamNum());
		getHUD().ClearMenus();
		camera.setPosition(Vec2f(map.getMapDimensions().x / 2, map.getMapDimensions().y / 2));
	}

	isModerating = true;
	moderator.Tag("moderator");
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	// print("changed team");
	if(oldteam == this.getSpectatorTeamNum())
	{
		if(player.hasTag("moderator"))
		{
			player.Untag("moderator");
		}
	}
}

CPlayer@ getReportedPlayer(string name)
{
	CBlob@[] players;
	getBlobsByTag("player", @players);

	for(int i = 0; i < players.length(); i++)
	{
		if (players[i].getPlayer().getCharacterName() == name || players[i].getPlayer().getUsername() == name)
		{
			return players[i].getPlayer();
		}
	}

	CPlayer@[] matches;

	for(int i = 0; i < players.length(); i++)
	{
		if (players[i].getPlayer().getCharacterName().toLower().findFirst(name.toLower(), 0) >= 0)
		{
			matches.push_back(players[i].getPlayer());
		} else if (players[i].getPlayer().getUsername().toLower().findFirst(name.toLower(), 0) >= 0)
		{
			matches.push_back(players[i].getPlayer());
		}
	}

	if(matches.length() > 0)
	{
		if(matches.length() == 1)
		{
			return matches[0];
		} else {
			client_AddToChat("Closest options are:");
			for(int i = 0; i < matches.length(); i++)
			{
				client_AddToChat("- " + matches[i].getCharacterName() + " (" + matches[i].getCharacterName() + ")");
			}

			return null;
		}
	}

	return null;
}

CPlayer@ getPlayerByCharactername(string name)
{
	CBlob@[] players;
	getBlobsByTag("player", @players);

	for(int i = 0; i < players.length(); i++)
	{
		if(name == players[i].getPlayer().getCharacterName())
		{
			return players[i].getPlayer();
		}
	}

	return null;
}
