#include "EmotesCommon.as"
#include "WheelMenuCommon.as"

#define CLIENT_ONLY

void onInit(CRules@ rules)
{
	ConfigFile cfg;
	if (!cfg.loadFile("../Cache/EmoteEntries.cfg")
	 && !cfg.loadFile("EmoteEntries.cfg"))
	{
		return;
	}

	WheelMenu@ menu = get_wheel_menu("emotes");
	menu.option_notice = getTranslatedString("Select emote");

	string[] names;
	cfg.readIntoArray_string(names, "emotes");

	if (names.length % 2 != 0)
	{
		error("EmoteEntries.cfg is not in the form of visible_name; token;");
		return;
	}

	for (uint i = 0; i < names.length; i += 2)
	{
		IconWheelMenuEntry entry(names[i+1]);
		entry.visible_name = getTranslatedString(names[i]);
		entry.texture_name = "Emoticons.png";
		entry.frame = Emotes::names.find(names[i+1]);
		entry.frame_size = Vec2f(32.0f, 32.0f);
		entry.offset = Vec2f(0.0f, -4.0f);
		entry.scale = 1.0f;
		menu.entries.push_back(@entry);
	}
}

void onTick(CRules@ rules)
{
	CBlob@ blob = getLocalPlayerBlob();

	if (blob is null) return;

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