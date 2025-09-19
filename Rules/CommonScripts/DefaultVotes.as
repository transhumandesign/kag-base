//implements 2 default vote types (kick and next map) and menus for them

#include "VoteCommon.as"

enum vote_type
{
	vote_type_kick = 0,
	vote_type_nextmap,
	vote_type_surrender,
	vote_type_scramble,
	vote_type_count
};

bool g_haveStartedVote = false;

const float required_minutes = 10; //time you have to wait after joining w/o skip_votewait.
const float required_minutes_nextmap = 10; //global nextmap vote cooldown

const s32 VoteKickTime = 30; //minutes (30min default)

//kicking related globals and enums
enum kick_reason
{
	kick_reason_griefer = 0,
	kick_reason_hacker,
	kick_reason_teamkiller,
	kick_reason_spammer,
	kick_reason_non_participation,
	kick_reason_count,
};
string[] kick_reason_string = { "Griefer", "Hacker", "Teamkiller", "Chat Spam", "Non-Participation" };

u8 g_kick_reason_id = kick_reason_griefer; // default

//next map related globals and enums
enum nextmap_reason
{
	nextmap_reason_ruined = 0,
	nextmap_reason_stalemate,
	nextmap_reason_bugged,
	nextmap_reason_count,
};

string[] nextmap_reason_string = { "Map Ruined", "Stalemate", "Game Bugged" };

void onInit(CRules@ this)
{
	this.addCommandID("vote_start");
	this.addCommandID("vote_start_client");
}

