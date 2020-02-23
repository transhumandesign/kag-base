//-- Written by Monkey_Feats 22/2/2020 --//
#include "MapVotesCommon.as";

const int VoteSecs = 16;
const u16 FadeTicks = 60; //2(secs)*30(ticks)
s16 fadeTimer;
const string vote_end_id = "mapvote: ended";
const string vote_selectmap_id = "mapvote: selectmap";
u8 current_Selected = 0;

void onInit( CRules@ this )
{
	onRestart(this);

	string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();	
	GUI::LoadFont("arial_20", AveriaSerif, 20);

	this.addCommandID(vote_end_id);
	this.addCommandID(vote_selectmap_id);

	MapVotesMenu mvm();
	this.set("MapVotesMenu", @mvm);

	int id = Render::addScript(Render::layer_posthud, "PostGameMapVotes.as", "RenderFunction", 0.0f);
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
		fadeTimer = -(4*30); // ticks of endgame time before fading
		mvm.VoteTimeLeft = VoteSecs;
		mvm.Refresh();

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
	if (getGameTime() % 30 == 0)
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
	if (getNet().isServer() && mvm.VoteTimeLeft == -4) //timeup + 4 secs, load voted map
	{
		params.write_u8(mvm.MostVoted);
		this.SendCommand(this.getCommandID(vote_end_id), params);
	}

	//---------- CLIENT -----------\\
	CPlayer@ me = getLocalPlayer();
	if (!getNet().isClient()) return;

	CControls@ controls = getControls();
	if (controls is null) return;

	if (mvm.VoteTimeLeft <= 0 || mvm.VoteTimeLeft >= VoteSecs || me.getTeamNum() == this.getSpectatorTeamNum()) return;

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
	else if (getNet().isServer() && cmd == this.getCommandID(vote_end_id))
	{		
		SaveVoteStats(this);

		PrintVoteStats(this);

		u8 MostVoted = params.read_u8(); 
		switch (MostVoted)
		{
			case 1: LoadMap(mvm.button1.filename); break;
			case 3:	LoadMap(mvm.button3.filename); break;
			default: LoadNextMap(); break;
		}
	}
}

void onRender(CRules@ this)
{
	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm)) return;
	if (!this.isGameOver() || !mvm.isSetup) return;

	mvm.RenderGUI();
}

void RenderFunction(int id)
{	
	MapVotesMenu@ mvm;
	if (!getRules().get("MapVotesMenu", @mvm)) return;
	if (!getRules().isGameOver() || !mvm.isSetup) return;

	Render::SetTransformScreenspace();
	Render::SetAlphaBlend(true);
	Render::SetBackfaceCull(true);
	mvm.RenderRaw();
}

void SaveVoteStats(CRules@ this)
{
	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm)) return;

	if (getNet().isServer())
	{
		string mode = this.gamemode_name;
		string statsFile = "Stats_"+mode+"_MapVotes""/"+mode+"_mapvote_stats.cfg";
		ConfigFile stats;

		if (stats.loadFile("../Cache/" + statsFile))
		{
			const u32 b1votes = stats.exists(mvm.button1.shortname) ? stats.read_u32(mvm.button1.shortname) : 0;
			const u32 b2votes = stats.exists("Random_Map") ? stats.read_u32("Random_Map") : 0;
			const u32 b3votes = stats.exists(mvm.button3.shortname) ? stats.read_u32(mvm.button3.shortname) : 0;
			
			stats.add_u32(mvm.button1.shortname, b1votes+mvm.VotedCount1);
			stats.add_u32("Random_Map", b2votes+mvm.VotedCount2);
			stats.add_u32(mvm.button3.shortname, b3votes+mvm.VotedCount3);

			stats.saveFile(statsFile);
		}
	}
}

void PrintVoteStats(CRules@ this)
{
	if (getNet().isServer())
	{
		ConfigFile stats;
		string mode = this.gamemode_name;
		string statsFile = "Stats_"+mode+"_MapVotes""/"+mode+"_mapvote_stats.cfg";

		if (mode == "Team Deathmatch") mode = "TDM";
		string mapcycle =  "Rules/"+mode+"/mapcycle.cfg";

		ConfigFile cfg;	
		bool loaded = false;
		if (CFileMatcher(mapcycle).getFirst() == mapcycle && cfg.loadFile(mapcycle)) loaded = true;
		else if (cfg.loadFile(mapcycle)) loaded = true;
		if (!loaded) { warn( mapcycle+ " not found!"); return; }

		string[] map_names;
		if (cfg.readIntoArray_string(map_names, "mapcycle"))
		{
			if (stats.loadFile("../Cache/" + statsFile))
			{
				for (uint i = 0; i < map_names.length(); i++)
				{
					string filename = map_names[i];				
					string shortname = getFilenameWithoutExtension(getFilenameWithoutPath(filename));

					if (stats.exists(shortname))
					printf(""+shortname +" = " +stats.read_u32(shortname));
				}	
				if (stats.exists("Random_Map"))
				printf("Random_Map = " +stats.read_u32("Random_Map"));
			}
		}
	}
}
