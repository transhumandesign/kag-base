#include "AdminLogic.as"
#include "ChatCommand.as"

// time (in seconds) between repeated reports
const u32 reportRepeatTime = 1 * 60;

bool reportAllowed(CRules@ this, CPlayer@ player, CPlayer@ baddie)
{
	if (player is null || baddie is null) return false;

	string p_name = player.getUsername();
	string b_name = baddie.getUsername();

	// cannot report yourself
	if (baddie is player)
	{
		client_AddToChat(getTranslatedString("You cannot report yourself"), ConsoleColour::ERROR);
		return false;
	}

	// cannot report bots
	if (baddie.isBot())
	{
		client_AddToChat(getTranslatedString("You cannot report a bot"), ConsoleColour::ERROR);
		return false;
	}

	// hasn't reported in a while
	if (s32(s32(Time_Local()) - s32(this.get_u32(p_name + "_reported_at"))) <= reportRepeatTime)
	{
		client_AddToChat(getTranslatedString("You have already reported a player recently"), ConsoleColour::ERROR);
		return false;
	}

	return true;
}

void report(CRules@ this, CPlayer@ player, CPlayer@ baddie, string reason)
{
	string playerUsername = player.getUsername();
	string baddieUsername = baddie.getUsername();
	string servername = getNet().joined_servername;
	string serverip = getNet().joined_ip;

	// send report information to server
	CBitStream report_params;
	report_params.write_string(playerUsername);
	report_params.write_string(baddieUsername);
	report_params.write_string(servername);
	report_params.write_string(serverip);
	report_params.write_string(reason);
	this.SendCommand(this.getCommandID("report"), report_params);
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	string p_name = player.getUsername();

	// remove moderator tag for people re-joining play
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
	// search for exact matches
	for(int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if(p.getCharacterName() == name || p.getUsername() == name)
		{
			return p;
		}
	}

	// search for partial matches
	CPlayer@[] matches;
	for(int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if( // partial match on
			// char name
			p.getCharacterName().toLower().findFirst(name.toLower(), 0) >= 0
			// or username
			|| p.getUsername().toLower().findFirst(name.toLower(), 0) >= 0
		) {
			matches.push_back(p);
		}
	}

	// found any matches?
	if(matches.length() > 0)
	{
		// only one? great!
		if(matches.length() == 1)
		{
			return matches[0];
		}
		// otherwise ambiguous
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

class ModerateCommand : ChatCommand
{
	ModerateCommand()
	{
		super("moderate", "Toggle moderator mode");
		AddAlias("mod");
		AddAlias("m");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!player.isMyPlayer()) return;

		CRules@ rules = getRules();

		if (player.getTeamNum() == rules.getSpectatorTeamNum()) // is in spec team?
		{
			rules.set_bool(player.getUsername()+"_moderator", false);
			swapSpecTeam(rules, player, nonSpecTeam, true); // swap him back to his nonSpecTeam.
		}
		else
		{
			joinNewSpecTeam(rules, player); // create a spec/mod team even if it doesn't exist in the gamemode.
		}
	}
}

class ReportCommand : ChatCommand
{
	ReportCommand()
	{
		super("report", "Report a player");
		AddAlias("r");
		SetUsage("<player> [reason]");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!player.isMyPlayer()) return;

		CRules@ rules = getRules();

		if (args.size() == 0)
		{
			client_AddToChat(getTranslatedString("Specify a player to report"), ConsoleColour::ERROR);
			return;
		}

		string playerName = player.getUsername();
		string baddieName = args[0];
		args.removeAt(0);
		string reason = join(args, " ");

		CPlayer@ baddie = getReportedPlayer(baddieName);
		if (baddie is null)
		{
			client_AddToChat(getTranslatedString("Player '{PLAYER}' not found").replace("{PLAYER}", baddieName), ConsoleColour::ERROR);
			return;
		}

		baddieName = baddie.getUsername();

		if (reportAllowed(rules, player, baddie))
		{
			//if baddie exists, start more reporting logic
			report(rules, player, baddie, reason);
			client_AddToChat("You have reported " + baddie.getCharacterName() + " (" + baddieName + ")", ConsoleColour::INFO);
		}
	}
}
