void LoadMap()
{
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadWarPNG.as", "png");
	LoadRules("Rules/WAR/gamemode.cfg");
	sv_mapautocycle = false;
	sv_mapcycle_shuffle = false;
	LoadMapCycle("Rules/Tutorials/tutorial_tth_maps.cfg");
	LoadNextMap();
	
	CRules@ r = getRules();
	if(r !is null)
	{
		r.set_bool("tutorial",true);
		r.AddScript("RestartAfterShortPostGame.as");
		r.RemoveScript("PostGameMapVotes.as");
	}
}
