
#include "EmotesCommon.as";

string[] emoteBinds;
const string emote_config_file = "EmoteBindings.cfg";

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

	this.addCommandID("prevent emotes");

	emoteBinds = readEmoteBindings();
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

	for (uint i = 0; i < 9; i++)
	{
		if (controls.isKeyJustPressed(KEY_NUMPAD1 + i))
		{
			set_emote(this, emoteBinds[9 + i]);
			break;
		}
	}

	if (controls.ActionKeyPressed(AK_BUILD_MODIFIER))
	{
		return;
	}

	for (uint i = 0; i < 9; i++)
	{
		if (controls.isKeyJustPressed(KEY_KEY_1 + i))
		{
			set_emote(this, emoteBinds[i]);
			break;
		}
	}
}
