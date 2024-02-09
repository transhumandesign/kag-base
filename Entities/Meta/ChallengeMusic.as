// Game Music

#define CLIENT_ONLY

#include "HolidaySprites.as";

string 	KAGWorld1_1a_file_name, KAGWorld1_2a_file_name, KAGWorld1_3a_file_name, KAGWorld1_4a_file_name, KAGWorld1_5a_file_name, KAGWorld1_6a_file_name, 
		KAGWorld1_7a_file_name, KAGWorld1_8a_file_name, KAGWorld1_9a_file_name, KAGWorld1_10a_file_name, KAGWorld1_11a_file_name, KAGWorld1_12a_file_name, 
		KAGWorld1_13_file_name, KAGWorld1_14_file_name;

enum GameMusicTags
{
	world_ambient,
	world_ambient_underground,
	world_ambient_mountain,
	world_ambient_night,
	world_intro,
	world_home,
	world_calm,
	world_battle,
	world_battle_2,
	world_outro,
	world_quick_out,
};

void onInit(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null) { return; } //prevents aids on server

	this.set_bool("initialized game", false);
}

void onTick(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null) { return; } //prevents aids on server

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
	if (mixer is null) { return; }

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

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	timer++;
	if (mixer is null) { return; }

	CRules @rules = getRules();
	CBlob @blob = getLocalPlayerBlob();
	if (blob is null)
	{
		mixer.FadeOutAll(0.0f, 6.0f);
		return;
	}
	CMap@ map = blob.getMap();
	if (map is null) return;
	Vec2f pos = blob.getPosition();

	if (!s_gamemusic || rules.isWarmup())
	{
		if (timer % 48 != 0)
			return;

		bool isNight = map.getDayTime() > 0.85f && map.getDayTime() < 0.1f;
		bool isUnderground = map.rayCastSolid(pos, Vec2f(pos.x, pos.y - 60.0f));
		if (isUnderground)
		{
			changeMusic(mixer, world_ambient_underground, 2.0f, 4.0f);
		}
		else if (pos.y < 312.0f)
		{
			changeMusic(mixer, world_ambient_mountain, 2.0f, 4.0f);
		}
		else if (isNight)
		{
			changeMusic(mixer, world_ambient_night, 2.0f, 4.0f);
		}
		else
		{
			changeMusic(mixer, world_ambient, 2.0f, 4.0f);
		}
	}
	//else if (rules.isBarrier())
	//{
	//  printf("isBarrier");
	//   changeMusic( mixer, world_home );
	//}
	//every beat, checks situation for appropriate music
	else if (rules.isMatchRunning())
	{
		if (mixer.getPlayingCount() == 0)
		{
			changeMusic(mixer, world_battle, 0.01f, 0.01f);
			timer = 0;
		}
		else
		{
			if (timer % 24 != 0)
				return;

			if (mixer.isPlaying(world_ambient) 
				|| mixer.isPlaying(world_ambient_underground) 
				|| mixer.isPlaying(world_ambient_mountain)
				|| mixer.isPlaying(world_ambient_night))
			{
				mixer.FadeOutAll(0.0f, 0.01f);
			}
		}
	}
	else
		mixer.FadeOutAll(0.0f, 6.0f);
}

// handle fadeouts / fadeins dynamically
void changeMusic(CMixer@ mixer, int nextTrack, f32 fadeoutTime = 1.6f, f32 fadeinTime = 1.6f)
{
	if (!mixer.isPlaying(nextTrack))
	{
		mixer.FadeOutAll(0.0f, fadeoutTime);
	}

	mixer.FadeInRandom(nextTrack, fadeinTime);
}
