#include "EmotesCommon.as"
#include "WheelMenuCommon.as"

#define CLIENT_ONLY

void onInit(CRules@ rules)
{
	ConfigFile@ cfg = loadEmoteConfig();
	dictionary emojis = LoadEmojis(cfg);
	Emoji@[] wheelEmojis = getWheelEmojis(cfg, emojis);

	WheelMenu@ menu = get_wheel_menu("emotes");
	menu.option_notice = getTranslatedString("Select emote");

	for (uint i = 0; i < wheelEmojis.size(); i++)
	{
		Emoji@ emoji = wheelEmojis[i];

		IconWheelMenuEntry entry(emoji.token);
		entry.visible_name = getTranslatedString(emoji.name);
		entry.texture_name = emoji.pack.filePath;
		entry.frame = emoji.index;
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
		set_emote(blob, (selected !is null ? Emotes::names.find(selected.name) : Emotes::off));
		set_active_wheel_menu(null);
	}
}