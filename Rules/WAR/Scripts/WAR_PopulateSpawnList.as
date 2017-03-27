// get trading posts for WAR

#include "HallCommon.as"

shared void PopulateSpawnList(CBlob@[]@ respawns, const int teamNum, bool takeUnderRaid = false)
{
	CBlob@[] posts;
	getBlobsByTag("respawn", @posts);
	getBlobsByTag("bed", @posts);

	for (uint i = 0; i < posts.length; i++)
	{
		CBlob@ blob = posts[i];

		if (blob.getTeamNum() == teamNum
		        && !isHallDepleted(blob)
		        && (takeUnderRaid || !isUnderRaid(blob))
		   )
		{
			respawns.push_back(blob);
		}
	}
}
