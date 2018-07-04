//handy dandy frame lookup
namespace Emotes
{
	//note: it's recommended to use the names in-config
	//		for future compatibility; emote indices _may_ get re-ordered
	//		but we will try not to rename emoticons

	enum Emote_Indices
	{
		skull = 0,  //0
		blueflag,
		note,
		right,
		smile,
		redflag,
		flex,
		down,
		frown,
		troll,
		finger,		//10
		left,
		mad,
		archer,
		sweat,
		up,
		laugh,
		knight,
		question,
		thumbsup,
		wat,		//20
		builder,
		disappoint,
		thumbsdown,
		drool,
		ladder,
		attn,
		okhand,
		cry,
		wall,
		heart,		//30
		fire,
		check,
		cross,
		dots,
		cog,
		think,
		laughcry,
		derp,
		awkward,
		smug,       //40
		love,
		kiss,
		pickup,
		raised,

		emotes_total,
		off
	};

	//careful to keep these in sync!
	const string[] names = {
		"skull",
		"blueflag",
		"note",
		"right",
		"smile",
		"redflag",
		"flex",
		"down",
		"frown",
		"troll",
		"finger",
		"left",
		"mad",
		"archer",
		"sweat",
		"up",
		"laugh",
		"knight",
		"question",
		"thumbsup",
		"wat",
		"builder",
		"disappoint",
		"thumbsdown",
		"drool",
		"ladder",
		"attn",
		"okhand",
		"cry",
		"wall",
		"heart",
		"fire",
		"check",
		"cross",
		"dots",
		"cog",
		"think",
		"laughcry",
		"derp",
		"awkward",
		"smug",
		"love",
		"kiss",
		"pickup",
		"raised"
	};
}

void set_emote(CBlob@ this, u8 emote, int time, CBlob@ sender = null)
{
	if (emote >= Emotes::emotes_total)
	{
		emote = Emotes::off;
	}
	this.set_u8("emote", emote);
	this.set_u32("emotetime", getGameTime() + time);

	bool client = this.getPlayer() !is null && this.isMyPlayer();
	this.Sync("emote", !client);
	this.Sync("emotetime", !client);
}

void set_emote(CBlob@ this, u8 emote)
{
	if (this.isInInventory())
	{
		CBlob@ inventoryblob = this.getInventoryBlob();
		if (inventoryblob !is null && inventoryblob.getName() == "crate"
			&& inventoryblob.exists("emote"))
		{
			CBitStream params;
			params.write_u8(emote);
			params.write_u32(getGameTime() + 90);
			inventoryblob.SendCommand(inventoryblob.getCommandID("emote"), params);
			this.SendCommand(this.getCommandID("emote"), params);
		}
	}
	else
	{
		set_emote(this, emote, 90);
	}
}

bool is_emote(CBlob@ this, u8 emote = 255, bool checkBlank = false)
{
	u8 index = emote;
	if (index == 255)
		index = this.get_u8("emote");

	u32 time = this.get_u32("emotetime");

	return time > getGameTime() && index != Emotes::off && (!checkBlank || (index != Emotes::dots));
}

