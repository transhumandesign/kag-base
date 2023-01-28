// CTF Game Music

#define CLIENT_ONLY

const string[] classList = {"knight", "archer", "builder"};
const string[] blobList = {"knight", "archer", "builder", "ballista", "tunnel", "keg"};

enum GameMusicTag
{
	world_ambient,

	world_music_start,

	world_ambient_underground,
	world_ambient_mountain,
	world_intro,
	world_home,
	world_calm,
	world_battle,
	world_outro,

	world_music_end,
};

void onInit(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	mixer.ResetMixer();
	this.set_bool("initialized game", false);

	this.getCurrentScript().tickFrequency = 10;
}

void onTick(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	if (s_soundon != 0 && s_musicvolume > 0.0f)
	{
		if (!this.get_bool("initialized game"))
		{
			AddGameMusic(this, mixer);
		}

		GameMusicLogic(this, mixer);
	}
	else
	{
		mixer.FadeOutAll(0.0f, 2.0f);
	}
}

//sound references with tag
void AddGameMusic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	this.set_bool("initialized game", true);
	mixer.ResetMixer();
	mixer.AddTrack("Sounds/Music/ambient_forest.ogg", world_ambient);
	mixer.AddTrack("Sounds/Music/ambient_mountain.ogg", world_ambient_mountain);
	mixer.AddTrack("Sounds/Music/ambient_cavern.ogg", world_ambient_underground);
	mixer.AddTrack("Sounds/Music/KAGWorldIntroShortA.ogg", world_intro);
	mixer.AddTrack("Sounds/Music/KAGWorld1-1a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-2a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-3a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-4a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-5a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-6a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-7a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-8a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-9a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-10a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-11a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-12a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-13.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-14.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-14outro.ogg", world_outro);
}