void onRestart(CRules@ this)
{
	if (isServer())
	{
		for (int i=0; i<getPlayerCount(); ++i)
		{
			CPlayer@ p = getPlayer(i);
			if (p is null) continue;

			this.set_s32("last nextmap counter player " + p.getUsername(), 60 * getTicksASecond() * required_minutes_nextmap);
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	string username = player.getUsername();

	this.set_s32("last vote counter player " + username, 0);
	this.SyncToPlayer("last vote counter player " + username, player);

	this.set_s32("last nextmap counter player " + username, 0);
	this.SyncToPlayer("last nextmap counter player " + username, player);
}

void onTick(CRules@ this)
{
	// server-side counter for every player since we don't trust the client
	if (isServer())
	{
		// update every 10 seconds only? probably not necessary but whatever
		if (getGameTime() % (10 * getTicksASecond()) == 0)
		{
			for (int i=0; i<getPlayerCount(); ++i)
			{
				CPlayer@ p = getPlayer(i);
				if (p is null) continue;

				string username = p.getUsername();

				if (this.get_s32("last vote counter player " + username) < 60 * getTicksASecond()*required_minutes)
				{
					this.add_s32("last vote counter player " + username, (10 * getTicksASecond()));
					this.SyncToPlayer("last vote counter player " + username, p);
				}
				if (this.get_s32("last nextmap counter player " + username) < 60 * getTicksASecond()*required_minutes_nextmap)
				{
					this.add_s32("last nextmap counter player " + username, (10 * getTicksASecond()));
					this.SyncToPlayer("last nextmap counter player " + username, p);
				}
			}
		}
	}
}

//VOTE KICK --------------------------------------------------------------------
//votekick functors

class VoteKickFunctor : VoteFunctor
{
	VoteKickFunctor() {} //dont use this
	VoteKickFunctor(CPlayer@ _kickplayer, CPlayer@ _byplayer, u8 _reasonid)
	{
		@kickplayer = _kickplayer;
		@byplayer = _byplayer;
		reasonid = _reasonid;
	}

	CPlayer@ kickplayer;
	CPlayer@ byplayer;
	u8 reasonid;

	void Pass(bool outcome)
	{
		if (kickplayer is null) 
		{
			return;
		}

		if (outcome)
		{
			client_AddToChat(
				getTranslatedString("Votekick passed! {USER} will be kicked out.")
					.replace("{USER}", kickplayer.getUsername()),
				vote_message_colour()
			);

			if (isServer())
			{
				getSecurity().ban(kickplayer, VoteKickTime, "Voted off"); //30 minutes ban
			}	
		}

		// Log the vote!
		if (sv_tcpr && isServer())	
		{
			string username = byplayer !is null ? byplayer.getUsername() : " unknown";
			string voteResult = outcome ? " has successfully voted" : " attempted";

			string message = username + voteResult + " to kick " + kickplayer.getUsername() + " ("+ kick_reason_string[reasonid] +")";
			string serverip = getNet().sv_current_ip;			

			tcpr("*LOG *MESSAGE=\"" + message + "\" *SERVERNAME=\"" + sv_name + "\" *SERVERIP=\"" + serverip + "\"");
		}
	}
};

class VoteKickCheckFunctor : VoteCheckFunctor
{
	VoteKickCheckFunctor() {}//dont use this
	VoteKickCheckFunctor(CPlayer@ _kickplayer, u8 _reasonid)
	{
		@kickplayer = _kickplayer;
		reasonid = _reasonid;
	}

	CPlayer@ kickplayer;
	u8 reasonid;

	bool PlayerCanVote(CPlayer@ player)
	{
		if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

		if (!getSecurity().checkAccess_Feature(player, "mark_player")) return false;

		if (reasonid == kick_reason_griefer || // "Griefer"
				reasonid == kick_reason_teamkiller || // TKer
				reasonid == kick_reason_non_participation) //AFK
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
			client_AddToChat(
				getTranslatedString("{USER} left early, acting as if they were kicked.")
					.replace("{USER}", player.getUsername()),
				vote_message_colour()
			);
			if (isServer())
			{
				getSecurity().ban(player, VoteKickTime, "Ran from vote");
			}

			CancelVote(vote);
		}
	}
};

//setting up a votekick object
VoteObject@ Create_Votekick(CPlayer@ player, CPlayer@ byplayer, u8 reasonid)
{
	VoteObject vote;

	@vote.onvotepassed = VoteKickFunctor(player, byplayer, reasonid);
	@vote.canvote = VoteKickCheckFunctor(player, reasonid);
	@vote.playerleave = VoteKickLeaveFunctor(player);

	vote.title = "Kick {USER}?";
	vote.reason = kick_reason_string[reasonid];
	vote.byuser = byplayer.getUsername();
	vote.user_to_kick = player.getUsername();
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
		if (
			charname != username &&
			charname != player.getClantag() + username &&
			charname != player.getClantag() + " " + username
		) {
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
			if (isServer())
			{
				getRules().SetCurrentState(GAME_OVER);
			}
		}
		else
		{
			client_AddToChat(
				getTranslatedString("{USER} needs to take a spoonful of cement! Play on!")
					.replace("{USER}", playername),
				vote_message_colour()
			);
		}
	}
};

class VoteNextmapCheckFunctor : VoteCheckFunctor
{
	VoteNextmapCheckFunctor() {}

	bool PlayerCanVote(CPlayer@ player)
	{
		if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

		return getSecurity().checkAccess_Feature(player, "map_vote");
	}
};

