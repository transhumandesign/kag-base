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
		clap,

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
		"raised",
		"clap"
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

ConfigFile@ openEmoteBindingsConfig()
{
	ConfigFile cfg = ConfigFile();
	if(!cfg.loadFile("../Cache/EmoteBindings.cfg"))
	{
		// grab the one with defaults from base
		if(!cfg.loadFile("EmoteBindings.cfg"))
		{
			warn("missing default emote binding");
			cfg.add_string("emote_1", "attn");
			cfg.add_string("emote_2", "smile");
			cfg.add_string("emote_3", "frown");
			cfg.add_string("emote_4", "mad");
			cfg.add_string("emote_5", "laugh");
			cfg.add_string("emote_6", "wat");
			cfg.add_string("emote_7", "troll");
			cfg.add_string("emote_8", "disappoint");
			cfg.add_string("emote_9", "ladder");
			cfg.saveFile("EmoteBindings.cfg");

		}

		// write EmoteBinding.cfg to Cache
		cfg.saveFile("EmoteBindings.cfg");

	}

	return cfg;

}

//helper - allow integer entries as well as name entries
u8 read_emote(ConfigFile@ cfg, string name, u8 default_value)
{
	string attempt = cfg.read_string(name, "");
	if (attempt != "")
	{
		//replace quoting and semicolon
		//TODO: how do we not have a string lib for this?
		string[] check_str = {";",   "\"", "\"",  "'",  "'"};
		bool[] check_pos =   {false, true, false, true, false};
		for(int i = 0; i < check_str.length; i++)
		{
			string check = check_str[i];
			if(check_pos[i]) //check front
			{
				if(attempt.substr(0, 1) == check)
				{
					attempt = attempt.substr(1, attempt.size() - 1);
				}
			}
			else //check back
			{
				if(attempt.substr(attempt.size() - 1, 1) == check)
				{
					attempt = attempt.substr(0, attempt.size() - 1);
				}
			}
		}
		//match
		for(int i = 0; i < Emotes::names.length; i++)
		{
			if(attempt == Emotes::names[i])
			{
				return i;
			}
		}

		//fallback to u8 read
		u8 read_val = cfg.read_u8(name, default_value);
		return read_val;
	}
	return default_value;
}