u8 battle_timer = 0;
u8 battle_delay = 5; // seconds
bool gameStarted = true;

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null || !s_gamemusic)
		return;

	if (mixer.isPlaying(world_battle))
	{
		battle_timer++;
		battle_timer = battle_timer % (battle_delay * getTicksASecond());
	}

	CRules @rules = getRules();
	CBlob @blob = getLocalPlayerBlob();
	CPlayer @player = getLocalPlayer();

	// Stop music if we're unable to reference either player's blob or player instance. 
	if (blob is null && 
		( player is null || player.getTeamNum() != getRules().getSpectatorTeamNum()))
	{
		mixer.FadeOutAll(0.0f, 6.0f);
		return;
	}

	CMap@ map = getMap();
	if (map is null)
		return;

	if (rules.isWarmup())
	{
		gameStarted = false;

		Vec2f pos; 
		
		// If the player is a spectating, base their location off of their camera.
		if (player.getTeamNum() == getRules().getSpectatorTeamNum())
		{
			pos = getCamera().getPosition();
		}
		else 
		{
			pos = blob.getPosition();
		}

		bool isUnderground = checkUnderground(pos, map);
		if (isUnderground)
		{
			changeMusic(mixer, world_ambient_underground, 2.0f, 2.0f);
			toggleAmbience(mixer, false, 1.0f);
		}
		else if (pos.y < map.tilemapheight * map.tilesize * 0.2f)
		{
			changeMusic(mixer, world_ambient_mountain, 2.0f, 2.0f);
			toggleAmbience(mixer, false, 1.0f);
		}
		else
		{
			changeMusic(mixer, world_home, 2.0f, 2.0f);
			toggleAmbience(mixer, true, 1.0f);
		}
	}
	else if (rules.isMatchRunning())
	{
		if (!gameStarted)
		{
			Sound::Play("/fanfare_start.ogg");
		}

		gameStarted = true;
		if (!mixer.isPlaying(world_battle) || battle_timer == getTicksASecond() * 5) // hold onto battle music at least 5 seconds
		{
			Vec2f pos;

			// If the player is a spectating, base their location off of their camera.
			if (player.getTeamNum() == getRules().getSpectatorTeamNum())
			{
				pos = getCamera().getPosition();
			}
			else
			{
				pos = blob.getPosition();
			}

			GameMusicTag chosen = world_calm;

			// check for ambience -- priority
			bool isUnderground = checkUnderground(pos, map);
			if (isUnderground)
			{
				chosen = world_ambient_underground;
				toggleAmbience(mixer, false, 1.0f);
			}
			else if (pos.y < map.tilemapheight * map.tilesize * 0.2f)
			{
				chosen = world_ambient_mountain;
				toggleAmbience(mixer, false, 1.0f);
			}
			else
			{
				toggleAmbience(mixer, true, 1.0f);

				CMap@ map = getMap();

				const f32 mapWidth = map.tilemapwidth * map.tilesize;
				const f32 teamAreaWidth = mapWidth * 0.3;

				u8 team_num = player.getTeamNum();

				if (pos.x <= teamAreaWidth) // left side of map
				{
					chosen = (team_num == 0 ? world_home : world_battle);
				}
				else if (pos.x >= mapWidth - teamAreaWidth) // right side of map
				{
					chosen = (team_num == 1 ? world_home : world_battle);
				}
				else // mid
				{
					chosen = world_calm;
				}
			}

			if (chosen != world_battle) // below starts more "heavy" checks -> no need to execute this if we are already on battle theme
			{
				CBlob@[] flagBases;
				if (getBlobsByName("flag_base", @flagBases))
				{
					for (uint i = 0; i < flagBases.length; i++)
					{
						CBlob @b = flagBases[i];
						if (!b.hasAttached())
						{
							chosen = world_battle;
							break;
						}
					}
				}

				if (chosen == world_battle)
				{
					CBlob@[] blobsInRadius;
					if (map.getBlobsInRadius(pos, 48.0f, @blobsInRadius))
					{
						for (uint i = 0; i < blobsInRadius.length; i++)
						{
							CBlob @b = blobsInRadius[i];
							if (blobList.find(b.getConfig()) >= 0)
							{

								if (b.getConfig() == "keg" && !b.hasTag("exploding")) // only exploding kegs
									continue;

								if (classList.find(b.getConfig()) >= 0 && b.hasTag("dead")) // skip corpses
									continue;

								chosen = world_battle;
								break;
							}
						}
					}
				}
			}

			if (!mixer.isPlaying(chosen))
			{
				changeMusic(mixer, chosen, 2.0f, 2.0f);

				battle_timer = 0;
			}
		}
	}
	else //end of game, fade out music
	{
		toggleAmbience(mixer, false, 1.0f);

		if (playingMusic(mixer) > 0)
		{
			changeMusic(mixer, world_outro, 0.25f, 0.25f);
		}
		else
		{
			mixer.FadeOutAll(0.0f, 4.0f);
		}
	}
}

// handle fadeouts / fadeins dynamically
void changeMusic(CMixer@ mixer, int nextTrack, f32 fadeoutTime = 0.0f, f32 fadeinTime = 0.0f)
{
	if (!mixer.isPlaying(nextTrack))
	{
		for (u32 i = world_music_start + 1; i < world_music_end; i++)
			mixer.FadeOut(i, fadeoutTime);
	}

	mixer.FadeInRandom(nextTrack, fadeinTime);
}

u32 playingMusic(CMixer@ mixer)
{
	u32 count = 0;
	for (u32 i = world_music_start + 1; i < world_music_end; i++)
		count += mixer.isPlaying(i) ? 1 : 0;

	return count;
}

void toggleAmbience(CMixer@ mixer, bool turnOn, f32 fadeTime = 0.0f)
{
	if (turnOn && !mixer.isPlaying(world_ambient))
		mixer.FadeInRandom(world_ambient, fadeTime);
	else
		mixer.Stop(world_ambient);
}

bool checkUnderground(Vec2f pos, CMap@ map)
{
	return (map.getTile(pos).dirt > 0 &&
		map.getTile(pos + Vec2f(-8, -8)).dirt > 0 &&
		map.getTile(pos + Vec2f(8, -8)).dirt > 0 &&
		map.getTile(pos + Vec2f(-8, 8)).dirt > 0 &&
		map.getTile(pos + Vec2f(8, 8)).dirt > 0);
}
