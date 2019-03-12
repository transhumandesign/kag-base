
#include "EmotesCommon.as";

// set these so they default correctly even if we don't find the file.
u8 emote_1 = Emotes::attn;
u8 emote_2 = Emotes::smile;
u8 emote_3 = Emotes::frown;
u8 emote_4 = Emotes::mad;
u8 emote_5 = Emotes::laugh;
u8 emote_6 = Emotes::wat;
u8 emote_7 = Emotes::troll;
u8 emote_8 = Emotes::disappoint;
u8 emote_9 = Emotes::ladder;

const string emote_config_file = "EmoteBindings.cfg";

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

	this.addCommandID("prevent emotes");

	//attempt to load from cache first
	ConfigFile@ cfg = openEmoteBindingsConfig();

	emote_1 = read_emote(cfg, "emote_1", Emotes::attn);
	emote_2 = read_emote(cfg, "emote_2", Emotes::smile);
	emote_3 = read_emote(cfg, "emote_3", Emotes::frown);
	emote_4 = read_emote(cfg, "emote_4", Emotes::mad);
	emote_5 = read_emote(cfg, "emote_5", Emotes::laugh);
	emote_6 = read_emote(cfg, "emote_6", Emotes::wat);
	emote_7 = read_emote(cfg, "emote_7", Emotes::troll);
	emote_8 = read_emote(cfg, "emote_8", Emotes::disappoint);
	emote_9 = read_emote(cfg, "emote_9", Emotes::ladder);

}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("prevent emotes"))
	{
		set_emote(this, Emotes::off);
	}
}

void onTick(CBlob@ this)
{
	if(this.hasTag("reload emotes"))
	{
		this.Untag("reload emotes");
		onInit(this);
	}

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
