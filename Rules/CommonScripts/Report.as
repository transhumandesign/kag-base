//Report.as
// report logic

//time (in seconds) between repeated reports
const u32 reportRepeatTime = 1 * 60;

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
					string p_name = player.getUsername();
					string b_name = tokens[1];
					CPlayer@ baddie = getReportedPlayer(b_name);

					if(baddie !is null)
					{
						string baddie_name = baddie.getUsername();
						if(reportAllowed(this, player, baddie))
						{
							//if he exists start more reporting logic
							report(this, player, baddie);
							client_AddToChat("You have reported: " + baddie.getCharacterName() + " (" + baddie_name + ")", reportMessageColor);
						}
						else if(this.get_u32(p_name + "_reported_at") > 0)
						{
							client_AddToChat("You have already reported a player recently", reportMessageColor);
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

//on new player join we must initialize the required variables
void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if(isServer())
	{
		string p_name = player.getUsername();

		if(!this.exists(p_name + "_report_count"))
		{
			this.set_u8(p_name + "_report_count", 0);
		}
		if(!this.exists(p_name + "_reported_at"))
		{
			this.set_u32(p_name + "_reported_at", 0);
		}

		this.set_bool(p_name + "_moderator", false);

		this.Sync(p_name + "_report_count", true);
		this.Sync(p_name + "_reported_at", true);
		this.Sync(p_name + "_moderator", true);
	}
	
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params){
    if (isClient() && this.getCommandID("report") == cmd)
    {
        if (getLocalPlayer().isMod())
        {
            string p_name = params.read_string();
            string b_name = params.read_string();

            CPlayer@ baddie = getPlayerByUsername(b_name);

            if(baddie !is null){
                client_AddToChat("Report has been made of: " + baddie.getCharacterName() + " (" + b_name + ")", reportMessageColor);
                Sound::Play("ReportSound.ogg");
            }
        }
    }
	else if (isServer() && this.getCommandID("report") == cmd)
	{
		string p_name = params.read_string();
        string b_name = params.read_string();

        CPlayer@ player = getPlayerByUsername(p_name);
        CPlayer@ baddie = getPlayerByUsername(b_name);

		//server gets info from client and decides if it will report baddie
		if(player !is baddie)
		{
			//initialise report_count if it's missing
			if(!this.exists(b_name + "_report_count"))
			{
				this.set_u8(b_name + "_report_count", 0);
			}

			//initialise reported timer if it's missing
			if(!this.exists(p_name + "_reported_at"))
			{
				this.set_u32(p_name + "_reported_at", 0);
			}

			//initialise x reported y if it's missing, this will forbid a plyer from reporting another player multiple times
			if(!this.exists(p_name + "_reported_" + b_name))
			{
				this.set_bool(p_name + "_reported_" + b_name, true);
			}

			//set time at which player reported baddie
			this.set_u32(p_name + "_reported_at", Time());
			//increment baddie's report count
			this.add_u8(b_name + "_report_count", 1);

			//sync props to clients
			this.Sync(p_name + "_reported_at", true);
			this.Sync(b_name + "_report_count", true);
			this.Sync(p_name + "_reported_" + b_name, true);

			tcpr("*REPORT " + p_name + " " + b_name + " " + this.get_u8(b_name + "_report_count") + " " + getNet().joined_servername);
		}
	}
}

bool reportAllowed(CRules@ this, CPlayer@ player, CPlayer@ baddie)
{
	if (player is null || baddie is null) return false;

	string p_name = player.getUsername();
	string b_name = baddie.getUsername();

	//cannot report yourself
	if (baddie is player)
	{
		client_AddToChat("You cannot report yourself", reportMessageColor);
		return false;
	}

	//cannot report bots
	if (baddie.isBot())
	{
		client_AddToChat("You cannot report a bot", reportMessageColor);
		return false;
	}

	//unique player cannot report another unique player more than once
	if (this.get_bool(p_name + "_reported_" + b_name))
	{
		client_AddToChat("You cannot report the same player twice", reportMessageColor);
		return false;
	}
	
	//hasn't reported in a while
	bool allowed = s32(Time() - this.get_u32(p_name + "_reported_at")) > reportRepeatTime;

	return allowed;
}

void report(CRules@ this, CPlayer@ player, CPlayer@ baddie)
{
		string playerUsername = player.getUsername();
		string baddieUsername = baddie.getUsername();
		string baddieCharacterName = baddie.getCharacterName();

		//send report information to server
        CBitStream report_params;
        report_params.write_string(player.getUsername());
        report_params.write_string(baddie.getUsername());
        this.SendCommand(this.getCommandID("report"), report_params);
}

//moderation logic
void moderate(CRules@ this, CPlayer@ player)
{
	if(player !is null && player is getLocalPlayer())
	{
		if(isClient())
		{
			string p_name = player.getUsername();
			CCamera@ camera = getCamera();
			CMap@ map = getMap();

			//change to spectator cam
			player.client_ChangeTeam(this.getSpectatorTeamNum());
			getHUD().ClearMenus();
			camera.setPosition(Vec2f(map.getMapDimensions().x / 2, map.getMapDimensions().y / 2));

			//so the interface is drawn
			this.set_bool(p_name + "_moderator", true);
		}
	}
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	string p_name = player.getUsername();

	//remove moderator tag for people re-joining play
	if(oldteam == this.getSpectatorTeamNum())
	{
		if(this.get_bool(p_name + "_moderator"))
		{
			this.set_bool(p_name + "_moderator", false);
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
