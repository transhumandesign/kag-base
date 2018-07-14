// report logic
// wip

#define CLIENT_ONLY

bool isModerating;
string _moderatorUsername;
string _baddieUsername;
int specTeam;

void onInit(CRules@ this)
{
	isModerating = false;
	specTeam = this.getSpectatorTeamNum();
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
				_baddieUsername = tokens[1];
				CPlayer@ baddie = getPlayerByUsername(_baddieUsername);

				if(baddie !is null)
				{
					string baddieCharacterName = _baddieUsername;
					_moderatorUsername = player.getUsername();

					if(player.isMod() && player is getLocalPlayer())
					{
						if(baddie.hasTag("reported"))
						{
							client_AddToChat("You're moderating " + _baddieUsername, SColor(255, 255, 0, 0));
							moderate(this, player, baddie);
						}
						else
						{
							client_AddToChat("The person you're moderating has not been reported, but you may do so anyway.", SColor(255, 255, 0, 0));
							moderate(this, player, baddie);
						}
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

//Change to spectator cam on moderate
void moderate(CRules@ this, CPlayer@ moderator, CPlayer@ baddie)
{
	print(baddie.getBlob().getLightColor());
}
