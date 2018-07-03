void test(string message)
{
    print("Hi, " + message);
}

void report(CPlayer@ reportedPlayer, string reportedName)
{
    print("Reporting " + reportedName);
    print("Reporting " + reportedPlayer.getUsername());
    print("Reporting " + reportedPlayer.getCharacterName());
    print("Reporting " + reportedPlayer.getTeamNum());
    print("Reporting " + reportedName);

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
		client_AddToChat("Report has been made of: " + reportedName, SColor(255, 255, 0, 0));
	}
}
