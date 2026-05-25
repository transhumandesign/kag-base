// Game Music

#define CLIENT_ONLY

#include "MusicCommon.as";

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

	if (musicAlreadyExists(this))
	{
		this.server_Die();
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}

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
	mixer.AddTrack("Sounds/Music/KAGWorldIntroShortA.ogg", world_intro);
	mixer.AddTrack("Sounds/Music/KAGWorld1-1a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-2a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-3a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-4a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-5a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-6a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-7a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-8a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-9a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-10a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-11a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-12a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-13+Intro.ogg", world_battle_2);
	mixer.AddTrack("Sounds/Music/KAGWorld1-14.ogg", world_battle_2);
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
