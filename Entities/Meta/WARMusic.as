// Game Music

#define CLIENT_ONLY

#include "RulesCore.as";
#include "HolidaySprites.as";

string 	KAGWorld1_1a_file_name, KAGWorld1_2a_file_name, KAGWorld1_3a_file_name, KAGWorld1_4a_file_name, KAGWorld1_5a_file_name, KAGWorld1_6a_file_name, 
		KAGWorld1_7a_file_name, KAGWorld1_8a_file_name, KAGWorld1_9a_file_name, KAGWorld1_10a_file_name, KAGWorld1_11a_file_name, KAGWorld1_12a_file_name, 
		KAGWorld1_13_file_name, KAGWorld1_14_file_name;

enum GameMusicTag
{
	world_ambient_start,

	world_ambient,
	world_ambient_underground,
	world_ambient_mountain,
	world_ambient_night,

	world_ambient_end,

	world_music_start,

	world_intro,
	world_home,
	world_calm,
	world_battle,
	world_battle_2,
	world_outro,
	world_quick_out,

	world_music_end,
};

string base_blob_name = "hall";

void onInit(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	mixer.ResetMixer();
	this.set_bool("initialized game", false);

	CRules@ rules = getRules();
	if (rules !is null)
	{
		if (rules.exists("music - base name"))
		{
			base_blob_name = rules.get_string("music - base name");
		}
	}
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
	
	KAGWorld1_1a_file_name = getHolidayVersionFileName("KAGWorld1-1a", "ogg");
	KAGWorld1_2a_file_name = getHolidayVersionFileName("KAGWorld1-2a", "ogg");
	KAGWorld1_3a_file_name = getHolidayVersionFileName("KAGWorld1-3a", "ogg");
	KAGWorld1_4a_file_name = getHolidayVersionFileName("KAGWorld1-4a", "ogg");
	KAGWorld1_5a_file_name = getHolidayVersionFileName("KAGWorld1-5a", "ogg");
	KAGWorld1_6a_file_name = getHolidayVersionFileName("KAGWorld1-6a", "ogg");	
	KAGWorld1_7a_file_name = getHolidayVersionFileName("KAGWorld1-7a", "ogg");
	KAGWorld1_8a_file_name = getHolidayVersionFileName("KAGWorld1-8a", "ogg");
	KAGWorld1_9a_file_name = getHolidayVersionFileName("KAGWorld1-9a", "ogg");
	KAGWorld1_10a_file_name = getHolidayVersionFileName("KAGWorld1-10a", "ogg");
	KAGWorld1_11a_file_name = getHolidayVersionFileName("KAGWorld1-11a", "ogg");
	KAGWorld1_12a_file_name = getHolidayVersionFileName("KAGWorld1-12a", "ogg");
	KAGWorld1_13_file_name = isChristmas() ? "KAGWorld1-13Christmas.ogg" : "KAGWorld1-13+Intro.ogg";
	KAGWorld1_14_file_name = getHolidayVersionFileName("KAGWorld1-14", "ogg");
	
	mixer.AddTrack("Sounds/Music/ambient_forest.ogg", world_ambient);
	mixer.AddTrack("Sounds/Music/ambient_mountain.ogg", world_ambient_mountain);
	mixer.AddTrack("Sounds/Music/ambient_cavern.ogg", world_ambient_underground);
	mixer.AddTrack("Sounds/Music/ambient_night.ogg", world_ambient_night);
	mixer.AddTrack("Sounds/Music/KAGWorldIntroShortA.ogg", world_intro);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_1a_file_name, world_home);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_2a_file_name, world_home);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_3a_file_name, world_home);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_4a_file_name, world_home);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_5a_file_name, world_calm);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_6a_file_name, world_calm);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_7a_file_name, world_calm);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_8a_file_name, world_calm);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_9a_file_name, world_home);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_10a_file_name, world_battle);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_11a_file_name, world_battle);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_12a_file_name, world_battle);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_13_file_name, world_battle_2);
	mixer.AddTrack("Sounds/Music/" + KAGWorld1_14_file_name, world_battle_2);
	mixer.AddTrack("Sounds/Music/KAGWorldQuickOut.ogg", world_quick_out);
}

uint timer = 0;
bool wasgame = false;

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	timer++;
	if (mixer is null || !s_gamemusic)
		return;

	CRules @rules = getRules();
	CBlob @blob = getLocalPlayerBlob();
	if (blob is null)
	{
		mixer.FadeOutAll(0.0f, 6.0f);
		return;
	}

	CMap@ map = blob.getMap();
	if (map is null)
		return;

	Vec2f pos = blob.getPosition();

	//calc ambience
	if (timer % 30 == 0)
	{
		bool isNight = map.getDayTime() > 0.75f;
		bool isUnderground = map.rayCastSolid(pos, Vec2f(pos.x, pos.y - 60.0f));
		if (isUnderground)
		{
			changeAmbience(mixer, world_ambient_underground, 4.0f, 4.0f);
		}
		else if (pos.y < map.tilemapheight * map.tilesize * 0.2f) // top one fifth of map is windy
		{
			changeAmbience(mixer, world_ambient_mountain, 4.0f, 4.0f);
		}
		else if (isNight)
		{
			changeAmbience(mixer, world_ambient_night, 4.0f, 4.0f);
		}
		else
		{
			changeAmbience(mixer, world_ambient, 4.0f, 4.0f);
		}
	}

	if (rules.isWarmup())
	{
		wasgame = false;
		changeMusic(mixer, world_home);
	}
	//every beat, checks situation for appropriate music
	else if (rules.isMatchRunning())
	{
		if (!wasgame)
		{
			Sound::Play("/fanfare_start.ogg");
		}

		wasgame = true;
		if (playingMusic(mixer) == 0)
		{
			GameMusicTag chosen = world_calm;

			//check blobs around player for various traits
			CBlob@[] bases;
			getBlobsByName(base_blob_name, @bases);
			for (uint i = 0; i < bases.length; i++)
			{
				CBlob @base = bases[i];
				if (base !is null)
				{
					if (base.getDistanceTo(blob) < 400.0f)
					{
						if (base.getTeamNum() == 255) //skip neutral bases
							continue;

						if (base.getTeamNum() != blob.getTeamNum())
							chosen = world_battle;
						else if (chosen != world_battle) //home if we're not within range of battle
							chosen = world_home;
					}
				}
			}

			changeMusic(mixer, chosen);
			timer = 0;
		}
	}
	else //end of game, fade out music
	{
		wasgame = false;
		if (mixer.getPlayingCount() >= 0)
		{
			mixer.FadeOutAll(0.0f, 0.5f);
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

// handle fadeouts / fadeins dynamically
void changeAmbience(CMixer@ mixer, int nextTrack, f32 fadeoutTime = 0.0f, f32 fadeinTime = 0.0f)
{
	if (!mixer.isPlaying(nextTrack))
	{
		for (u32 i = world_ambient_start + 1; i < world_ambient_end; i++)
			mixer.FadeOut(i, fadeoutTime);
	}

	mixer.FadeInRandom(nextTrack, fadeinTime);
}
