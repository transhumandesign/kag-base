void LoadMap()
{
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadChallengePNG.as", "png");
	LoadRules("Rules/Challenge/gamemode.cfg");
	sv_mapautocycle = true;
	sv_mapcycle_shuffle = false;
	LoadMapCycle("Rules/Tutorials/tutorial_maps.cfg");
	LoadNextMap();
}
