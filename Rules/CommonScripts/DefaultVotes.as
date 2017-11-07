//implements 2 default vote types (kick and next map) and menus for them

#include "VoteCommon.as"

bool g_haveStartedVote = false;
s32 g_lastVoteCounter = 0;
string g_lastUsernameVoted = "";
const float required_minutes = 10; //time you have to wait after joining w/o skip_votewait.

s32 g_lastNextmapCounter = 0;
const float required_minutes_nextmap = 10; //global nextmap vote cooldown

const s32 VoteKickTime = 30; //minutes (30min default)

//kicking related globals and enums
enum kick_reason
{
	kick_reason_griefer = 0,
	kick_reason_hacker,
	kick_reason_teamkiller,
	kick_reason_spammer,
	kick_reason_afk,
	kick_reason_count,
};
string[] kick_reason_string = { "Griefer", "Hacker", "Teamkiller", "Spammer", "AFK" };

string g_kick_reason = kick_reason_string[kick_reason_griefer]; //default

//next map related globals and enums
enum nextmap_reason
{
	nextmap_reason_ruined = 0,
	nextmap_reason_stalemate,
	nextmap_reason_bugged,
	nextmap_reason_count,
};

string[] nextmap_reason_string = { "Map Ruined", "Stalemate", "Game Bugged" };

//votekick and vote nextmap

const string votekick_id = "vote: kick";
const string votenextmap_id = "vote: nextmap";
const string votesurrender_id = "vote: surrender";

//set up the ids
void onInit(CRules@ this)
{
	this.addCommandID(votekick_id);
	this.addCommandID(votenextmap_id);
	this.addCommandID(votesurrender_id);
}


void onRestart(CRules@ this)
{
	g_lastNextmapCounter = 60 * getTicksASecond() * required_minutes_nextmap;
}

void onTick(CRules@ this)
{
	if (g_lastVoteCounter < 60 * getTicksASecond()*required_minutes)
		g_lastVoteCounter++;
	if (g_lastNextmapCounter < 60 * getTicksASecond()*required_minutes_nextmap)
		g_lastNextmapCounter++;
}

//VOTE KICK --------------------------------------------------------------------
//votekick functors

class VoteKickFunctor : VoteFunctor
{
	VoteKickFunctor() {} //dont use this
	VoteKickFunctor(CPlayer@ _kickplayer)
	{
		@kickplayer = _kickplayer;
	}

	CPlayer@ kickplayer;

	void Pass(bool outcome)
	{
		if (kickplayer !is null && outcome)
		{
			client_AddToChat("Votekick passed! " + kickplayer.getUsername() + " will be kicked out.", vote_message_colour());

			if (getNet().isServer())
				getSecurity().ban(kickplayer, VoteKickTime, "Voted off"); //30 minutes ban
		}
	}
};

class VoteKickCheckFunctor : VoteCheckFunctor
{
	VoteKickCheckFunctor() {}//dont use this
	VoteKickCheckFunctor(CPlayer@ _kickplayer, string _reason)
	{
		@kickplayer = _kickplayer;
		reason = _reason;
	}

	CPlayer@ kickplayer;
	string reason;

	bool PlayerCanVote(CPlayer@ player)
	{
		if (!getSecurity().checkAccess_Feature(player, "mark_player")) return false;

		if (reason.find(kick_reason_string[kick_reason_griefer]) != -1 || //reason contains "Griefer"
		        reason.find(kick_reason_string[kick_reason_teamkiller]) != -1 || //or TKer
		        reason.find(kick_reason_string[kick_reason_afk]) != -1) //or AFK
		{
			return (player.getTeamNum() == kickplayer.getTeamNum() || //must be same team
			        kickplayer.getTeamNum() == getRules().getSpectatorTeamNum() || //or they're spectator
			        getSecurity().checkAccess_Feature(player, "mark_any_team"));   //or has mark_any_team
		}

		return true; //spammer, hacker (custom?)
	}
};

