//admin backend stuff

//admin join


//admin leave

//admin ban

void SendAdminBan(string username, string offence)
{
	CBitStream params;
	params.write_string(username);
	params.write_string(offence);
	sendAdminCommand(getLocalPlayer(), "ban", params);
}

void RecvAdminBan(CPlayer@ admin, string username, string offence)
{

}

//admin

//admin interface


//security check
bool canAccessAdminMenu(CPlayer@ p)
{
	return getSecurity().checkAccess_Feature(player, "admin_color");
}

//commands from interface
const int ADMIN_GUI_CMD = 70;

void sendAdminCommand(CPlayer@ admin, string cmd, CBitStream params)
{
	CBitStream p;
	p.write_u16(admin.getNetworkID());
	p.write_string(cmd);
	p.write_CBitStream(params);
	getRules().SendCommand(ADMIN_GUI_CMD, p);
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	if(cmd == ADMIN_GUI_CMD)
	{
		u16 netid; //todo: get this from somewhere more reliable :)
		string cmd;
		CBitStream cmd_params;
		if(!params.saferead_u16(netid)) return;
		if(!params.saferead_string(cmd)) return;
		if(!params.saferead_CBitStream(cmd_params)) return;

		CPlayer@ admin = getPlayerByNetworkID(netid);

		if(admin is null) return;
		if(!canAccessAdminMenu(admin)) return;

		if(cmd == "ban")
		{
			string username;
			string offence;
			if(!cmd_params.saferead_string(username)) return;
			if(!cmd_params.saferead_string(offence)) return;

			RecvAdminBan(admin, username, offence);
		}
	}
}
