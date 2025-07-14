
#define CLIENT_ONLY

bool musicAlreadyExists(CBlob@ this)
{
	CBlob@[] musics;
	getBlobsByName("music", @musics);
	getBlobsByName("ctf_music", @musics);
	getBlobsByName("war_music", @musics);
	getBlobsByName("challenge_music", @musics);
	
	for (uint i = 0; i < musics.length; i++)
	{
		CBlob@ music = musics[i];
		if (music is null || music is this) continue;

		return true;
	}

	return false;
}
