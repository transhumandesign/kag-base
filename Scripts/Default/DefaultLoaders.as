
void LoadDefaultMapLoaders()
{
	printf("############ GAMEMODE " + sv_gamemode);
	if (sv_gamemode == "TTH" || sv_gamemode == "WAR" ||
	        sv_gamemode == "tth" || sv_gamemode == "war")
	{
		RegisterFileExtensionScript("Scripts/MapLoaders/LoadWarPNG.as", "png");
	}
	else if (sv_gamemode == "Challenge" || sv_gamemode == "challenge")
	{
		RegisterFileExtensionScript("Scripts/MapLoaders/LoadChallengePNG.as", "png");
	}
	else if (sv_gamemode == "TDM" || sv_gamemode == "tdm")
	{
		RegisterFileExtensionScript("Scripts/MapLoaders/LoadTDMPNG.as", "png");
	}
	else
	{
		RegisterFileExtensionScript("Scripts/MapLoaders/LoadPNGMap.as", "png");
	}


	RegisterFileExtensionScript("Scripts/MapLoaders/GenerateFromKAGGen.as", "kaggen.cfg");
}
