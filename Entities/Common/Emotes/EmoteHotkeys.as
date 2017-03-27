
#include "EmotesCommon.as";

bool init = false;
u8 emote_1 = 0;
u8 emote_2 = 0;
u8 emote_3 = 0;
u8 emote_4 = 0;
u8 emote_5 = 0;
u8 emote_6 = 0;
u8 emote_7 = 0;
u8 emote_8 = 0;
u8 emote_9 = 0;

const string emote_config_file = "EmoteBindings.cfg";

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

	if (!init)
	{
		init = true; 	//only load the cfg once to avoid
		//too much file access!

		ConfigFile cfg = ConfigFile();
		cfg.loadFile(emote_config_file);

		emote_1 = cfg.read_u8("emote_1", Emotes::attn);
		emote_2 = cfg.read_u8("emote_2", Emotes::smile);
		emote_3 = cfg.read_u8("emote_3", Emotes::frown);
		emote_4 = cfg.read_u8("emote_4", Emotes::mad);
		emote_5 = cfg.read_u8("emote_5", Emotes::laugh);
		emote_6 = cfg.read_u8("emote_6", Emotes::wat);
		emote_7 = cfg.read_u8("emote_7", Emotes::troll);
		emote_8 = cfg.read_u8("emote_8", Emotes::disappoint);
		emote_9 = cfg.read_u8("emote_9", Emotes::ladder);
	}
}

void onTick(CBlob@ this)
{
	CControls@ controls = getControls();
	if (controls.isKeyJustPressed(KEY_KEY_1))
	{
		set_emote(this, emote_1);
	}
	else if (controls.isKeyJustPressed(KEY_KEY_2))
	{
		set_emote(this, emote_2);
	}
	else if (controls.isKeyJustPressed(KEY_KEY_3))
	{
		set_emote(this, emote_3);
	}
	else if (controls.isKeyJustPressed(KEY_KEY_4))
	{
		set_emote(this, emote_4);
	}
	else if (controls.isKeyJustPressed(KEY_KEY_5))
	{
		set_emote(this, emote_5);
	}
	else if (controls.isKeyJustPressed(KEY_KEY_6))
	{
		set_emote(this, emote_6);
	}
	else if (controls.isKeyJustPressed(KEY_KEY_7))
	{
		set_emote(this, emote_7);
	}
	else if (controls.isKeyJustPressed(KEY_KEY_8))
	{
		set_emote(this, emote_8);
	}
	else if (controls.isKeyJustPressed(KEY_KEY_9))
	{
		set_emote(this, emote_9);
	}
}
