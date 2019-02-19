//implementation of patron-related rules-side extra functionality

//extra patron slots handling
const int PATRON_EXTRA_SLOTS = 2;
int onProcessFullJoin(CRules@ this, APIPlayer@ user)
{
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