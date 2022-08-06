
#ifndef INCLUDED_PLAYERINFO
#define INCLUDED_PLAYERINFO

shared class PlayerInfo
{
	string username; //used to get the player
	u8 team, oldteam;
	string blob_name;
	int spawnsCount;
	int lastSpawnRequest;
	int customImmunityTime;

	PlayerInfo() { Setup("", 0, ""); }
	PlayerInfo(string _name, u8 _team, string _default_config) { Setup(_name, _team, _default_config); }

	void Setup(string _name, u8 _team, string _default_config)
	{
		username = _name;
		team = _team;
		blob_name = _default_config;
		spawnsCount = 0;
		oldteam = 255;
		lastSpawnRequest = 0;
		customImmunityTime = -1;
	}

	void setTeam(u8 newTeam)
	{
		oldteam = team;
		team = newTeam;
	}

	//pure reference equality
	bool opEquals(const PlayerInfo &in other) const
	{
		return this is other;
	}

	//pass off to string's comparision :)
	int opCmp(const PlayerInfo &in other) const
	{
		return username.opCmp(other.username);
	}

};

#endif