//setting up a vote next map object
VoteObject@ Create_VoteNextmap(CPlayer@ byplayer, u8 reasonid)
{
	VoteObject vote;

	@vote.onvotepassed = VoteNextmapFunctor(byplayer);
	@vote.canvote = VoteNextmapCheckFunctor();

	vote.title = "Skip to next map?";
	vote.reason = nextmap_reason_string[reasonid];
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
		if (
			charname != username &&
			charname != player.getClantag() + username &&
			charname != player.getClantag() + " " + username
		) {
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
			if (isServer())
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
			client_AddToChat(getTranslatedString("{USER} needs to take a spoonful of cement! Play on!").replace("{USER}", playername), vote_message_colour());
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
		if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

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

//VOTE SCRAMBLE ----------------------------------------------------------------
//scramble functors

class VoteScrambleFunctor : VoteFunctor
{
	VoteScrambleFunctor() {} //dont use this
	VoteScrambleFunctor(CPlayer@ player)
	{
		string charname = player.getCharacterName();
		string username = player.getUsername();
		//name differs?
		if (
			charname != username &&
			charname != player.getClantag() + username &&
			charname != player.getClantag() + " " + username
		) {
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
			if (isServer())
			{
				LoadMap(getMap().getMapName());
			}
		}
		else
		{
			client_AddToChat(
				getTranslatedString("{USER} needs to take a spoonful of cement! Play on!")
					.replace("{USER}", playername),
				vote_message_colour()
			);
		}
	}
};

class VoteScrambleCheckFunctor : VoteCheckFunctor
{
	VoteScrambleCheckFunctor() {}

	bool PlayerCanVote(CPlayer@ player)
	{
		if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

		return player.getTeamNum() != getRules().getSpectatorTeamNum();
	}
};

//setting up a vote next map object
VoteObject@ Create_VoteScramble(CPlayer@ byplayer)
{
	VoteObject vote;

	@vote.onvotepassed = VoteScrambleFunctor(byplayer);
	@vote.canvote = VoteScrambleCheckFunctor();

	vote.title = "Scramble the teams?";
	vote.reason = "";
	vote.byuser = byplayer.getUsername();
	vote.forcePassFeature = "scramble";
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
		Menu::addContextItem(menu, getTranslatedString("(Vote already in progress)"), "DefaultVotes.as", "void CloseMenu()");
		Menu::addSeparator(menu);

		return;

	}

	//and advance context menu when clicked
	CContextMenu@ votemenu = Menu::addContextMenu(menu, getTranslatedString("Start a Vote"));
	Menu::addSeparator(menu);

	//vote options menu

	CContextMenu@ kickmenu = Menu::addContextMenu(votemenu, getTranslatedString("Kick"));
	CContextMenu@ mapmenu = Menu::addContextMenu(votemenu, getTranslatedString("Next Map"));
	CContextMenu@ surrendermenu = Menu::addContextMenu(votemenu, getTranslatedString("Surrender"));
	CContextMenu@ scramblemenu = Menu::addContextMenu(votemenu, getTranslatedString("Scramble"));
	Menu::addSeparator(votemenu); //before the back button

	bool can_skip_wait = getSecurity().checkAccess_Feature(me, "skip_votewait");

	bool duplicatePlayer = isDuplicatePlayer(me);

	//kick menu
	if (getSecurity().checkAccess_Feature(me, "mark_player"))
	{
		if (duplicatePlayer)
		{
			Menu::addInfoBox(
				kickmenu,
				getTranslatedString("Can't Start Vote"),
				getTranslatedString(
					"Voting to kick a player\n" +
					"is not allowed when playing\n" +
					"with a duplicate instance of KAG.\n\n" +
					"Try rejoining the server\n" +
					"if this was unintentional."
				)
			);
		}
		else if (this.get_s32("last vote counter player " + me.getUsername()) < 60 * getTicksASecond()*required_minutes // synced from server
				&& (!can_skip_wait || g_haveStartedVote))
		{
			string cantstart_info = getTranslatedString(
				"Voting requires a {REQUIRED_MIN} min wait\n" +
				"after each started vote to\n" +
				"prevent spamming/abuse.\n"
			).replace("{REQUIRED_MIN}", "" + required_minutes);

			Menu::addInfoBox(kickmenu, getTranslatedString("Can't Start Vote"), cantstart_info);
		}
		else
		{
			string votekick_info = getTranslatedString(
				"Vote to kick a player on your team\nout of the game.\n\n" +
				"- use responsibly\n" +
				"- report any abuse of this feature.\n" +
				"\nTo Use:\n\n" +
				"- select a reason from the\n     list (default is griefing).\n" +
				"- select a name from the list.\n" +
				"- everyone votes.\n"
			);
			Menu::addInfoBox(kickmenu, getTranslatedString("Vote Kick"), votekick_info);

			Menu::addSeparator(kickmenu);

			//reasons
			for (uint i = 0 ; i < kick_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				Menu::addContextItemWithParams(kickmenu, getTranslatedString(kick_reason_string[i]), "DefaultVotes.as", "Callback_KickReason", params);
			}

			Menu::addSeparator(kickmenu);

			//write all players on our team
			bool added = false;
			for (int i = 0; i < getPlayersCount(); ++i)
			{
				CPlayer@ player = getPlayer(i);

				//if (player is me) continue; //don't display ourself for kicking
				//commented out for max lols

				int player_team = player.getTeamNum();
				if ((player_team == me.getTeamNum() || player_team == this.getSpectatorTeamNum()
						|| getSecurity().checkAccess_Feature(me, "mark_any_team"))
						&& (!getSecurity().checkAccess_Feature(player, "kick_immunity")))
				{
					string descriptor = player.getCharacterName();

					if (player.getUsername() != player.getCharacterName())
						descriptor += " (" + player.getUsername() + ")";

					if (this.get_string("last username voted " + me.getUsername()) == player.getUsername()) // synced from server
					{
						string title = getTranslatedString(
							"Cannot kick {USER}"
						).replace("{USER}", descriptor);
						string info = getTranslatedString(
							"You started a vote for\nthis person last time.\n\nSomeone else must start the vote."
						);
						//no-abuse box
						Menu::addInfoBox(
							kickmenu,
							title,
							info
						);
					}
					else
					{
						string kick = getTranslatedString("Kick {USER}").replace("{USER}", descriptor);
						string kicking = getTranslatedString("Kicking {USER}").replace("{USER}", descriptor);
						string info = getTranslatedString( "Make sure you're voting to kick\nthe person you meant.\n" );

						CContextMenu@ usermenu = Menu::addContextMenu(kickmenu, kick);
						Menu::addInfoBox(usermenu, kicking, info);
						Menu::addSeparator(usermenu);

						CBitStream params;
						params.write_u16(player.getNetworkID());

						Menu::addContextItemWithParams(
							usermenu, getTranslatedString("Yes, I'm sure"),
							"DefaultVotes.as", "Callback_Kick",
							params
						);
						added = true;

						Menu::addSeparator(usermenu);
					}
				}
			}

			if (!added)
			{
				Menu::addContextItem(
					kickmenu, getTranslatedString("(No-one available)"),
					"DefaultVotes.as", "void CloseMenu()"
				);
			}
		}
	}
	else
	{
		Menu::addInfoBox(
			kickmenu,
			getTranslatedString("Can't vote"),
			getTranslatedString(
				"You are not allowed to votekick\n" +
				"players on this server\n"
			)
		);
	}
	Menu::addSeparator(kickmenu);

	//nextmap menu
	if (getSecurity().checkAccess_Feature(me, "map_vote"))
	{
		if (duplicatePlayer)
		{
			Menu::addInfoBox(
				mapmenu,
				getTranslatedString("Can't Start Vote"),
				getTranslatedString(
					"Voting for next map\n" +
					"is not allowed when playing\n" +
					"with a duplicate instance of KAG.\n\n" +
					"Try rejoining the server\n" +
					"if this was unintentional."
				)
			);
		}
		else if (this.get_s32("last nextmap counter player " + me.getUsername()) < 60 * getTicksASecond()*required_minutes_nextmap // synced from server
				&& (!can_skip_wait || g_haveStartedVote))
		{
			string cantstart_info = getTranslatedString(
				"Voting for next map\n" +
				"requires a {NEXTMAP_MINS} min wait\n" +
				"after each started vote\n" +
				"to prevent spamming.\n"
			).replace("{NEXTMAP_MINS}", "" + required_minutes_nextmap);
			Menu::addInfoBox( mapmenu, getTranslatedString("Can't Start Vote"), cantstart_info);
		}
		else
		{
			string nextmap_info = getTranslatedString(
				"Vote to change the map\nto the next in cycle.\n\n" +
				"- report any abuse of this feature.\n" +
				"\nTo Use:\n\n" +
				"- select a reason from the list.\n" +
				"- everyone votes.\n"
			);
			Menu::addInfoBox(mapmenu, getTranslatedString("Vote Next Map"), nextmap_info);

			Menu::addSeparator(mapmenu);
			//reasons
			for (uint i = 0 ; i < nextmap_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				Menu::addContextItemWithParams(mapmenu, getTranslatedString(nextmap_reason_string[i]), "DefaultVotes.as", "Callback_NextMap", params);
			}
		}
	}
	else
	{
		Menu::addInfoBox(
			mapmenu,
			getTranslatedString("Can't vote"),
			getTranslatedString(
				"You are not allowed to vote\n" +
				"to change the map on this server\n"
			)
		);
	}
	Menu::addSeparator(mapmenu);

	//surrender menu
	//(shares nextmap counter to prevent nextmap/surrender spam)
	if (duplicatePlayer)
	{
		Menu::addInfoBox(
			surrendermenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for surrender\n" +
				"is not allowed when playing\n" +
				"with a duplicate instance of KAG.\n\n" +
				"Try rejoining the server\n" +
				"if this was unintentional."
		)
		);
	}
	else if (me.getTeamNum() == rules.getSpectatorTeamNum())
	{
		Menu::addInfoBox(
			surrendermenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for surrender\n" +
				"is not available as a spectator\n"
			)
		);
	}
	else if (!this.isMatchRunning() && !can_skip_wait)
	{
		Menu::addInfoBox(
			surrendermenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for surrender\n" +
				"is not allowed before the game starts.\n"
			)
		);
	}
	else if (this.get_s32("last nextmap counter player " + me.getUsername()) < 60 * getTicksASecond()*required_minutes_nextmap // synced from server
			 && (!can_skip_wait || g_haveStartedVote))
	{
		string cantstart_info = getTranslatedString(
			"Voting for surrender\n" +
			"requires a {NEXTMAP_MINS} min wait\n" +
			"after each started vote\n" +
			"to prevent spamming.\n"
		).replace("{NEXTMAP_MINS}", "" + required_minutes_nextmap);
		Menu::addInfoBox(surrendermenu, getTranslatedString("Can't Start Vote"), cantstart_info);
	}
	else
	{
		Menu::addInfoBox(
			surrendermenu,
			getTranslatedString("Vote Surrender"),
			getTranslatedString(
				"Vote to end the game\nin favour of the enemy team.\n\n" +
				"- report any abuse of this feature.\n" +
				"\nTo Use:\n\n" +
				"- select surrender if you're sure.\n" +
				"- everyone votes.\n"
			)
		);

		Menu::addSeparator(surrendermenu);
		CBitStream params;
		Menu::addContextItemWithParams(
			surrendermenu,
			getTranslatedString("We Surrender! (I'm sure)"),
			"DefaultVotes.as", "Callback_Surrender",
			params
		);
	}
	Menu::addSeparator(surrendermenu);

	if (duplicatePlayer)
	{
		Menu::addInfoBox(
			scramblemenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for team scramble\n" +
				"is not allowed when playing\n" +
				"with a duplicate instance of KAG.\n\n" +
				"Try rejoining the server\n" +
				"if this was unintentional."
			)
		);
	}
	else if (me.getTeamNum() == rules.getSpectatorTeamNum())
	{
		Menu::addInfoBox(
			scramblemenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for team scramble\n" +
				"is not available as a spectator\n"
			)
		);
	}
	else if (!this.isWarmup())
	{
		Menu::addInfoBox(
			scramblemenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for team scramble\n" +
				"is not allowed after the game starts.\n"
			)
		);
	}
	else if (this.get_s32("last nextmap counter player " + me.getUsername()) < 60 * getTicksASecond()*required_minutes_nextmap // synced from server
			 && (!can_skip_wait || g_haveStartedVote))
	{
		string cantstart_info = getTranslatedString(
			"Voting for team scramble\n" +
			"requires a {NEXTMAP_MINS} min wait\n" +
			"after each started vote\n" +
			"to prevent spamming.\n"
		).replace("{NEXTMAP_MINS}", "" + required_minutes_nextmap);
		Menu::addInfoBox(scramblemenu, getTranslatedString("Can't Start Vote"), cantstart_info);
	}
	else
	{
		Menu::addInfoBox(
			scramblemenu,
			getTranslatedString("Vote team scramble"),
			getTranslatedString(
				"Vote to scramble teams\nto hopefully make them balanced.\n\n" +
				"- report any abuse of this feature.\n" +
				"\nTo Use:\n\n" +
				"- select scramble if you're sure.\n" +
				"- everyone votes.\n"
			)
		);

		Menu::addSeparator(scramblemenu);
		CBitStream params;
		Menu::addContextItemWithParams(
			scramblemenu,
			getTranslatedString("Rebalance Teams! (I'm sure)"),
			"DefaultVotes.as", "Callback_Scramble",
			params
		);
	}
	Menu::addSeparator(scramblemenu);
}

