
#include "EmotesCommon.as";

// set these so they default correctly even if we don't find the file.
string emote_1 = "attn";
string emote_2 = "smile";
string emote_3 = "frown";
string emote_4 = "mad";
string emote_5 = "laugh";
string emote_6 = "wat";
string emote_7 = "troll";
string emote_8 = "disappoint";
string emote_9 = "ladder";

string emote_10 = "flex";
string emote_11 = "down";
string emote_12 = "smug";
string emote_13 = "left";
string emote_14 = "okhand";
string emote_15 = "right";
string emote_16 = "thumbsup";
string emote_17 = "up";
string emote_18 = "thumbsdown";

const string emote_config_file = "EmoteBindings.cfg";

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

	this.addCommandID("prevent emotes");

	//attempt to load from cache first
	ConfigFile@ cfg = openEmoteBindingsConfig();

	dictionary emotes;
	getRules().get("emotes", emotes);

	emote_1 = read_emote(cfg, emotes, "emote_1", "attn");
	emote_2 = read_emote(cfg, emotes, "emote_2", "smile");
	emote_3 = read_emote(cfg, emotes, "emote_3", "frown");
	emote_4 = read_emote(cfg, emotes, "emote_4", "mad");
	emote_5 = read_emote(cfg, emotes, "emote_5", "laugh");
	emote_6 = read_emote(cfg, emotes, "emote_6", "wat");
	emote_7 = read_emote(cfg, emotes, "emote_7", "troll");
	emote_8 = read_emote(cfg, emotes, "emote_8", "disappoint");
	emote_9 = read_emote(cfg, emotes, "emote_9", "ladder");

	emote_10 = read_emote(cfg, emotes, "emote_10", "flex");
	emote_11 = read_emote(cfg, emotes, "emote_11", "down");
	emote_12 = read_emote(cfg, emotes, "emote_12", "smug");
	emote_13 = read_emote(cfg, emotes, "emote_13", "left");
	emote_14 = read_emote(cfg, emotes, "emote_14", "okhand");
	emote_15 = read_emote(cfg, emotes, "emote_15", "right");
	emote_16 = read_emote(cfg, emotes, "emote_16", "thumbsup");
	emote_17 = read_emote(cfg, emotes, "emote_17", "up");
	emote_18 = read_emote(cfg, emotes, "emote_18", "thumbsdown");

}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("prevent emotes"))
	{
		set_emote(this, "");
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
