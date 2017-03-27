void LoadMap()
{
	print("-- LOADING SAVE THE PRINCESS SCRIPT --");
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadChallengePNG.as", "png");
	LoadRules("Rules/Challenge/gamemode.cfg");
	sv_mapautocycle = false;
	sv_mapcycle_shuffle = false;
	LoadMapCycle("Rules/Challenge/princess_maps.cfg");
	LoadNextMap();
}
