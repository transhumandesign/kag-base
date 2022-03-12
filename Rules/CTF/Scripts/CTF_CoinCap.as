// hacky
#define SERVER_ONLY

const int coin_cap = 600;

void onTick(CRules@ this)
{
	// coin cap won't exist during the christmas holiday
	if(this.hasTag("remove coincap")) return;

	for(int a = 0; a < getPlayerCount(); a++)
	{
		CPlayer@ p = getPlayer(a);
		if(p is null) continue;
		if(p.getCoins() > coin_cap) p.server_setCoins(coin_cap);
	}
}  