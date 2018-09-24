//Report.as
// report logic

//time (in seconds) between repeated reports
const u32 reportRepeatTime = 5 * 60;

const SColor reportMessageColor(255, 255, 0, 0);

void onInit(CRules@ this)
{
	this.addCommandID("notify");
	this.addCommandID("report");
}

bool onClientProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if((text_in == "!moderate" || text_in == "!m") && player.isMod())
	{
		moderate(this, player);

		//false so it doesn't show as normal public chat
		return false;
	}
	else if(text_in.substr(0, 1) == "!")
	{
		string[]@ tokens = text_in.split(" ");

		//check if we have tokens
		if(tokens.length > 1)
		{
			if(tokens[0] == "!report" || tokens[0] == "!r")
			{
				if(player is getLocalPlayer())
				{
					string baddieUsername = tokens[1];
					CPlayer@ baddie = getReportedPlayer(baddieUsername);

					if(baddie !is null)
					{
						//if he exists start more reporting logic
						if(reportAllowed(player, baddie))
						{
							report(this, player, baddie);
							client_AddToChat("You have reported: " + baddie.getCharacterName() + " (" + baddie.getUsername() + ")", reportMessageColor);
						}
						else if(player.hasTag("reported" + baddie.getUsername()))
						{
							client_AddToChat("You have already reported this player recently.", reportMessageColor);
						}
					}
					else
					{
						client_AddToChat("Player not found", reportMessageColor);
					}
				}
				//false for everyone so it doesn't show as normal chat
				return false;
			}
		}
	}

	return true;
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params ){
    if (isClient() && this.getCommandID("notify") == cmd)
	{
		if (getLocalPlayer().isMod())
		{
			client_AddToChat(params.read_string(), reportMessageColor);
			Sound::Play("ReportSound.ogg");
		}
    }
	else if (isServer() && this.getCommandID("report") == cmd)
	{
		string reportParams = params.read_string();
		string[]@ tokens = reportParams.split(" ");
		CPlayer@ player = getPlayerByUsername(tokens[0]);
		CPlayer@ baddie = getPlayerByUsername(tokens[1]);

		//tag player
		player.Tag("reported" + baddie.getUsername());

		player.set_u32("reported" + baddie.getUsername() + "At", Time());

		//tag baddie as reported
		baddie.Tag("reported");

		//initialise reportCount if it's missing
		if(!baddie.exists("reportCount"))
		{
			baddie.set_u8("reportCount", 0);
		}

		//increment the report count
		baddie.add_u8("reportCount", 1);

		player.Sync("reported" + baddie.getUsername(), true);
		player.Sync("reported" + baddie.getUsername() + "At", true);
		baddie.Sync("reported", true);
		baddie.Sync("reportCount", true);
	}
	else if (isServer() && this.getCommandID("report") == cmd)
	{
		string reportParams = params.read_string();
		string[]@ tokens = reportParams.split(" ");
		CPlayer@ player = getPlayerByUsername(tokens[0]);
		CPlayer@ baddie = getPlayerByUsername(tokens[1]);

		string playerUsername = player.getUsername();
		string baddieUsername = baddie.getUsername();

		tcpr("*REPORT " + playerUsername + " " + baddieUsername + " " + baddie.get_u8("reportCount"));
	}
}

bool reportAllowed(CPlayer@ player, CPlayer@ baddie)
{
	if (player is null or baddie is null) return false;

	bool allowed =
		// (never reported this player)
		!player.hasTag("reported" + baddie.getUsername())
		// (expire after however long)
		|| s32(Time() - player.get_u32("reported" + baddie.getUsername() + "At")) > reportRepeatTime;

	return allowed;
}

void report(CRules@ this, CPlayer@ player, CPlayer@ baddie)
{
	if(reportAllowed(player, baddie) && player !is baddie)
	{
		string playerUsername = player.getUsername();
		string baddieUsername = baddie.getUsername();
		string baddieCharacterName = baddie.getCharacterName();

		//propagate report to clients if they are relevant e.g. send report counts
		CBitStream reportParams;
		reportParams.write_string(player.getUsername() + " " + baddie.getUsername());
		this.SendCommand(this.getCommandID("report"), reportParams);

		CBitStream params;
        params.write_string("Report has been made of: " + baddieCharacterName + " (" + baddieUsername + ")");
        this.SendCommand(this.getCommandID("notify"), params);
	}
}

//Change to spectator cam on starting moderatation
void moderate(CRules@ this, CPlayer@ moderator)
{
	if(moderator !is null && moderator is getLocalPlayer())
	{
		CCamera@ camera = getCamera();
		CMap@ map = getMap();

		moderator.client_ChangeTeam(this.getSpectatorTeamNum());
		getHUD().ClearMenus();
		camera.setPosition(Vec2f(map.getMapDimensions().x / 2, map.getMapDimensions().y / 2));
	}

	moderator.Tag("moderator");
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	//remove moderator tag for people re-joining play
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
	//search for exact matches
	for(int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if(p.getCharacterName() == name || p.getUsername() == name)
		{
			return p;
		}
	}

	//search for partial matches
	CPlayer@[] matches;
	for(int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if( //partial match on
			//char name
			p.getCharacterName().toLower().findFirst(name.toLower(), 0) >= 0
			//or username
			|| p.getUsername().toLower().findFirst(name.toLower(), 0) >= 0
		) {
			matches.push_back(p);
		}
	}

	//found any matches?
	if(matches.length() > 0)
	{
		//only one? great!
		if(matches.length() == 1)
		{
			return matches[0];
		}
		//otherwise ambiguous
		else
		{
			client_AddToChat("Closest options are:");
			for(int i = 0; i < matches.length(); i++)
			{
				client_AddToChat("- " + matches[i].getCharacterName() + " (" + matches[i].getUsername() + ")");
			}
		}
	}

	return null;
}

CPlayer@ getPlayerByCharactername(string name)
{
	for(int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if(name == p.getCharacterName())
		{
			return p;
		}
	}

	return null;
}
