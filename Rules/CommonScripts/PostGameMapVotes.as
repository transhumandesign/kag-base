//-- Written by Monkey_Feats 22/2/2020 --//
#include "MapVotesCommon.as";

const int VoteSecs = 16;
const int PrePostVoteSecs = -4;
const u16 FadeTicks = 60; //2(secs)*30(ticks)
s16 fadeTimer;
const string vote_end_id = "mapvote: ended";
const string vote_selectmap_id = "mapvote: selectmap";
u8 current_Selected = 0;

void onInit( CRules@ this )
{
	onRestart(this);

	string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();	
	GUI::LoadFont("AveriaSerif-Bold_20", AveriaSerif, 20);

	this.addCommandID(vote_end_id);
	this.addCommandID(vote_selectmap_id);

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
		fadeTimer = PrePostVoteSecs*getTicksASecond(); // endgame time before fading
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

void onRender(CRules@ this)
{
	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm)) return;
	if (!this.isGameOver() || !mvm.isSetup) return;

	mvm.RenderGUI();
}

void RenderRaw(int id)
{	
	MapVotesMenu@ mvm;
	if (!getRules().get("MapVotesMenu", @mvm)) return;
	if (!getRules().isGameOver() || !mvm.isSetup) return;

	Render::SetTransformScreenspace();
	Render::SetAlphaBlend(true);
	Render::SetBackfaceCull(true);
	mvm.RenderRaw();
}