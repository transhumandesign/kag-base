
#ifndef INCLUDED_BASETEAMINFO
#define INCLUDED_BASETEAMINFO

shared class BaseTeamInfo
{
	u8 index;
	string name;
	s32 players_count, alive_count;

	bool lost;

	BaseTeamInfo() { index = 0; name = ""; Reset(); }

	BaseTeamInfo(u8 _index, string _name)
	{
		index = _index;
		name = _name;
		Reset();
	}

	void Reset()
	{
		players_count = alive_count = 0;
		lost = false;
	}

};

shared s32 getTeamSize(BaseTeamInfo@[]@ teams, int team)
{
	if (team >= 0 && team < teams.length)
	{
		return teams[team].players_count;
	}

	return 0;
}


shared s32 getSmallestTeam(BaseTeamInfo@[]@ teams)
{
	s32 lowestTeam = (XORRandom(512) % teams.length);
	s32 lowestCount = teams[lowestTeam].players_count;

	for (uint i = 0; i < teams.length; i++)
	{
		int size = getTeamSize(teams, i);
		if (size < lowestCount)
		{
			lowestCount = size;
			lowestTeam = i;
		}
	}

	return lowestTeam;
}

shared int getLargestTeam(BaseTeamInfo@[]@ teams)
{
	s32 largestTeam = (XORRandom(512) % teams.length);
	s32 largestCount = teams[largestTeam].players_count;

	for (uint i = 0; i < teams.length; i++)
	{
		s32 size = getTeamSize(teams, i);
		if (size > largestCount)
		{
			largestCount = size;
			largestTeam = i;
		}
	}

	return largestTeam;
}

shared int getTeamDifference(BaseTeamInfo@[]@ teams)
{
	s32 lowestCount = getTeamSize(teams, getSmallestTeam(teams));
	s32 highestCount = getTeamSize(teams, getLargestTeam(teams));

	return (highestCount - lowestCount);
}

#endif
