// Report.as
// report logic

#include "ReportCommon.as"

void onInit(CRules@ this)
{
	this.addCommandID("notify");
	this.addCommandID("report");
	this.addCommandID("mod_team");

	ChatCommands::RegisterCommand(ModerateCommand());
	ChatCommands::RegisterCommand(ReportCommand());
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	commandReceive(this, cmd, params);
	if (isClient() && this.getCommandID("report") == cmd)
	{
		string p_name = params.read_string();
		string b_name = params.read_string();
		string servername = params.read_string();
		string serverip = params.read_string();
		string reason = params.read_string();

		if (getLocalPlayer().isMod())
		{
			CPlayer@ baddie = getPlayerByUsername(b_name);

			if(baddie !is null)
			{
				client_AddToChat(
					getTranslatedString("Report has been made for {PLAYER}" + ". Reason: {REASON}")
						.replace("{PLAYER}", baddie.getCharacterName() + " (" + b_name + ")")
						.replace("{REASON}", reason),
				ConsoleColour::CRAZY);
				Sound::Play("ReportSound.ogg");
			}
		}
	}
	else if (isServer() && this.getCommandID("report") == cmd)
	{
		string p_name = params.read_string();
		string b_name = params.read_string();
		string servername = params.read_string();
		string serverip = params.read_string();
		string reason = params.read_string();

		CPlayer@ player = getPlayerByUsername(p_name);
		CPlayer@ baddie = getPlayerByUsername(b_name);

		// server gets info from client and decides if it will report baddie
		if(player !is baddie)
		{
			// initialise report_count if it's missing
			if(!this.exists(b_name + "_report_count"))
			{
				this.set_u8(b_name + "_report_count", 0);
			}

			// initialise reported timer if it's missing
			if(!this.exists(p_name + "_reported_at"))
			{
				this.set_u32(p_name + "_reported_at", 0);
			}

			// initialise x reported y if it's missing, this will forbid a plyer from reporting another player multiple times
			if(!this.exists(p_name + "_reported_" + b_name))
			{
				this.set_bool(p_name + "_reported_" + b_name, true);
			}

			// set time at which player reported baddie
			this.set_u32(p_name + "_reported_at", Time_Local());
			// increment baddie's report count
			this.add_u8(b_name + "_report_count", 1);

			// sync props to clients
			this.Sync(p_name + "_reported_at", true);
			this.Sync(b_name + "_report_count", true);
			this.Sync(p_name + "_reported_" + b_name, true);

			//*REPORT *PLAYER="SirSalami" *BADDIE="vik" *COUNT="1" *SERVER="arbitrary server name" *REASON="bullshit fuckery"

			tcpr("*REPORT *PLAYER=\"" + p_name + "\" *BADDIE=\"" + b_name + "\" *COUNT=\"" + this.get_u8(b_name + "_report_count") +
			"\" *SERVERNAME=\"" + servername + "\" *SERVERIP=\"" + serverip + "\" *REASON=\"" + reason + "\"");
		}
	}
}

// on new player join we must initialize the required variables
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
