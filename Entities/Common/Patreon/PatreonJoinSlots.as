#define SERVER_ONLY
//implementation of patron-related rules-side extra functionality

//extra patron slots handling
const int PATRON_EXTRA_SLOTS = 2;
int onProcessFullJoin(CRules@ this, APIPlayer@ user)
{
	this.set_u16("supportTier " + user.username, user.supportTier);

	//allow royal guard and up supporters in
	if(
		//user is good supporter
		user.supportTier >= SUPPORT_TIER_ROYALGUARD
		//not up to the extra slots yet
		&& getPlayersCount() < (sv_maxplayers + PATRON_EXTRA_SLOTS)
	) {
		return 1;
	}
	//ignore otherwise
	return -1;
}

// If a patreon joins and is on spec team, lets sort this out
void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
	if (this.get_u16("supportTier " + player.getUsername()) >= SUPPORT_TIER_ROYALGUARD && // if we are high enough in the tier list
		this.getSpectatorTeamNum() == player.getTeamNum() && // and we are a spectator
		getPlayersCount_NotSpectator() < sv_maxplayers + PATRON_EXTRA_SLOTS) // and there are still free slots for us
	{
		player.server_setTeamNum(255); // server will auto balance them
	}

}