// report logic
// wip

#include "PlayerCamera.as"

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if((text_in == "!moderate" || text_in == "!m") && player.isMod())
	{

		int specTeam = getRules().getSpectatorTeamNum();
		CBlob@ blob = player.getBlob();
		blob.server_SetPlayer(null);
		blob.server_Die();
		player.client_ChangeTeam(specTeam);
		
		return false; //false so it doesn't show as normal chat
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
			if ((tokens[0] == "!report" || tokens[0] == "!r") && !security.isPlayerIgnored(player))
			{
				//check if reported player exists
				string reportedUsername = tokens[1];
				string reportedCharacterName = reportedUsername;
				CPlayer@ reportedPlayer = getPlayerByUsername(reportedUsername);

				if(reportedPlayer !is null)
				{
					//if he exists start more reporting logic
					report(reportedPlayer, reportedUsername, reportedCharacterName);
				}
				else {
					print("not found");
				}

				return false; //false so it doesn't show as normal chat
			}
			else if(tokens[0] == "!moderate" || tokens[0] == "!m")
			{
				string targetUsername = tokens[1];
				string targetCharacterName = targetUsername;
				CPlayer@ targetPlayer = getPlayerByUsername(targetUsername);

				if(targetPlayer !is null)
				{
					moderate(player, targetPlayer, targetUsername, targetCharacterName);
				}
				
				return false; //false so it doesn't show as normal chat
			}
		}
	}

	return false;
}

void report(CPlayer@ reportedPlayer, string reportedUsername, string reportedCharactername)
{
    print("Reporting " + reportedUsername);
    print("Reporting " + reportedPlayer.getUsername());
    print("Reporting " + reportedPlayer.getCharacterName());
    print("Reporting " + reportedPlayer.getTeamNum());
    print("Reporting " + reportedUsername);

	//tag player as reported
	reportedPlayer.Tag("reported");

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
			client_AddToChat("Report has been made of: " + reportedUsername, SColor(255, 255, 0, 0));
			Sound::Play("/ReportSound.ogg");
		}
	}
}

void moderate(CPlayer@ moderator, CPlayer@ targetPlayer, string targetUsername, string targetCharactername)
{
	int specTeam = getRules().getSpectatorTeamNum();
	CBlob@ blob = moderator.getBlob();
	blob.server_SetPlayer(null);
	blob.server_Die();
	moderator.client_ChangeTeam(specTeam);

	onModerate(getRules(), moderator, targetPlayer);
}
