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
		wink,
		cool,
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
		clap,

		emotes_total,
		off
	};

	//careful to keep these in sync!
	const string[] names = {
		"skull", // in wheel by default
		"blueflag", // in wheel by default
		"note", // in wheel by default
		"right", // in wheel by default
		"smile", // in wheel by default
		"redflag", // in wheel by default
		"flex", // in wheel by default
		"down", // in wheel by default
		"frown", // in wheel by default
		"troll", // in wheel by default
		"finger", // in wheel by default
		"left", // in wheel by default
		"mad", // in wheel by default
		"archer", // in wheel by default
		"sweat", // in wheel by default
		"up", // in wheel by default
		"laugh", // in wheel by default
		"knight", // in wheel by default
		"question", // in wheel by default
		"thumbsup", // in wheel by default
		"wat", // in wheel by default
		"builder", // in wheel by default
		"disappoint", // in wheel by default
		"thumbsdown", // in wheel by default
		"drool", //
		"ladder", // in wheel by default
		"attn", // in wheel by default
		"okhand", // in wheel by default
		"cry", // in wheel by default
		"wall", // in wheel by default
		"heart", // in wheel by default
		"fire", // in wheel by default
		"wink", // in wheel by default
		"cool", // in wheel by default
		"dots",
		"cog", // in wheel by default
		"think", // in wheel by default
		"laughcry", // in wheel by default
		"derp", // in wheel by default
		"awkward", // in wheel by default
		"smug", // in wheel by default
		"love", // in wheel by default
		"kiss", // in wheel by default
		"pickup",
		"raised", // in wheel by default
		"clap", // in wheel by default
	};
}

void set_emote(CBlob@ this, u8 emote, int time)
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

