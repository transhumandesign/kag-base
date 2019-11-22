///////////////////////////////////////////////////////////
// Precache textures
//
//	loading stuff from the textures in script is slow
//	so for now we're pawning it off on load-time
//
//	If you're going to do this for a mod, it's recommended
//	that you make your own copy and add it to the mod's gamemode
//	rather than edit this directly - re-caching stuff doesn't
//	add overhead and it avoids things getting out of sync
//

#include "RunnerTextures.as"

namespace _precache {

	int team_count = 2;
	int skin_count = 1;
	array<string> textures_names = {
		//base armour
		"archer, Archer, 32, 32",
		"knight, Knight, 32, 32",
		"builder, Builder, 32, 32",
		//capes
		"archer_cape, ArcherCape, 32, 32",
		"knight_cape, KnightCape, 32, 32",
		"builder_cape, BuilderCape, 32, 32",
		//gold
		"archer_gold, ArcherGold, 32, 32",
		"knight_gold, KnightGold, 32, 32",
		"builder_gold, BuilderGold, 32, 32"
	};

	void runner_textures()
	{
		for(int i = 0; i < textures_names.length; i++)
		{
			array<string> chunks = textures_names[i].split(", ");
			if(chunks.length < 4) {
				warn("bad texture precache definition: "+textures_names[i]);
				continue;
			}

			Vec2f framesize = Vec2f(parseInt(chunks[2]), parseInt(chunks[3]));

			RunnerTextures@ tex = fetchRunnerTexture(chunks[0], chunks[1]);
			if(tex is null) {
				warn("failed to precache texture: "+textures_names[i]);
				continue;
			}

			tex.Load(framesize);

			//loop gender
			for(int g = 0; g < 2; g++)
			{
				//loop team
				for(int t = 0; t < team_count; t++)
				{
					//loop skin
					for(int s = 0; s < skin_count; s++)
					{
						//get the texture = force precache
						string texname = getRunnerTeamTexture(tex, g, t, s);
						//(debug)
						//print("cached: "+texname);
						if(isServer())
						{
							getNet().server_KeepConnectionsAlive();
						}
					}
				}
			}
		}
	}
}

void PrecacheTextures()
{
	_precache::runner_textures();
}
