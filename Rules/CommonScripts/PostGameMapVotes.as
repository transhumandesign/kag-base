//-- Written by Monkey_Feats 22/2/2020 --//
#include "MapVotesCommon.as";

void onInit( CRules@ this )
{
	this.addCommandID(vote_end_id);
	this.addCommandID(vote_selectmap_id);
	this.addCommandID(vote_unselectmap_id);
	this.addCommandID(vote_sync_id);
	
	MapVotesMenu mvm();
	this.set("MapVotesMenu", @mvm);

	if (!GUI::isFontLoaded("AveriaSerif-Bold_22"))
	{		
		string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
		GUI::LoadFont("AveriaSerif-Bold_22", AveriaSerif, 22, true);
	}

	if (isServer())
	{
		_random.Reset(Time());
	}

	if (isClient())
	{
		Render::addScript(Render::layer_posthud, "PostGameMapVotes.as", "RenderRaw", 0.0f);
	}

	onRestart(this);
}

void onRestart(CRules@ rules)
{	
	MapVotesMenu@ mvm;
	if (!rules.get("MapVotesMenu", @mvm))
	{
		warn("MapVotesMenu null in onRestart");
	}

	if (isServer())
	{
    	randomizeMapOptions(@rules, mvm);
		syncVoteOptions(@rules);
	}

	mvm.ClearVotes();
}