class VoteKickLeaveFunctor : VotePlayerLeaveFunctor
{
	VoteKickLeaveFunctor() {} //dont use this
	VoteKickLeaveFunctor(CPlayer@ _kickplayer)
	{
		@kickplayer = _kickplayer;
	}

	CPlayer@ kickplayer;

	//avoid dangling reference to player
	void PlayerLeft(VoteObject@ vote, CPlayer@ player)
	{
		if (player is kickplayer)
		{
			client_AddToChat(player.getUsername() + " left early, acting as if they were kicked.", vote_message_colour());
			if (getNet().isServer())
			{
				getSecurity().ban(player, VoteKickTime, "Ran from vote");
			}

			CancelVote(vote);
		}
	}
};

//setting up a votekick object
VoteObject@ Create_Votekick(CPlayer@ player, CPlayer@ byplayer, string reason)
{
	VoteObject vote;

	@vote.onvotepassed = VoteKickFunctor(player);
	@vote.canvote = VoteKickCheckFunctor(player, reason);
	@vote.playerleave = VoteKickLeaveFunctor(player);

	vote.title = "Kick " + player.getUsername() + "?";
	vote.reason = reason;
	vote.byuser = byplayer.getUsername();
	vote.forcePassFeature = "ban";
	vote.cancel_on_restart = false;

	CalculateVoteThresholds(vote);

	return vote;
}

//VOTE NEXT MAP ----------------------------------------------------------------
//nextmap functors

class VoteNextmapFunctor : VoteFunctor
{
	VoteNextmapFunctor() {} //dont use this
	VoteNextmapFunctor(CPlayer@ player)
	{
		string charname = player.getCharacterName();
		string username = player.getUsername();
		//name differs?
		if (charname != username &&
		        charname != player.getClantag() + username &&
		        charname != player.getClantag() + " " + username)
		{
			playername = charname + " (" + player.getUsername() + ")";
		}
		else
		{
			playername = charname;
		}
	}

	string playername;
	void Pass(bool outcome)
	{
		if (outcome)
		{
			if (getNet().isServer())
			{
				LoadNextMap();
			}
		}
		else
		{
			client_AddToChat(playername + " needs to take a spoonful of cement! Play on!", vote_message_colour());
		}
	}
};

class VoteNextmapCheckFunctor : VoteCheckFunctor
{
	VoteNextmapCheckFunctor() {}

	bool PlayerCanVote(CPlayer@ player)
	{
		return getSecurity().checkAccess_Feature(player, "map_vote");
	}
};

//setting up a vote next map object
VoteObject@ Create_VoteNextmap(CPlayer@ byplayer, string reason)
{
	VoteObject vote;

	@vote.onvotepassed = VoteNextmapFunctor(byplayer);
	@vote.canvote = VoteNextmapCheckFunctor();

	vote.title = "Skip to next map?";
	vote.reason = reason;
	vote.byuser = byplayer.getUsername();
	vote.forcePassFeature = "nextmap";
	vote.cancel_on_restart = true;

	CalculateVoteThresholds(vote);

	return vote;
}

//VOTE SURRENDER ----------------------------------------------------------------
//surrender functors

class VoteSurrenderFunctor : VoteFunctor
{
	VoteSurrenderFunctor() {} //dont use this
	VoteSurrenderFunctor(CPlayer@ player)
	{
		team = player.getTeamNum();

		string charname = player.getCharacterName();
		string username = player.getUsername();
		//name differs?
		if (charname != username &&
		        charname != player.getClantag() + username &&
		        charname != player.getClantag() + " " + username)
		{
			playername = charname + " (" + player.getUsername() + ")";
		}
		else
		{
			playername = charname;
		}
	}