void CloseMenu()
{
	Menu::CloseAllMenus();
}

void onPlayerStartedVote()
{
	g_haveStartedVote = true;
}

void Callback_KickReason(CBitStream@ params)
{
	u8 id; if (!params.saferead_u8(id)) return;

	if (id < kick_reason_count)
	{
		g_kick_reason_id = id;
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

	CBitStream params2;
	params2.write_u8(vote_type_kick);
	params2.write_u16(other_player.getNetworkID());
	params2.write_u8(g_kick_reason_id);

	getRules().SendCommand(getRules().getCommandID("vote_start"), params2);
}

void Callback_NextMap(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	u8 id;
	if (!params.saferead_u8(id)) return;

	CBitStream params2;
	params2.write_u8(vote_type_nextmap);
	params2.write_u16(me.getNetworkID());
	params2.write_u8(id);

	getRules().SendCommand(getRules().getCommandID("vote_start"), params2);
}

void Callback_Surrender(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	CBitStream params2;
	params2.write_u8(vote_type_surrender);
	params2.write_u16(me.getNetworkID());

	getRules().SendCommand(getRules().getCommandID("vote_start"), params2);
}

void Callback_Scramble(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	CBitStream params2;
	params2.write_u8(vote_type_scramble);
	params2.write_u16(me.getNetworkID());

	getRules().SendCommand(getRules().getCommandID("vote_start"), params2);
}


bool server_canPlayerStartVote(CRules@ this, CPlayer@ player, CPlayer@ other_player, u8 vote_type)
{
	if (player is null) return false;

	bool can_skip_wait = getSecurity().checkAccess_Feature(player, "skip_votewait");

	if (vote_type == vote_type_kick)
	{
		if (other_player is null || getSecurity().checkAccess_Feature(other_player, "kick_immunity")) return false;
		if (this.get_string("last username voted " + player.getUsername()) == other_player.getUsername()) return false;
		if (!can_skip_wait && this.get_s32("last vote counter player " + player.getUsername()) < 60 * getTicksASecond()*required_minutes) return false;
	}
	else if (vote_type == vote_type_nextmap)
	{
		if (!can_skip_wait && this.get_s32("last nextmap counter player " + player.getUsername()) < 60 * getTicksASecond()*required_minutes_nextmap) return false;
	}
	else if (vote_type == vote_type_surrender)
	{
		if (!can_skip_wait && this.get_s32("last nextmap counter player " + player.getUsername()) < 60 * getTicksASecond()*required_minutes_nextmap) return false;
	}
	else if (vote_type == vote_type_scramble)
	{
		if (!can_skip_wait && this.get_s32("last nextmap counter player " + player.getUsername()) < 60 * getTicksASecond()*required_minutes_nextmap) return false;
	}

	return true;
}

//actually setting up the votes
void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (Rules_AlreadyHasVote(this)) return;

	// Server voting
	if (cmd == this.getCommandID("vote_start") && isServer())
	{
		u8 vote_type_value;
		if (!params.saferead_u8(vote_type_value)) return;
		if (vote_type_value >= vote_type_count) return;

		CPlayer@ byplayer = getNet().getActiveCommandPlayer();
		if (byplayer is null) return;

		CBitStream client_params;
		client_params.write_u8(vote_type_value);

		if (vote_type_value == vote_type_kick)
		{
			u16 playerid;
			if (!params.saferead_u16(playerid)) return;
			u8 reasonid;
			if (!params.saferead_u8(reasonid)) return;
			if (reasonid >= kick_reason_count) return;

			CPlayer@ player = getPlayerByNetworkId(playerid);
			if (player is null) return;

			if (!server_canPlayerStartVote(this, byplayer, player, vote_type_kick)) return;

			this.set_s32("last vote counter player " + byplayer.getUsername(), 0);
			this.SyncToPlayer("last vote counter player " + byplayer.getUsername(), byplayer);

			this.set_string("last username voted " + byplayer.getUsername(), player.getUsername());
			this.SyncToPlayer("last username voted " + byplayer.getUsername(), byplayer);

			Rules_SetVote(this, Create_Votekick(player, byplayer, reasonid));

			client_params.write_u16(playerid);
			client_params.write_u8(reasonid);
			client_params.write_u16(byplayer.getNetworkID());
		}
		else if (vote_type_value == vote_type_nextmap)
		{
			u8 reasonid;
			if (!params.saferead_u8(reasonid)) return;
			if (reasonid >= nextmap_reason_count) return;

			if (!server_canPlayerStartVote(this, byplayer, null, vote_type_nextmap)) return;

			this.set_s32("last nextmap counter player " + byplayer.getUsername(), 0);
			this.SyncToPlayer("last nextmap counter player " + byplayer.getUsername(), byplayer);

			Rules_SetVote(this, Create_VoteNextmap(byplayer, reasonid));

			client_params.write_u8(reasonid);
			client_params.write_u16(byplayer.getNetworkID());
		}
		else if (vote_type_value == vote_type_surrender)
		{
			if (!server_canPlayerStartVote(this, byplayer, null, vote_type_surrender)) return;

			this.set_s32("last nextmap counter player " + byplayer.getUsername(), 0);
			this.SyncToPlayer("last nextmap counter player " + byplayer.getUsername(), byplayer);

			Rules_SetVote(this, Create_VoteSurrender(byplayer));

			client_params.write_u16(byplayer.getNetworkID());
		}
		else if (vote_type_value == vote_type_scramble) 
		{
			if (!server_canPlayerStartVote(this, byplayer, null, vote_type_scramble)) return;

			this.set_s32("last nextmap counter player " + byplayer.getUsername(), 0);
			this.SyncToPlayer("last nextmap counter player " + byplayer.getUsername(), byplayer);

			Rules_SetVote(this, Create_VoteScramble(byplayer));

			client_params.write_u16(byplayer.getNetworkID());
		}

		this.SendCommand(this.getCommandID("vote_start_client"), client_params);
	}
	// Client voting
	else if (cmd == this.getCommandID("vote_start_client") && isClient())
	{
		u8 vote_type_value;
		if (!params.saferead_u8(vote_type_value)) return;
		if (vote_type_value >= vote_type_count) return;

		if (vote_type_value == vote_type_kick)
		{
			u16 playerid;
			if (!params.saferead_u16(playerid)) return;
			u8 reasonid;
			if (!params.saferead_u8(reasonid)) return;
			if (reasonid >= kick_reason_count) return;
			u16 byplayerid;
			if (!params.saferead_u16(byplayerid)) return;

			CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);
			CPlayer@ player = getPlayerByNetworkId(playerid);
			if (byplayer is null || player is null) return;

			Rules_SetVote(this, Create_Votekick(player, byplayer, reasonid));
		}
		else if (vote_type_value == vote_type_nextmap)
		{
			u8 reasonid;
			if (!params.saferead_u8(reasonid)) return;
			if (reasonid >= nextmap_reason_count) return;
			u16 byplayerid;
			if (!params.saferead_u16(byplayerid)) return;

			CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);
			if (byplayer is null) return;

			Rules_SetVote(this, Create_VoteNextmap(byplayer, reasonid));
		}
		else if (vote_type_value == vote_type_surrender)
		{
			u16 byplayerid;
			if (!params.saferead_u16(byplayerid)) return;

			CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);
			if (byplayer is null) return;

			Rules_SetVote(this, Create_VoteSurrender(byplayer));
		}
		else if (vote_type_value == vote_type_scramble)
		{
			u16 byplayerid;
			if (!params.saferead_u16(byplayerid)) return;

			CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);
			if (byplayer is null) return;

			Rules_SetVote(this, Create_VoteScramble(byplayer));
		}
	}
}