void onNewPlayerJoin(CRules@ rules, CPlayer@ player)
{
	syncVoteOptions(@rules, @player);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{	
	CBitStream params;
	u16 id = player.getNetworkID();
	params.write_u16(id);
	this.SendCommand(this.getCommandID(vote_unselectmap_id), params);
}

void onTick( CRules@ this )
{
	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm))
	{
		warn("MapVotesMenu null in onTick");
		return;
	}

	if (!this.isGameOver())
	{
		this.set_s32(gameEndTimePointTag, getGameTime() + this.get_s32(gameRestartDelayTag));
		return;
	}

	if (!mvm.isSetup)
	{	
		mvm.Refresh();
		return;
	}

	u8 count1 = mvm.Votes1.length();
	u8 count2 = mvm.Votes2.length();
	u8 count3 = mvm.Votes3.length();

	if (count1 > count2 && count1 > count3)
	{	//map 1 got the most votes
		mvm.MostVoted = 1;
	}
	else if (count3 > count1 && count3 > count2)
	{	//map 3 got the most votes
		mvm.MostVoted = 3;
	}
	else 
	{	//random map got the most votes or inconclusive
		mvm.MostVoted = 2;
	}

	CBitStream params;
	if (isServer() && ticksRemainingBeforeRestart() <= 0)
	{
		params.write_u8(mvm.MostVoted);
		this.SendCommand(this.getCommandID(vote_end_id), params);
	}

	//--------------------- CLIENT -----------------------\\
	if (getNet().isServer() && !getNet().isClient()) return; //not server, but also not localhost

	if (isMapVoteOver()) return;

	CControls@ controls = getControls();
	if (controls is null) return;
	
	u8 NewSelectedNum = 0;
	mvm.Update(controls, NewSelectedNum);

	if (NewSelectedNum != 0)
	{
		CPlayer@ me = getLocalPlayer();
		u16 id = me.getNetworkID();
		params.write_u16(id);
		params.write_u8(NewSelectedNum);
		this.SendCommand(this.getCommandID(vote_selectmap_id), params);
	}	
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm)) return;
	
	if (cmd == this.getCommandID(vote_selectmap_id))
	{
		u16 id = params.read_u16();
		u8 selected = params.read_u8();

		int p1 = mvm.Votes1.find(id);
		if (p1 != -1) mvm.Votes1.removeAt(p1);
		int p2 = mvm.Votes2.find(id);
		if (p2 != -1) mvm.Votes2.removeAt(p2);
		int p3 = mvm.Votes3.find(id);
		if (p3 != -1) mvm.Votes3.removeAt(p3);		

		switch (selected)
		{
			case 0: break;
			case 1: if (p1 == -1) mvm.Votes1.push_back(id); break;
			case 2: if (p2 == -1) mvm.Votes2.push_back(id); break;
			case 3: if (p3 == -1) mvm.Votes3.push_back(id); break;
		}

		CPlayer@ player = getPlayerByNetworkId(id);
		if (getNet().isClient() && player.isMyPlayer()) 
		{
			current_Selected = selected;
			Sound::Play("buttonclick.ogg");
		}
	}	
	else if (cmd == this.getCommandID(vote_unselectmap_id))
	{
		u16 id = params.read_u16();
		int p1 = mvm.Votes1.find(id);
		if (p1 != -1) mvm.Votes1.removeAt(p1);
		int p2 = mvm.Votes2.find(id);
		if (p2 != -1) mvm.Votes2.removeAt(p2);
		int p3 = mvm.Votes3.find(id);
		if (p3 != -1) mvm.Votes3.removeAt(p3);
	}
	else if (getNet().isClient() && cmd == this.getCommandID(vote_sync_id))
	{	
		mvm.button1.filename = params.read_string();
		mvm.button3.filename = params.read_string();		
		mvm.button1.shortname = params.read_string();
		mvm.button3.shortname = params.read_string();
		mvm.MostVoted = params.read_u8();

		u8 l1 = params.read_u8();
		u8 l2 = params.read_u8();
		u8 l3 = params.read_u8();

		for (uint i = 0; i < l1; i++)
		{ 
			mvm.Votes1.push_back(params.read_u8()); 
		}
		
		for (uint i = 0; i < l2; i++)
		{
			mvm.Votes2.push_back(params.read_u8()); 
		}
		
		for (uint i = 0; i < l3; i++)
		{ 
			mvm.Votes3.push_back(params.read_u8());
		}
			
		if (!Texture::exists(mvm.button1.shortname))
		{
			CreateMapTexture(mvm.button1.shortname, mvm.button1.filename);
		}
		
		if (!Texture::exists(mvm.button3.shortname))
		{
			CreateMapTexture(mvm.button3.shortname, mvm.button3.filename);
		}

		mvm.ClearVotes();
	}
	else if (getNet().isServer() && cmd == this.getCommandID(vote_end_id))
	{		
		tcpr("(MapVotes) Map1: "+mvm.button1.shortname+" = "+mvm.Votes1.length()+" Map2: "+mvm.button3.shortname+" = "+mvm.Votes3.length()+" Random = "+mvm.Votes2.length());

		u8 MostVoted = params.read_u8(); 
		switch (MostVoted)
		{
			case 1: LoadMap(mvm.button1.filename); break;
			case 3:	LoadMap(mvm.button3.filename); break;
			default: LoadNextMap(); break;
		}
	}
}

void syncVoteOptions(CRules@ rules, CPlayer@ targetPlayer = null)
{
	MapVotesMenu@ mvm;
	if (!rules.get("MapVotesMenu", @mvm))
	{
		warn("MapVotesMenu null in syncVoteOptions");
		return;
	}

	CBitStream params;
	params.write_string(mvm.button1.filename);
	params.write_string(mvm.button3.filename);
	params.write_string(mvm.button1.shortname);
	params.write_string(mvm.button3.shortname);
	params.write_u8(mvm.MostVoted);

	params.write_u8(mvm.Votes1.length());
	params.write_u8(mvm.Votes2.length());
	params.write_u8(mvm.Votes3.length());

	for (uint i = 0; i < mvm.Votes1.length(); i++)
	{ params.write_u16(mvm.Votes1[i]); }
	for (uint i = 0; i < mvm.Votes2.length(); i++)
	{ params.write_u16(mvm.Votes2[i]); }
	for (uint i = 0; i < mvm.Votes3.length(); i++)
	{ params.write_u16(mvm.Votes3[i]); }

	if (targetPlayer is null)
	{
		// Send to everyone
		rules.SendCommand(rules.getCommandID(vote_sync_id), params);
	}
	else
	{
		rules.SendCommand(rules.getCommandID(vote_sync_id), params, @targetPlayer);
	}
}