	string playername;
	s32 team;
	void Pass(bool outcome)
	{
		if (outcome)
		{
			if (getNet().isServer())
			{
				CRules@ rules = getRules();
				s32 teamWonNum = (team + 1) % rules.getTeamsCount();
				CTeam@ teamLost = rules.getTeam(team);
				CTeam@ teamWon = rules.getTeam(teamWonNum);

				rules.SetTeamWon(teamWonNum);
				rules.SetCurrentState(GAME_OVER);

				rules.SetGlobalMessage("{LOSING_TEAM} Surrendered! {WINNING_TEAM} wins the Game!");
				rules.AddGlobalMessageReplacement("LOSING_TEAM", teamLost.getName());
				rules.AddGlobalMessageReplacement("WINNING_TEAM", teamWon.getName());
			}
		}
		else
		{
			client_AddToChat(playername + " needs to take a spoonful of cement! Play on!", vote_message_colour());
		}
	}
};

class VoteSurrenderCheckFunctor : VoteCheckFunctor
{
	VoteSurrenderCheckFunctor() {}//dont use this
	VoteSurrenderCheckFunctor(s32 _team)
	{
		team = _team;
	}

	s32 team;

	bool PlayerCanVote(CPlayer@ player)
	{
		//todo: seclevs? how would they look?

		return player.getTeamNum() == team;
	}
};

//setting up a vote surrender object
VoteObject@ Create_VoteSurrender(CPlayer@ byplayer)
{
	VoteObject vote;

	@vote.onvotepassed = VoteSurrenderFunctor(byplayer);
	@vote.canvote = VoteSurrenderCheckFunctor(byplayer.getTeamNum());

	vote.title = "Surrender to the enemy?";
	vote.reason = "";
	vote.byuser = byplayer.getUsername();
	vote.forcePassFeature = "surrender";
	vote.cancel_on_restart = true;

	CalculateVoteThresholds(vote);

	return vote;
}

//create menus for kick and nextmap

