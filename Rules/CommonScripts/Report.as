void test(string message)
{
    print("Hi, " + message);
}

void report(CPlayer@ reportedPlayer, string reportedUsername, string reportedCharactername)
{
    print("Reporting " + reportedUsername);
    print("Reporting " + reportedPlayer.getUsername());
    print("Reporting " + reportedPlayer.getCharacterName());
    print("Reporting " + reportedPlayer.getTeamNum());
    print("Reporting " + reportedUsername);

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
