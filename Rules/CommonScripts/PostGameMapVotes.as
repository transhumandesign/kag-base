//-- Written by Monkey_Feats 22/2/2020 --//
#include "MapVotesCommon.as";

void onInit(CRules@ rules)
{
	rules.addCommandID(voteEndTag);
	rules.addCommandID(voteSelectMapTag);
	rules.addCommandID(voteUnselectMapTag);
	rules.addCommandID(voteSyncTag);

	MapVotesMenu mvm();
	rules.set("MapVotesMenu", @mvm);

	if (!GUI::isFontLoaded("AveriaSerif-Bold_22"))
	{
		string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
		GUI::LoadFont("AveriaSerif-Bold_22", AveriaSerif, 22, true);
	}

	if (isClient())
	{
		Render::addScript(Render::layer_posthud, "PostGameMapVotes.as", "RenderRaw", 0.0f);
	}

	shouldCallOnRestart = true;
}

// HACK: if we call this directly within onInit we get a command error because initialization
//       has to finish before commands work the way you would expect.
//       as a workaround, we make it call on the first tick that occurs after onInit.
bool shouldCallOnRestart = false;

void onRestart(CRules@ rules)
{
	MapVotesMenu@ mvm;
	if (!rules.get("MapVotesMenu", @mvm))
	{
		warn("MapVotesMenu null in onRestart");
		return;
	}

	if (isServer())
	{
    	mvm.Randomize();
		mvm.Sync();
	}

	mvm.ClearVotes();
}

void onNewPlayerJoin(CRules@ rules, CPlayer@ player)
{
	MapVotesMenu@ mvm;
	if (!rules.get("MapVotesMenu", @mvm))
	{
		warn("MapVotesMenu null in onNewPlayerJoin");
		return;
	}

	mvm.Sync(@player);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	CBitStream params;
	u16 id = player.getNetworkID();
	params.write_u16(id);
	this.SendCommand(this.getCommandID(voteUnselectMapTag), params);
}

