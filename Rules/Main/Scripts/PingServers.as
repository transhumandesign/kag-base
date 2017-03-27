
funcdef void CALLBACK();

void onTick( CRules@ this )
{
	uint gameTime = getGameTime();
	uint createdTime = this.get_u32("PingServers created time");
	if (createdTime == 0) {
		this.set_u32("PingServers created time", gameTime);
		createdTime = gameTime;
	}
	if((gameTime - createdTime) % 5 != 0) return;

	CScriptedBrowser@ b = getBrowser();
	APIServer@[] servers;
	b.getServersList(servers);

	for (int i = 0; i < servers.length; ++i)
		if (servers[i].ping == -2 && gameTime < createdTime + 41 ) return;

	CALLBACK@ cb;
	this.get("OnPinged", @cb);
	cb();
	this.set_u32("PingServers created time", 0);
	this.RemoveScript("PingServers");
}
