void LoadMap()
{
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadPNGMap.as", "png");
	LoadRules("Rules/CTF/gamemode.cfg");
	sv_mapautocycle = false;
	sv_mapcycle_shuffle = false;
	LoadMapCycle("Rules/Tutorials/tutorial_ctf_maps.cfg");
	LoadNextMap();
	
	CRules@ r = getRules();
	if(r !is null)
	{
		r.AddScript("RestartAfterShortPostGame.as");
		r.RemoveScript("PostGameMapVotes.as");
	}
}