void onTick( CRules@ this )
{
	if (shouldCallOnRestart)
	{
		onRestart(this);
		shouldCallOnRestart = false;
	}

	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm))
	{
		warn("MapVotesMenu null in onTick");
		return;
	}

	if (!this.isGameOver())
	{
		this.set_s32(gameEndTimePointTag, getGameTime() + this.get_s32(gameRestartDelayTag));
		this.set_s32(gameOverTimeTag, getGameTime());
		return;
	}

	if (!mvm.isSetup)
	{
		mvm.Refresh();
		return;
	}

	u8 count1 = mvm.votes1.length();
	u8 count2 = mvm.votes2.length();
	u8 count3 = mvm.votes3.length();
	u8 count4 = mvm.votes4.length();

	if (count1 > count2 && count1 > count3 && count1 > count4)
	{	//map 1 got the most votes
		mvm.mostVoted = 1;
	}
	else if (count2 > count1 && count2 > count3 && count2 > count4)
	{	//map 2 got the most votes
		mvm.mostVoted = 2;
	}
	else if (count3 > count1 && count3 > count2 && count3 > count4)
	{	//map 3 got the most votes
		mvm.mostVoted = 3;
	}
	else if (count4 > count1 && count4 > count2 && count4 > count3)
	{	//map 4 got the most votes
		mvm.mostVoted = 4;
	}
	else
	{	//vote inconclusive

		// NOTE(hobey): take one of the maps that got the most votes, at random

		bool vote1_is_in_tie = false;
		bool vote2_is_in_tie = false;
		bool vote3_is_in_tie = false;
		bool vote4_is_in_tie = false;

		vote1_is_in_tie = true;
		u8 max_count = count1;

		if (count2 > max_count) {
			vote1_is_in_tie = false;
			vote2_is_in_tie = true;
			max_count = count2;
		} else if (count2 == max_count) {
			vote2_is_in_tie = true;
		}

		if (count3 > max_count) {
			vote1_is_in_tie = false;
			vote2_is_in_tie = false;
			vote3_is_in_tie = true;
			max_count = count3;
		} else if (count3 == max_count) {
			vote3_is_in_tie = true;
		}

		if (count4 > max_count) {
			vote1_is_in_tie = false;
			vote2_is_in_tie = false;
			vote3_is_in_tie = false;
			vote4_is_in_tie = true;
			max_count = count4;
		} else if (count4 == max_count) {
			vote4_is_in_tie = true;
		}

		int number_of_votes_that_got_tied = 0;
		if (vote1_is_in_tie) number_of_votes_that_got_tied += 1;
		if (vote2_is_in_tie) number_of_votes_that_got_tied += 1;
		if (vote3_is_in_tie) number_of_votes_that_got_tied += 1;
		if (vote4_is_in_tie) number_of_votes_that_got_tied += 1;

		int r = XORRandom(number_of_votes_that_got_tied);

		if (vote1_is_in_tie) {
			if (r == 0) {
				mvm.mostVoted = 1;
			}
			r -= 1;
		}
		if (vote2_is_in_tie) {
			if (r == 0) {
				mvm.mostVoted = 2;
			}
			r -= 1;
		}
		if (vote3_is_in_tie) {
			if (r == 0) {
				mvm.mostVoted = 3;
			}
			r -= 1;
		}
		if (vote4_is_in_tie) {
			if (r == 0) {
				mvm.mostVoted = 4;
			}
			r -= 1;
		}
	}

	if (isServer() && ticksRemainingBeforeRestart() <= 0)
	{
		CBitStream params;
		params.write_u8(mvm.mostVoted);
		this.SendCommand(this.getCommandID(voteEndTag), params);
	}

	//--------------------- CLIENT -----------------------\\
	if (isServer() && !isClient()) return; //not server, but also not localhost

	if (isMapVoteOver()) return;

	CControls@ controls = getControls();
	if (controls is null) return;

	u8 newSelectedNum = 0;
	mvm.Update(controls, newSelectedNum);

	if (newSelectedNum != 0)
	{
		CPlayer@ me = getLocalPlayer();
		u16 id = me.getNetworkID();

		CBitStream params;
		params.write_u16(id);
		params.write_u8(newSelectedNum);
		this.SendCommand(this.getCommandID(voteSelectMapTag), params);
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm)) return;

	if (cmd == this.getCommandID(voteSelectMapTag))
	{
		u16 id = params.read_u16();
		u8 selected = params.read_u8();

		int p1 = mvm.votes1.find(id);
		if (p1 != -1) mvm.votes1.removeAt(p1);
		int p2 = mvm.votes2.find(id);
		if (p2 != -1) mvm.votes2.removeAt(p2);
		int p3 = mvm.votes3.find(id);
		if (p3 != -1) mvm.votes3.removeAt(p3);
		int p4 = mvm.votes4.find(id);
		if (p4 != -1) mvm.votes4.removeAt(p4);

		switch (selected)
		{
			case 0: break;
			case 1: if (p1 == -1) mvm.votes1.push_back(id); break;
			case 2: if (p2 == -1) mvm.votes2.push_back(id); break;
			case 3: if (p3 == -1) mvm.votes3.push_back(id); break;
			case 4: if (p4 == -1) mvm.votes4.push_back(id); break;
		}

		CPlayer@ player = getPlayerByNetworkId(id);
		if (getNet().isClient() && player !is null && player.isMyPlayer())
		{
			mvm.selectedOption = selected;
			Sound::Play("buttonclick.ogg");
		}
	}
	else if (cmd == this.getCommandID(voteUnselectMapTag))
	{
		u16 id = params.read_u16();
		int p1 = mvm.votes1.find(id);
		if (p1 != -1) mvm.votes1.removeAt(p1);
		int p2 = mvm.votes2.find(id);
		if (p2 != -1) mvm.votes2.removeAt(p2);
		int p3 = mvm.votes3.find(id);
		if (p3 != -1) mvm.votes3.removeAt(p3);
		int p4 = mvm.votes4.find(id);
		if (p4 != -1) mvm.votes4.removeAt(p4);
	}
	else if (getNet().isClient() && cmd == this.getCommandID(voteSyncTag))
	{
		mvm.button1.filename = params.read_string();
		mvm.button2.filename = params.read_string();
		mvm.button3.filename = params.read_string();
		mvm.button4.filename = params.read_string();
		mvm.button1.shortname = params.read_string();
		mvm.button2.shortname = params.read_string();
		mvm.button3.shortname = params.read_string();
		mvm.button4.shortname = params.read_string();
		mvm.mostVoted = params.read_u8();

		u8 l1 = params.read_u8();
		u8 l2 = params.read_u8();
		u8 l3 = params.read_u8();
		u8 l4 = params.read_u8();

		for (uint i = 0; i < l1; i++)
		{
			mvm.votes1.push_back(params.read_u8());
		}

		for (uint i = 0; i < l2; i++)
		{
			mvm.votes2.push_back(params.read_u8());
		}

		for (uint i = 0; i < l3; i++)
		{
			mvm.votes3.push_back(params.read_u8());
		}

		for (uint i = 0; i < l4; i++)
		{
			mvm.votes4.push_back(params.read_u8());
		}

		if (!Texture::exists(mvm.button1.shortname))
		{
			CreateMapTexture(mvm.button1.shortname, mvm.button1.filename);
		}
		
		if (!Texture::exists(mvm.button2.shortname))
		{
			CreateMapTexture(mvm.button2.shortname, mvm.button2.filename);
		}
		
		if (!Texture::exists(mvm.button3.shortname))
		{
			CreateMapTexture(mvm.button3.shortname, mvm.button3.filename);
		}
		
		if (!Texture::exists(mvm.button4.shortname))
		{
			CreateMapTexture(mvm.button4.shortname, mvm.button4.filename);
		}

		mvm.ClearVotes();
	}
	else if (getNet().isServer() && cmd == this.getCommandID(voteEndTag))
	{
		// TODO(hobey): also tcpr the tie breaker result?
		tcpr("(MapVotes) Map1: "+mvm.button1.shortname+" = "+mvm.votes1.length()+" Map2: "+mvm.button2.shortname+" = "+mvm.votes2.length()+" Map3: "+mvm.button3.shortname+" = "+mvm.votes3.length()+" Map4: "+mvm.button4.shortname+" = "+mvm.votes4.length());

		u8 mostVoted = params.read_u8();
		switch (mostVoted)
		{
			case 1: LoadMap(mvm.button1.filename); break;
			case 2: LoadMap(mvm.button2.filename); break;
			case 3: LoadMap(mvm.button3.filename); break;
			case 4: LoadMap(mvm.button4.filename); break;
			default: LoadNextMap(); break;
		}
	}
}

void RenderRaw(int id)
{
	MapVotesMenu@ mvm;
	if (!getRules().get("MapVotesMenu", @mvm)) return;
	if (!getRules().isGameOver() || !mvm.isSetup) return;
	if (!getNet().isClient()) return;
	if (ticksSinceGameOver() < 5*getTicksASecond()) return;

	Render::SetTransformScreenspace();
	Render::SetAlphaBlend(true);
	Render::SetBackfaceCull(true);
	Render::SetZBuffer(false, false);
	mvm.Render();
}
