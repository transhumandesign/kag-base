
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

u8 emote_10 = Emotes::flex;
u8 emote_11 = Emotes::down;
u8 emote_12 = Emotes::smug;
u8 emote_13 = Emotes::left;
u8 emote_14 = Emotes::okhand;
u8 emote_15 = Emotes::right;
u8 emote_16 = Emotes::thumbsup;
u8 emote_17 = Emotes::up;
u8 emote_18 = Emotes::thumbsdown;

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

	emote_10 = read_emote(cfg, "emote_10", Emotes::flex);
	emote_11 = read_emote(cfg, "emote_11", Emotes::down);
	emote_12 = read_emote(cfg, "emote_12", Emotes::smug);
	emote_13 = read_emote(cfg, "emote_13", Emotes::left);
	emote_14 = read_emote(cfg, "emote_14", Emotes::okhand);
	emote_15 = read_emote(cfg, "emote_15", Emotes::right);
	emote_16 = read_emote(cfg, "emote_16", Emotes::thumbsup);
	emote_17 = read_emote(cfg, "emote_17", Emotes::up);
	emote_18 = read_emote(cfg, "emote_18", Emotes::thumbsdown);

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
	if (this.hasTag("reload emotes"))
	{
		this.Untag("reload emotes");
		onInit(this);
	}

	CControls@ controls = getControls();

	if (controls.isKeyJustPressed(KEY_NUMPAD1))
	{
		set_emote(this, emote_10);
	}
	else if (controls.isKeyJustPressed(KEY_NUMPAD2))
	{
		set_emote(this, emote_11);
	}
	else if (controls.isKeyJustPressed(KEY_NUMPAD3))
	{
		set_emote(this, emote_12);
	}
	else if (controls.isKeyJustPressed(KEY_NUMPAD4))
	{
		set_emote(this, emote_13);
	}
	else if (controls.isKeyJustPressed(KEY_NUMPAD5))
	{
		set_emote(this, emote_14);
	}
	else if (controls.isKeyJustPressed(KEY_NUMPAD6))
	{
		set_emote(this, emote_15);
	}
	else if (controls.isKeyJustPressed(KEY_NUMPAD7))
	{
		set_emote(this, emote_16);
	}
	else if (controls.isKeyJustPressed(KEY_NUMPAD8))
	{
		set_emote(this, emote_17);
	}
	else if (controls.isKeyJustPressed(KEY_NUMPAD9))
	{
		set_emote(this, emote_18);
	}

	if (controls.ActionKeyPressed(AK_BUILD_MODIFIER))
	{
		return;
	}


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
