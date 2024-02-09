// Game Music

#define CLIENT_ONLY

#include "HolidaySprites.as";

string 	KAGWorld1_1a_file_name, KAGWorld1_2a_file_name, KAGWorld1_3a_file_name, KAGWorld1_4a_file_name, KAGWorld1_5a_file_name, KAGWorld1_6a_file_name, 
		KAGWorld1_7a_file_name, KAGWorld1_8a_file_name, KAGWorld1_9a_file_name, KAGWorld1_10a_file_name, KAGWorld1_11a_file_name, KAGWorld1_12a_file_name, 
		KAGWorld1_13_file_name, KAGWorld1_14_file_name;

enum GameMusicTags
{
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
	if (mixer is null)
		return;

	this.set_bool("initialized game", false);
}

void onTick(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	if (s_gamemusic && s_musicvolume > 0.0f)
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
	if (mixer is null)
		return;

	//warmup
	CRules @rules = getRules();

	if (rules.isWarmup())
	{
		if (mixer.getPlayingCount() == 0)
		{
			mixer.FadeInRandom(world_home , 0.0f);
		}
	}
	else if (rules.isMatchRunning()) //battle music
	{
		if (mixer.getPlayingCount() == 0)
		{
			mixer.FadeInRandom(world_battle , 0.0f);
		}
	}
	else
	{
		mixer.FadeOutAll(0.0f, 1.0f);
	}
}
