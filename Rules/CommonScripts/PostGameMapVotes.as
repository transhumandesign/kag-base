//-- Written by Monkey_Feats 22/2/2020 --//
#include "MapVotesCommon.as";

void onInit(CRules@ rules)
{
	rules.addCommandID(voteRequestSelectMapTag);
	rules.addCommandID(voteRequestUnselectMapTag);
	rules.addCommandID(voteInfoSelectMapTag);
	rules.addCommandID(voteInfoUnselectMapTag);
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
	if (!isServer()) { return; }

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
	if (!isServer()) { return; }

	CBitStream params;
	u16 id = player.getNetworkID();
	params.write_u16(id);
	this.SendCommand(this.getCommandID(voteInfoUnselectMapTag), params);
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

	CBitStream params;
	if (isServer() && ticksRemainingBeforeRestart() <= 0)
	{
		// FIXME: this is not correct anymore! needed for kagstats, probably.
		// tcpr("(MapVotes) Map1: "+mvm.button1.shortname+" = "+mvm.votes1.length()+" Map2: "+mvm.button3.shortname+" = "+mvm.votes3.length()+" Random = "+mvm.votes2.length());
		mvm.getButton(mvm.mostVoted).loadMap();
		this.minimap = true;
	}

	//--------------------- CLIENT -----------------------\\
	if (isServer() && !isClient()) return; //not server, but also not localhost

	if (!isMapVoteActive() || isMapVoteOver()) return;

	CControls@ controls = getControls();
	if (controls is null) return;

	u8 newSelectedNum = 0;
	mvm.Update(controls, newSelectedNum);

	if (newSelectedNum != 0)
	{
		params.write_u8(newSelectedNum);
		this.SendCommand(this.getCommandID(voteRequestSelectMapTag), params);
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	MapVotesMenu@ mvm;
	if (!this.get("MapVotesMenu", @mvm)) return;

	if (cmd == this.getCommandID(voteRequestSelectMapTag))
	{
		if (!isServer()) { return; }

		CPlayer@ sender = getNet().getActiveCommandPlayer();
		if (sender is null) { return; }
		u16 id = sender.getNetworkID();

		u8 selected = params.read_u8();

		mvm.RemoveVotesFrom(id);
		if (selected < mvm.votes.size())
		{
			mvm.votes[selected].push_back(id);
		}

		CBitStream params;
		params.write_netid(id);
		params.write_u8(selected);
		this.SendCommand(this.getCommandID(voteInfoSelectMapTag), params);
	}
	else if (cmd == this.getCommandID(voteInfoSelectMapTag))
	{
		if (!isClient()) { return; }

		u16 id = params.read_netid();
		u8 selected = params.read_u8();

		mvm.RemoveVotesFrom(id);

		if (selected < mvm.votes.size())
		{
			mvm.votes[selected].push_back(id);
		}

		CPlayer@ player = getPlayerByNetworkId(id);
		if (isClient() && player !is null && player.isMyPlayer())
		{
			mvm.selectedOption = selected;
			Sound::Play("buttonclick.ogg");
		}
	}
	else if (cmd == this.getCommandID(voteRequestUnselectMapTag))
	{
		if (!isServer()) { return; }

		CPlayer@ sender = getNet().getActiveCommandPlayer();
		if (sender is null) { return; }
		u16 id = sender.getNetworkID();

		mvm.RemoveVotesFrom(id);
	}
	else if (cmd == this.getCommandID(voteInfoUnselectMapTag))
	{
		if (!isClient()) { return; }

		u16 id = params.read_u16();
		mvm.RemoveVotesFrom(id);
	}
	else if (isClient() && cmd == this.getCommandID(voteSyncTag))
	{
		mvm.ParseFromStream(params);

		for (uint i = 0; i < mvm.imageButtons.size(); ++i)
		{
			MapImageVoteButton@ button = @mvm.imageButtons[i];
			if (!Texture::exists(button.shortname))
			{
				CreateMapTexture(button.shortname, button.filename);
			}
		}

		mvm.ClearVotes();
	}
}

void RenderRaw(int id)
{
	if (!isMapVoteActive())
	{
		return;
	}

	MapVotesMenu@ mvm;
	if (!getRules().get("MapVotesMenu", @mvm)) return;
	if (!getRules().isGameOver() || !mvm.isSetup) return;
	if (!getNet().isClient()) return;
	if (!isMapVoteVisible()) return;

	CRules@ rules = getRules();
	rules.Untag("animateGameOver");

	Render::SetTransformScreenspace();
	Render::SetAlphaBlend(true);
	Render::SetBackfaceCull(true);
	Render::SetZBuffer(false, false);
	mvm.Render();
	
	getRules().minimap = false;
}