void onMainMenuCreated(CRules@ this, CContextMenu@ menu)
{
	//get our player first - if there isn't one, move on
	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	CRules@ rules = getRules();

	if (Rules_AlreadyHasVote(rules))
	{
		Menu::addContextItem(menu, "(Vote already in progress)", "DefaultVotes.as", "void CloseMenu()");
		Menu::addSeparator(menu);

		return;
	}

	//and advance context menu when clicked
	CContextMenu@ votemenu = Menu::addContextMenu(menu, "Start a Vote");
	Menu::addSeparator(menu);

	//vote options menu

	CContextMenu@ kickmenu = Menu::addContextMenu(votemenu, "Kick");
	CContextMenu@ mapmenu = Menu::addContextMenu(votemenu, "Next Map");
	CContextMenu@ surrendermenu = Menu::addContextMenu(votemenu, "Surrender");
	Menu::addSeparator(votemenu); //before the back button

	bool can_skip_wait = getSecurity().checkAccess_Feature(me, "skip_votewait");

	//kick menu
	if (getSecurity().checkAccess_Feature(me, "mark_player"))
	{
		if (g_lastVoteCounter < 60 * getTicksASecond()*required_minutes
		        && (!can_skip_wait || g_haveStartedVote))
		{
			Menu::addInfoBox(kickmenu, "Can't Start Vote", "Voting requires a " + required_minutes + " min wait\n" +
			                 "after each started vote to\n" +
			                 "prevent spamming/abuse.\n");
		}
		else
		{
			Menu::addInfoBox(kickmenu, "Vote Kick", "Vote to kick a player on your team\nout of the game.\n\n" +
			                 "- use responsibly\n" +
			                 "- report any abuse of this feature.\n" +
			                 "\nTo Use:\n\n" +
			                 "- select a reason from the\n     list (default is griefing).\n" +
			                 "- select a name from the list.\n" +
			                 "- everyone votes.\n");

			Menu::addSeparator(kickmenu);

			//reasons
			for (uint i = 0 ; i < kick_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				Menu::addContextItemWithParams(kickmenu, kick_reason_string[i], "DefaultVotes.as", "Callback_KickReason", params);
			}

			Menu::addSeparator(kickmenu);

			//write all players on our team
			bool added = false;
			for (int i = 0; i < getPlayersCount(); ++i)
			{
				CPlayer@ player = getPlayer(i);

				//if(player is me) continue; //don't display ourself for kicking
				//commented out for max lols

				int player_team = player.getTeamNum();
				if ((player_team == me.getTeamNum() || player_team == this.getSpectatorTeamNum()
				        || getSecurity().checkAccess_Feature(me, "mark_any_team"))
				        && (!getSecurity().checkAccess_Feature(player, "kick_immunity")))
				{
					string descriptor = player.getCharacterName();

					if (player.getUsername() != player.getCharacterName())
						descriptor += " (" + player.getUsername() + ")";

					if(g_lastUsernameVoted == player.getUsername())
					{
						//no-abuse box
						Menu::addInfoBox(
							kickmenu,
							"Cannot kick " + descriptor,
							"You started a vote for\nthis person last time.\n\nSomeone else must start the vote."
						);
					}
					else
					{
						CContextMenu@ usermenu = Menu::addContextMenu(kickmenu, "Kick " + descriptor);
						Menu::addInfoBox(usermenu, "Kicking " + descriptor, "Make sure you're voting to kick\nthe person you meant.\n");
						Menu::addSeparator(usermenu);

						CBitStream params;
						params.write_u16(player.getNetworkID());

						Menu::addContextItemWithParams(usermenu, "Yes, I'm sure", "DefaultVotes.as", "Callback_Kick", params);
						added = true;

						Menu::addSeparator(usermenu);
					}
				}
			}

			if (!added)
			{
				Menu::addContextItem(kickmenu, "(No-one available)", "DefaultVotes.as", "void CloseMenu()");
			}
		}
	}
	else
	{
		Menu::addInfoBox(kickmenu, "Can't vote", "You cannot vote to kick\n" +
		                 "players on this server\n");
	}
	Menu::addSeparator(kickmenu);

	//nextmap menu
	if (getSecurity().checkAccess_Feature(me, "map_vote"))
	{
		if (g_lastNextmapCounter < 60 * getTicksASecond()*required_minutes_nextmap
		        && (!can_skip_wait || g_haveStartedVote))
		{
			Menu::addInfoBox(mapmenu, "Can't Start Vote", "Voting for next map\n" +
			                 "requires a " + required_minutes_nextmap + " min wait\n" +
			                 "after each started vote\n" +
			                 "to prevent spamming.\n");
		}
		else
		{
			Menu::addInfoBox(mapmenu, "Vote Next Map", "Vote to change the map\nto the next in cycle.\n\n" +
			                 "- report any abuse of this feature.\n" +
			                 "\nTo Use:\n\n" +
			                 "- select a reason from the list.\n" +
			                 "- everyone votes.\n");

			Menu::addSeparator(mapmenu);
			//reasons
			for (uint i = 0 ; i < nextmap_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				Menu::addContextItemWithParams(mapmenu, nextmap_reason_string[i], "DefaultVotes.as", "Callback_NextMap", params);
			}
		}
	}
	else
	{
		Menu::addInfoBox(mapmenu, "Can't vote", "You cannot vote to change\n" +
		                 "the map on this server\n");
	}
	Menu::addSeparator(mapmenu);

	//surrender menu
	//(shares nextmap counter to prevent nextmap/surrender spam)
	if (!this.isMatchRunning() && !can_skip_wait)
	{
		Menu::addInfoBox(surrendermenu, "Can't Start Vote", "Voting for surrender\n" +
		                 "is not allowed before the game starts.\n");
	}
	else if (g_lastNextmapCounter < 60 * getTicksASecond()*required_minutes_nextmap
	         && (!can_skip_wait || g_haveStartedVote))
	{
		Menu::addInfoBox(surrendermenu, "Can't Start Vote", "Voting for surrender\n" +
		                 "requires a " + required_minutes_nextmap + " min wait\n" +
		                 "after each started vote\n" +
		                 "to prevent spamming.\n");
	}
	else if (me.getTeamNum() == rules.getSpectatorTeamNum())
	{
		Menu::addInfoBox(surrendermenu, "Can't Start Vote", "Voting for surrender\n" +
		                 "is not available as a spectator\n");
	}
	else
	{
		Menu::addInfoBox(surrendermenu, "Vote Surrender", "Vote to end the game\nin favour of the enemy team.\n\n" +
		                 "- report any abuse of this feature.\n" +
		                 "\nTo Use:\n\n" +
		                 "- select surrender if you're sure.\n" +
		                 "- everyone votes.\n");

		Menu::addSeparator(surrendermenu);
		CBitStream params;
		Menu::addContextItemWithParams(surrendermenu, "We Surrender! (I'm sure)", "DefaultVotes.as", "Callback_Surrender", params);
	}
	Menu::addSeparator(surrendermenu);
}

