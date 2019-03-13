//AdminLogic.as
/*
	-Reporting players.
	-Forcing spectator team for admins.
*/

u8 nonSpecTeam = 0; //Sandbox' default team.
const SColor reportMessageColor(255, 255, 0, 0);

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	//Forcing spectator team for admins.
    if(getNet().isServer() && this.getCommandID("mod_team") == cmd)
    {
	    string p_name = params.read_string();
	    bool on_spec = params.read_bool();
	    u8 previousTeam = params.read_u8();

	    CPlayer@ player = getPlayerByUsername(p_name);
	    if(on_spec) //player is alread in spec team.
	    {
		    player.server_setTeamNum(previousTeam);
		    this.server_PlayerDie(player); //force the player to join his old team.
		    this.set_bool(p_name + "_moderator", false);
	    }
	    else
	    {
		    CBlob@ corpse = player.getBlob();
		    player.server_setTeamNum(200); //get to new spec team.
		    if(corpse !is null) //in case someone 'kills' the corpse.
		    {
			    corpse.server_SetPlayer(null); //a body with no spirit is a useless corpse.
			    corpse.server_Die(); //destroy the corpse.
		    }
		    this.set_bool(p_name + "_moderator", true);
	    }
    }
    //Reporting.
    if (isClient() && this.getCommandID("report") == cmd)
    {
        if (getLocalPlayer().isMod())
        {
            string p_name = params.read_string();
            string b_name = params.read_string();

            CPlayer@ baddie = getPlayerByUsername(b_name);

            if(baddie !is null)
            {
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

void swapSpecTeam(CRules@ this, CPlayer@ player,u8 team, bool isPlayerOnSpec)
{
	string playerUsername = player.getUsername();

	CBitStream report_params;

	report_params.write_string(playerUsername);
	report_params.write_bool(isPlayerOnSpec);
	report_params.write_u8(team);

	this.SendCommand(this.getCommandID("mod_team"), report_params);
}

void joinNewSpecTeam(CRules@ this, CPlayer@ player)
{
	this.set_bool(player.getUsername() + "_moderator", true);
	nonSpecTeam = player.getTeamNum(); //note the admin previous team.
	swapSpecTeam(this, player, nonSpecTeam, false); //make him force-join spec team.
	CCamera@ camera = getCamera(); //camera and visuals.
	CMap@ map = getMap();
	getHUD().ClearMenus();
	camera.setPosition(Vec2f(map.getMapDimensions().x / 2, map.getMapDimensions().y / 2));
}
