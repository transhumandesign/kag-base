// Report.as
// report logic

#include "ReportCommon.as"

void onInit(CRules@ this)
{
	this.addCommandID("report");
	this.addCommandID("report client");

	ChatCommands::RegisterCommand(ModerateCommand());
	ChatCommands::RegisterCommand(ReportCommand());
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (this.getCommandID("report") == cmd && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		u16 id;
		if (!params.saferead_u16(id)) return;
		CPlayer@ baddie = getPlayerByNetworkId(id);
		if (baddie is null) return;

		string reason;
		if (!params.saferead_string(reason)) return;

		string b_name = baddie.getUsername();
		string p_name = player.getUsername();

		if (!reportAllowed(this, player, baddie)) return;

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
			"\" *SERVERNAME=\"" + sv_name + "\" *SERVERIP=\"" + getNet().sv_current_ip + "\" *REASON=\"" + reason + "\"");

			CBitStream bt;
			bt.write_u16(player.getNetworkID());
			bt.write_u16(baddie.getNetworkID());
			bt.write_string(reason);
			this.SendCommand(this.getCommandID("report client"), bt);
		}
	}
	else if (this.getCommandID("report client") == cmd && isClient())
	{
		u16 id;
		if (!params.saferead_u16(id)) return;
		CPlayer@ player = getPlayerByNetworkId(id);
		if (player is null) return;

		u16 b_id;
		if (!params.saferead_u16(b_id)) return;
		CPlayer@ baddie = getPlayerByNetworkId(b_id);
		if (baddie is null) return;

		string reason;
		if (!params.saferead_string(reason)) return;

		if (getLocalPlayer().isMod())
		{
			if(baddie !is null)
			{
				client_AddToChat(
					getTranslatedString("Report has been made for {PLAYER} by {REPORTER}" + ". Reason: {REASON}")
						.replace("{PLAYER}", baddie.getCharacterName() + " (" + baddie.getUsername() + ")")
						.replace("{REPORTER}", player.getUsername())
						.replace("{REASON}", reason),
				ConsoleColour::CRAZY);
				Sound::Play("ReportSound.ogg");
			}
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
