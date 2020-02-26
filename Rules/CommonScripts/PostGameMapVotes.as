//-- Written by Monkey_Feats 22/2/2020 --//
#include "MapVotesCommon.as";

const int VoteSecs = 16;
const int PrePostVoteSecs = -4;
const u16 FadeTicks = 60; //2(secs)*30(ticks)
s16 fadeTimer;
const string vote_end_id = "mapvote: ended";
const string vote_selectmap_id = "mapvote: selectmap";
const string vote_random_names_id = "mapvote: random_names";
u8 current_Selected = 0;

void onInit( CRules@ this )
{
	onRestart(this);

	string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();	
	GUI::LoadFont("AveriaSerif-Bold_20", AveriaSerif, 20);

	this.addCommandID(vote_end_id);
	this.addCommandID(vote_selectmap_id);
	this.addCommandID(vote_random_names_id);

	MapVotesMenu mvm();
	this.set("MapVotesMenu", @mvm);

	int id = Render::addScript(Render::layer_posthud, "PostGameMapVotes.as", "RenderRaw", 0.0f);
}

void onRestart(CRules@ this)
{	
	MapVotesMenu@ mvm;
	if (this.get("MapVotesMenu", @mvm))
	mvm.isSetup = false;
	current_Selected = 0;
}

void onTick( CRules@ this )
{		
	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm)) return;
	if (!this.isGameOver()) return;
	if (!mvm.isSetup)
	{	
		RandomizeButtonNames(this);

		if (mvm.button1.filename != "" || mvm.button3.filename != "")
		{
			fadeTimer = PrePostVoteSecs*getTicksASecond(); // endgame time before fading
			mvm.VoteTimeLeft = VoteSecs;
			mvm.Refresh();
		}
		return;
	}

	if (fadeTimer < FadeTicks)
	{
		fadeTimer++;
		return;
	}
	else if (fadeTimer == FadeTicks)
	{
		CPlayer@ player;
		for (int i = 0; i < getPlayersCount(); i++)
		{
			@player = getPlayer(i);
			CBlob@ blob = player.getBlob();

			if (blob !is null)
			{
				blob.server_Die();				
				getHUD().SetDefaultCursor();
			}
		}
	}

	// Vote is now setup, faded to black and is counting down
	if (getGameTime() % getTicksASecond() == 0)
	mvm.VoteTimeLeft--;

	if (mvm.VotedCount1 > mvm.VotedCount2 && mvm.VotedCount1 > mvm.VotedCount3)
	{	//map 1 got the most votes
		mvm.MostVoted = 1;
	}
	else if (mvm.VotedCount3 > mvm.VotedCount1 && mvm.VotedCount3 > mvm.VotedCount2)
	{	//map 3 got the most votes
		mvm.MostVoted = 3;
	}
	else 
	{	//random map got the most votes or inconclusive
		mvm.MostVoted = 2;
	}

	CBitStream params;
	if (getNet().isServer() && mvm.VoteTimeLeft == PrePostVoteSecs) //timeup + some, load voted map
	{
		params.write_u8(mvm.MostVoted);
		this.SendCommand(this.getCommandID(vote_end_id), params);
	}

	//---------- CLIENT -----------\\
	CPlayer@ me = getLocalPlayer();
	if (!getNet().isClient()) return;

	CControls@ controls = getControls();
	if (controls is null) return;

	if (mvm.VoteTimeLeft <= 0 || mvm.VoteTimeLeft >= VoteSecs-1) return;

	u8 SelectedNum;	//default to zero, so command is sent only once
	mvm.Update(controls, SelectedNum);

	if (SelectedNum != 0)
	{
		u16 id = me.getNetworkID();
		params.write_u16(id);
		params.write_u8(SelectedNum);
		params.write_u8(current_Selected);
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
		u8 lastselected = params.read_u8();
		CPlayer@ player = getPlayerByNetworkId(id);	

		if (player !is null)
		{
			bool myPlayer = player.isMyPlayer();
			
			switch (selected)
			{
				case 0: break;
				case 1: mvm.VotedCount1++; break;
				case 2: mvm.VotedCount2++; break;
				case 3: mvm.VotedCount3++; break;
			}
			switch (lastselected)
			{
				case 0: break;
				case 1: mvm.VotedCount1--; break;
				case 2: mvm.VotedCount2--; break;
				case 3: mvm.VotedCount3--; break;
			}

			if (myPlayer) current_Selected = selected;
		}
	}	
	else if (cmd == this.getCommandID(vote_random_names_id))
	{		
		string m1fn = params.read_string();
		string m1sn = params.read_string();
		string m3fn = params.read_string();
		string m3sn = params.read_string();

		mvm.button1.filename = m1fn;
		mvm.button1.shortname = m1sn;
		mvm.button3.filename = m3fn;
		mvm.button3.shortname = m3sn;
	}
	else if (getNet().isServer() && cmd == this.getCommandID(vote_end_id))
	{		
		tcpr("(MapVotes) Map1: "+mvm.button1.shortname+" = "+mvm.VotedCount1+" Map2: "+mvm.button3.shortname+" = "+mvm.VotedCount3+" Random/Inconclusive = "+mvm.VotedCount2);

		u8 MostVoted = params.read_u8(); 
		switch (MostVoted)
		{
			case 1: LoadMap(mvm.button1.filename); break;
			case 3:	LoadMap(mvm.button3.filename); break;
			default: LoadNextMap(); break;
		}
	}
}

string map1name;
string map3name;

void RandomizeButtonNames(CRules@ this)
{
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
		string map1shortname = getFilenameWithoutExtension(getFilenameWithoutPath(map1name));
		string map3shortname = getFilenameWithoutExtension(getFilenameWithoutPath(map3name));

		CBitStream params;
		params.write_string(map1name);
		params.write_string(map1shortname);
		params.write_string(map3name);	
		params.write_string(map3shortname);
		this.SendCommand(this.getCommandID(vote_random_names_id), params);
	}	
}

void onRender(CRules@ this)
{	
	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm)) return;
	if (!this.isGameOver() || !mvm.isSetup) return;
	if (!getNet().isClient()) return;

	mvm.RenderGUI();
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
	mvm.RenderRaw();
}