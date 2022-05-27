const string[] excludedFromTeamCheck = {"seed", "food", "fishy", "chicken", "shark", "bison", "greg", "log", "boulder", "tree_pine", "tree_bushy", "bush"};

bool blobLimitExceeded(string blobName, CBlob@ caller = null) // returns true if exceeding the limit, false otherwise
{	
	string itemName = blobName;
	if (blobName == "filled_bucket") itemName = "bucket";

	CBlob@[] blobsInMap;
	getBlobsByName(itemName, @blobsInMap);
	int blobCounts = 0;

	int callerTeam = (caller is null) ? 8 : caller.getTeamNum();  
	if ( callerTeam < 0 || callerTeam > 8 ) callerTeam = 8;
	
	ConfigFile cfg = ConfigFile();
	cfg.loadFile("Rules/CommonScripts/ItemLimits.cfg");
	s32 maximum = cfg.read_s32( itemName, 200 );

	if ( maximum > 0 )
	{
		for (uint b = 0; b < blobsInMap.length(); ++b)
		{	
			int blobTeam = blobsInMap[b].getTeamNum();
			if ( blobTeam < 0 || blobTeam > 7 ) blobTeam = 8;
			if ( callerTeam == blobTeam || excludedFromTeamCheck.find(itemName) != -1 ) blobCounts++;
		}

		if ( blobCounts >= maximum ) 
		{	
			chatWarningItemLimit(maximum, itemName);
			return true;
		}
	}
	return false;
}

void chatWarningItemLimit(int maximum, string item)
{
	// send warning to chat
	CBitStream params;
	CPlayer@ player = getLocalPlayer();
	CRules@ rules = getRules();
	string appendix;
	
	if (excludedFromTeamCheck.find( item ) == -1) appendix = "per team";
		
	params.write_string("Can't create more than " + maximum + " " + item + "s " + appendix + ".");

	// List is reverse so we can read it correctly into SColor when reading
	SColor errorColor = SColor(255,255,100,0);
	params.write_u8(errorColor.getBlue());
	params.write_u8(errorColor.getGreen());
	params.write_u8(errorColor.getRed());
	params.write_u8(errorColor.getAlpha());

	rules.SendCommand(rules.getCommandID("SendChatMessage"), params, player);
}
