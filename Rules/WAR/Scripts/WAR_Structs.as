// management structs

#include "BaseTeamInfo.as";
#include "PlayerInfo.as";

shared class WarPlayerInfo : PlayerInfo
{
	u16 spawnpoint;
	u8 wave_delay;
	Vec2f deathPosition;
	f32 deathDistanceToBase;
	bool suicide;
	// spawn mats
	bool canGetArcherItems;
	bool canGetKnightItems;
	bool canGetBuilderItems;

	WarPlayerInfo() { Setup("", 0, ""); }
	WarPlayerInfo(string _name, u8 _team, string _default_config) { Setup(_name, _team, _default_config); }

	void Setup(string _name, u8 _team, string _default_config)
	{
		PlayerInfo::Setup(_name, _team, _default_config);
		spawnpoint = 0;
		wave_delay = 0;
		deathDistanceToBase = -1.0f;
		suicide = false;
		canGetArcherItems = canGetKnightItems = canGetBuilderItems = true;
	}

	bool opEquals(const WarPlayerInfo &in other) const
	{
		return this is other;
	}
};

//teams

shared class WarTeamInfo : BaseTeamInfo
{
	u32 endgame_start;
	PlayerInfo@[] respawns;
	bool under_raid;
	u16 base_id; // redundant
	u16 migrantCount;
	u16 migrantsInDormCount;
	u16 bedsCount;
	u16 factory_usage;

	WarTeamInfo() { super(); }

	WarTeamInfo(u8 _index, string _name)
	{
		super(_index, _name);
	}

	void Reset()
	{
		BaseTeamInfo::Reset();
		//respawns.clear();
		base_id = 0;
		endgame_start = 0;
		under_raid = false;
		migrantCount = migrantsInDormCount = bedsCount = factory_usage = 0;
	}

	bool opEquals(const WarTeamInfo &in other) const
	{
		return this is other;
	}
};

//return techs.find(name) >= 0; WHY U NO W RK!?
