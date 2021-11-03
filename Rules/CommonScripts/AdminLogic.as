//AdminLogic.as
/*
	-Forcing spectator team for admins.
*/

u8 nonSpecTeam = 0;	//Sandbox' default team.

void commandReceive(CRules@ this, u8 cmd, CBitStream @params)
{
	//Forcing spectator team for admins.
	if(getNet().isServer() && this.getCommandID("mod_team") == cmd)
	{
		string p_name = params.read_string();
		bool on_spec = params.read_bool();
		u8 previousTeam = params.read_u8();

		CPlayer@ player = getPlayerByUsername(p_name);
		if(on_spec)	//player is alread in spec team.
		{
			player.server_setTeamNum(previousTeam);
			this.server_PlayerDie(player);	//force the player to join his old team.
		}
		else
		{
			CBlob@ corpse = player.getBlob();
			player.server_setTeamNum(this.getSpectatorTeamNum());	//get to new spec team.
			if(corpse !is null)	//in case someone 'kills' the corpse.
			{
				corpse.server_SetPlayer(null);	//a body with no spirit is a useless corpse.
				corpse.server_Die();	//destroy the corpse.
			}
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
	nonSpecTeam = player.getTeamNum();	//note the admin previous team.
	swapSpecTeam(this, player, nonSpecTeam, false);	//make him force-join spec team.
	if(player is getLocalPlayer())
	{
		CCamera@ camera = getCamera();	//camera and visuals.
		CMap@ map = getMap();
		getHUD().ClearMenus();
		camera.setPosition(Vec2f(map.getMapDimensions().x / 2, map.getMapDimensions().y / 2));
	}
}