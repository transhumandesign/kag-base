// get spawn points for CTF

shared void PopulateSpawnList(CBlob@[]@ respawns, const int teamNum)
{
	CBlob@[] posts;
	getBlobsByTag("respawn", @posts);

	for (uint i = 0; i < posts.length; i++)
	{
		CBlob@ blob = posts[i];

		if (blob.getTeamNum() == teamNum && !blob.hasTag("under raid"))
		{
			respawns.push_back(blob);
		}
	}
}