void CloseMenu()
{
	Menu::CloseAllMenus();
}

void onPlayerStartedVote()
{
	g_lastVoteCounter = 0;
	g_lastNextmapCounter = 0;
	g_haveStartedVote = true;
}

void Callback_KickReason(CBitStream@ params)
{
	u8 id; if (!params.saferead_u8(id)) return;

	if (id < kick_reason_count)
	{
		g_kick_reason = kick_reason_string[id];
	}
}

void Callback_Kick(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	u16 id;
	if (!params.saferead_u16(id)) return;

	CPlayer@ other_player = getPlayerByNetworkId(id);
	if (other_player is null) return;

	if (getSecurity().checkAccess_Feature(other_player, "kick_immunity"))
		return;

	//monitor to prevent abuse
	g_lastUsernameVoted = other_player.getUsername();

	CBitStream params2;

	params2.write_u16(other_player.getNetworkID());
	params2.write_u16(me.getNetworkID());
	params2.write_string(g_kick_reason);

	getRules().SendCommand(getRules().getCommandID(votekick_id), params2);
	onPlayerStartedVote();
}

void Callback_NextMap(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	u8 id;
	if (!params.saferead_u8(id)) return;

	string reason = "";
	if (id < nextmap_reason_count)
	{
		reason = nextmap_reason_string[id];
	}

	CBitStream params2;

	params2.write_u16(me.getNetworkID());
	params2.write_string(reason);

	getRules().SendCommand(getRules().getCommandID(votenextmap_id), params2);
	onPlayerStartedVote();
}

void Callback_Surrender(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	CBitStream params2;

	params2.write_u16(me.getNetworkID());

	getRules().SendCommand(getRules().getCommandID(votesurrender_id), params2);
	onPlayerStartedVote();
}

//actually setting up the votes
void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (Rules_AlreadyHasVote(this))
		return;

	if (cmd == this.getCommandID(votekick_id))
	{
		u16 playerid, byplayerid;
		string reason;

		if (!params.saferead_u16(playerid)) return;
		if (!params.saferead_u16(byplayerid)) return;
		if (!params.saferead_string(reason)) return;

		CPlayer@ player = getPlayerByNetworkId(playerid);
		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);

		if (player !is null && byplayer !is null)
			Rules_SetVote(this, Create_Votekick(player, byplayer, reason));
	}
	else if (cmd == this.getCommandID(votenextmap_id))
	{
		u16 byplayerid;
		string reason;

		if (!params.saferead_u16(byplayerid)) return;
		if (!params.saferead_string(reason)) return;

		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);

		if (byplayer !is null)
			Rules_SetVote(this, Create_VoteNextmap(byplayer, reason));

		g_lastNextmapCounter = 0;
	}
	else if (cmd == this.getCommandID(votesurrender_id))
	{
		u16 byplayerid;

		if (!params.saferead_u16(byplayerid)) return;

		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);

		if (byplayer !is null)
			Rules_SetVote(this, Create_VoteSurrender(byplayer));

		g_lastNextmapCounter = 0;
	}
}
