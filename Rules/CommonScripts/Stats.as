#define SERVER_ONLY

const string mapStatsTag = "map stats";

void onStateChange( CRules@ this, const u8 oldState )
{
	if (this.isGameOver() && this.getTeamWon() >= 0)
	{
		string mapName = getFilenameWithoutExtension(getFilenameWithoutPath(getMap().getMapName()));
		tcpr("MapStats {\"name\":\"" + mapName + "\",\"duration\":" + getGameTime() + "}");
	}
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if(!this.isMatchRunning())
	{
		return;
	}

	if(sv_tcpr && victim !is null)
	{
		string victimObject = JSONPlayer(victim);
		string victimClass = victim.lastBlobName;

		string killerObject = victimObject;
		string killerClass = victimClass;

		if(killer !is null)
		{
			killerObject = JSONPlayer(killer);
			killerClass = killer.lastBlobName;
		}

		array<string> jsonProps = {
			"\"victim\":" + victimObject,
			"\"killer\":" + killerObject,
			JSONString("victimClass", victimClass),
			JSONString("killerClass", killerClass),
			JSONInt("Hitter", customData)
		};

		if(killer !is null && killer.getTeamNum() == victim.getTeamNum())
		{
			jsonProps.push_back(JSONBool("teamKill", true));

		}

		tcpr("PlayerDied " + JSON(join(jsonProps, ",")));
	}
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player ) {
	if(sv_tcpr)
	{
		print("player joined");
		tcpr("PlayerJoined " + JSONPlayer(player));

	}
}

void onPlayerLeave( CRules@ this, CPlayer@ player ) {
	if(sv_tcpr)
	{
		print("player left");
		tcpr("PlayerLeft " + JSONPlayer(player));
	}
}

string JSONPlayer(CPlayer@ player)
{
	array<string> props = {
		JSONString("username", player.getUsername()),
		JSONString("charactername", player.getCharacterName()),
		JSONString("clantag", player.getClantag()),
		JSONString("ip", player.server_getIP())
	};

	if(player.exists("stats_id"))
	{
		props.push_back(JSONInt("ID", player.get_u32("stats_id")));

	}

	return JSON(join(props,","));
}

string JSONProp(string name)
{
	return "\"" + name + "\":";
}

string JSONString(string name, string value)
{
	return JSONProp(name) + "\"" + value + "\"";

}

string JSONNull(string name)
{
	return JSONProp(name) + "null";

}

string JSONInt(string name, int value)
{
	return JSONProp(name) + value;

}

string JSONBool(string name, bool value)
{
	return JSONProp(name) + value;
}

string JSONObject(string name, string object)
{
	return JSONProp(name) + JSON(object);

}

string JSON(string object)
{
	return "{" + object + "}";
}
