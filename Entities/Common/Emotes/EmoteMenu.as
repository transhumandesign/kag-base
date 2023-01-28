#include "EmotesCommon.as"
#include "WheelMenuCommon.as"

#define CLIENT_ONLY

void onInit(CRules@ rules)
{
	ConfigFile@ cfg = loadEmoteConfig();
	LoadEmotes(rules, cfg);

	WheelMenu@ menu = get_wheel_menu("emotes");
	menu.option_notice = getTranslatedString("Select emote");

	Emote@[] wheelEmotes = getWheelEmotes(rules, cfg);
	for (uint i = 0; i < wheelEmotes.size(); i++)
	{
		Emote@ emote = wheelEmotes[i];

		IconWheelMenuEntry entry(emote.token);
		entry.visible_name = getTranslatedString(emote.name);
		entry.texture_name = emote.pack.filePath;
		entry.frame = emote.index;
		entry.frame_size = Vec2f(32.0f, 32.0f);
		entry.scale = 1.0f;
		entry.offset = Vec2f(0.0f, -3.0f);
		menu.entries.push_back(@entry);
	}
}

void onTick(CRules@ rules)
{
	CBlob@ blob = getLocalPlayerBlob();

	if (blob is null)
	{
		set_active_wheel_menu(null);
		return;
	}

	WheelMenu@ menu = get_wheel_menu("emotes");

	if (blob.isKeyJustPressed(key_bubbles))
	{
		set_active_wheel_menu(@menu);
	}
	else if (blob.isKeyJustReleased(key_bubbles) && get_active_wheel_menu() is menu)
	{
		WheelMenuEntry@ selected = menu.get_selected();
		set_emote(blob, (selected !is null ? selected.name : ""));
		set_active_wheel_menu(null);
	}
}