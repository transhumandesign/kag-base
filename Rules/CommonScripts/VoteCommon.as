/**
 * Vote functor interface
 * override
 */

//shared
class VoteFunctor
{
	VoteFunctor() {}
	void Pass(bool outcome) { /* do your vote action in here - remember to check server/client */ }
};

//shared
class VoteCheckFunctor
{
	VoteCheckFunctor() {}
	bool PlayerCanVote(CPlayer@ player)
	{
		//prevent duplicate players from voting
		return !isDuplicatePlayer(player);
	}
};

//shared
class VotePlayerLeaveFunctor
{
	VotePlayerLeaveFunctor() {}
	void PlayerLeft(VoteObject@ vote, CPlayer@ player) { }
};

/**
 * The vote object
 */
//shared
class VoteObject
{

	VoteObject()
	{
		@onvotepassed = null;
		@canvote = null;
		@playerleave = null;
		maximum_votes = getPlayersCount();
		current_yes = current_no = 0;
		timeremaining = 30 * 30; //default 30s
		required_percent = 0.5f; //default 50%
		cancel_on_restart = false;
	}

	VoteFunctor@ onvotepassed;
	VoteCheckFunctor@ canvote;
	VotePlayerLeaveFunctor@ playerleave;

	string title;
	string reason;
	string byuser;
	string user_to_kick = "";
	string forcePassFeature;

	u16[] players; //id of players that have voted explicitly

	int current_yes;
	int current_no;

	float required_percent; //required ratio yes/(yes+no)
	int maximum_votes; //number of players who can vote

	int timeremaining;

	bool cancel_on_restart;
};

shared SColor vote_message_colour() { return SColor(0xff444444); }

//rules methods

void Rules_SetVote(CRules@ this, VoteObject@ vote)
{
	if (!Rules_AlreadyHasVote(this))
	{
		this.set("g_vote", vote);

		if (CanPlayerVote(vote, getLocalPlayer()))
		{
			client_AddToChat(
				getTranslatedString("--- A vote was started by {USER} ---")
					.replace("{USER}", vote.byuser),
				vote_message_colour()
			);
		}
		else
		{
			//more info for server and those who cant see the vote
			if (vote.user_to_kick != "")
			{
				//special case; votekick
				client_AddToChat(
					getTranslatedString("--- Vote \"Kick {KICKUSER}?\" was started by {USER}. Reason: {REASON} ---")
						.replace("{KICKUSER}", getTranslatedString(vote.user_to_kick))
						.replace("{USER}", vote.byuser)
						.replace("{REASON}", getTranslatedString(vote.reason)),
					vote_message_colour()
				);
			}
			else
			{
				client_AddToChat(
					getTranslatedString("--- Vote \"{TITLE}\" was started by {USER}. Reason: {REASON} ---")
						.replace("{TITLE}", getTranslatedString(vote.title)).replace("{USER}", vote.byuser)
						.replace("{REASON}", getTranslatedString(vote.reason)),
					vote_message_colour()
				);
			}

		}
	}
}

VoteObject@ Rules_getVote(CRules@ this)
{
	VoteObject@ vote = null;
	this.get("g_vote", @vote);
	return vote;
}

bool Rules_AlreadyHasVote(CRules@ this)
{
	VoteObject@ tempvote = Rules_getVote(this);
	if (tempvote is null) return false;

	return tempvote.timeremaining > 0;
}

//vote methods

bool Vote_Conclusive(VoteObject@ vote)
{
	bool adminOnline = getRules().get_bool("admin online");
	return !adminOnline && (vote.current_yes > vote.required_percent * vote.maximum_votes
	                        || vote.current_no > (1 - vote.required_percent) * vote.maximum_votes
	                        || vote.current_yes + vote.current_no >= vote.maximum_votes);
}

void PassVote(VoteObject@ vote)
{
	if (vote is null || vote.timeremaining < 0) return;
	vote.timeremaining = -1; // so the gui hides and another vote can start

	if (vote.onvotepassed is null) return;
	bool outcome = vote.current_yes > vote.current_no + 1;//vote.required_percent * vote.maximum_votes;
	client_AddToChat(getTranslatedString("--- Vote {OUTCOME}: {YESCOUNT} vs {NOCOUNT} (out of {MAXVOTES}) ---").replace("{OUTCOME}", getTranslatedString(outcome ? "passed" : "failed")).replace("{YESCOUNT}", vote.current_yes + "").replace("{NOCOUNT}", vote.current_no + "").replace("{MAXVOTES}", vote.maximum_votes + ""), vote_message_colour());
	vote.onvotepassed.Pass(outcome);
}

void ForcePassVote(VoteObject@ vote, CPlayer@ player)
{
	if (vote is null || vote.timeremaining < 0) return;
	vote.timeremaining = -1; // so the gui hides and another vote can start
	client_AddToChat(getTranslatedString("--- Admin {USER} forced vote to pass ---").replace("{USER}", player.getUsername()));
	vote.onvotepassed.Pass(true);
}

void CancelVote(VoteObject@ vote, CPlayer@ player = null)
{
	if (vote is null || vote.timeremaining < 0) return;
	vote.timeremaining = -1; // so the gui hides and another vote can start

	if (player !is null)
	{
		client_AddToChat(getTranslatedString("--- Vote cancelled by admin {USER} ---").replace("{USER}", player.getUsername()), vote_message_colour());
	}
	else
	{
		client_AddToChat(getTranslatedString("--- Vote cancelled ---"), vote_message_colour());
	}
}

/**
 * Check if a player should be allowed to vote - note that this
 * doesn't check if they already have voted
 */

bool CanPlayerVote(VoteObject@ vote, CPlayer@ player)
{
	if (player is null || vote is null)
		return false;

	if (vote.canvote is null)
		return true;

	return vote.canvote.PlayerCanVote(player);
}

/**
 * Cast a vote from a player, in favour or against
 */
void Vote(VoteObject@ vote, CPlayer@ p, bool favour)
{
	if (vote is null || vote.timeremaining < 0) return;

	bool voted = false;

	u16 p_id = p.getNetworkID();
	for (uint i = 0; i < vote.players.length; ++i)
	{
		if (vote.players[i] == p_id)
		{
			voted = true;
			break;
		}
	}

	if (voted)
	{
		warning("double-vote from " + p.getUsername()); //warning about exploits
	}
	else
	{
		vote.players.push_back(p_id);
		if (favour)
		{
			vote.current_yes++;
		}
		else
		{
			vote.current_no++;
		}
		
		bool should_show_votes;
		CPlayer@ player = getLocalPlayer();
		if (player is null)
		{
			should_show_votes = isServer();
		}
		else
		{
			should_show_votes = (player.isDev() || player.isGuard()
				|| isServer() || player.isMod() || player.isRCON());
		}
		
		string text = getTranslatedString("--- {USER} Voted {DECISION} ---")
						.replace("{USER}", p.getUsername())
						.replace("{DECISION}", getTranslatedString(favour ? "In Favour" : "Against")),
					vote_message_colour();
		
		if (should_show_votes) // only let admins see what everyone votes for
			client_AddToChat(text);
	}
}

void CalculateVoteThresholds(VoteObject@ vote)
{
	vote.maximum_votes = 0;
	for (int i = 0; i < getPlayersCount(); ++i)
	{
		if (CanPlayerVote(vote, getPlayer(i)))
		{
			vote.maximum_votes++;
		}
	}
}

bool isDuplicatePlayer(CPlayer@ player)
{
	return player.getUsername().find("~") > -1;
}