void randomizeMapOptions(CRules@ this, MapVotesMenu@ mvm)
{	
	string map1name;
	string map3name;
	string mapcycle = sv_mapcycle;
	if (mapcycle == "")
	{
		string mode_name = sv_gamemode;
		if (mode_name == "Team Deathmatch") mode_name = "TDM";
		mapcycle =  "Rules/"+mode_name+"/mapcycle.cfg";
	}

	ConfigFile cfg;	
	bool loaded = false;
	if (CFileMatcher(mapcycle).getFirst() == mapcycle && cfg.loadFile(mapcycle)) loaded = true;
	else if (cfg.loadFile(mapcycle)) loaded = true;
	if (!loaded) { warn( mapcycle+ " not found!"); return; }

	string[] map_names;
	if (cfg.readIntoArray_string(map_names, "mapcycle"))
	{		
		const string currentMap = getMap().getMapName();	
		const int currentMapNum = map_names.find(currentMap);	

		int arrayleng = map_names.length();	
		if (arrayleng > 4)
		{
			//remove the current map first
			if (currentMapNum != -1)
				map_names.removeAt(currentMapNum);

			if (map1name != currentMap)
			{ 	// remove the old button 1
				const int oldMap1Num = map_names.find(map1name);
				if (oldMap1Num != -1)
					map_names.removeAt(oldMap1Num);
			}
			else if (map3name != currentMap) 
			{	// remove the old button 3
				const int oldMap3Num = map_names.find(map3name);
				if (oldMap3Num != -1)
					map_names.removeAt(oldMap3Num);
			}					
			
			// random based on what's left				
			map1name = map_names[_random.NextRanged(map_names.length())];
			map_names.removeAt(map_names.find(map1name));
			map3name = map_names[_random.NextRanged(map_names.length())];
		}
		else if (arrayleng >= 3)
		{
			//remove the current map
			if (currentMapNum != -1)
			map_names.removeAt(currentMapNum); 
			// random based on what's left
			map1name = map_names[_random.NextRanged(map_names.length())];
			map_names.removeAt(map_names.find(map1name));
			map3name = map_names[_random.NextRanged(map_names.length())];
		}
		else if (arrayleng == 2)
		{
			map1name = map_names[0];
			map3name = map_names[1];
		}
		else //if (arrayleng <= 1)
		{
			LoadNextMap(); // we don't care about voting, get me out
		}		

		//test to see if the map filename is inside parentheses and cut it out
		//incase someone wants to add map votes to a gamemode that loads maps via scripts, eg. Challenge/mapcycle.cfg				 
		string temptest = map1name.substr(map1name.length() - 1, map1name.length() - 1);
		if (temptest == ")")
		{
			string[] name = map1name.split(' (');
			string mapName = name[name.length() - 1];
			map1name = mapName.substr(0,mapName.length() - 1);
		}
		temptest = map3name.substr(map3name.length() - 1, map3name.length() - 1);
		if (temptest == ")")
		{
			string[] name = map1name.split(' (');
			string mapName = name[name.length() - 1];
			map3name = mapName.substr(0,mapName.length() - 1);
		}
	}	

	mvm.button1.filename = map1name;
	mvm.button3.filename = map3name;		
	mvm.button1.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(mvm.button1.filename));
	mvm.button3.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(mvm.button3.filename));
}

void RenderRaw(int id)
{	
	MapVotesMenu@ mvm;
	if (!getRules().get("MapVotesMenu", @mvm)) return;
	if (!getRules().isGameOver() || !mvm.isSetup) return;
	if (!getNet().isClient()) return;

	Render::SetTransformScreenspace();
	Render::SetAlphaBlend(true);
	Render::SetBackfaceCull(true);
	Render::SetZBuffer(false, false);
	mvm.Render();
}
