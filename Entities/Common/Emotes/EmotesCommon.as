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
		idea,
		mine,
		sorry,
		rat,
		dismayed,  //50


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
		"clap",
		"idea",
		"mine",
		"sorry",
		"rat",
		"dismayed"
	};
}

class EmotePack
{
	string name;
	string token;
	string filePath;
	Emote@[] emotes;

	EmotePack(string name, string token, string filePath)
	{
		this.name = name;
		this.token = token;
		this.filePath = filePath;
	}
}

class Emote
{
	string name;
	string token;
	u8 index;
	EmotePack@ pack;

	Emote(string name, string token, u8 index, EmotePack@ pack)
	{
		this.name = name;
		this.token = token;
		this.index = index;
		@this.pack = pack;
	}
}

void LoadEmotes(CRules@ this, ConfigFile@ cfg)
{
	dictionary emotesDict;
	dictionary packsDict;

	string[] packs;
	cfg.readIntoArray_string(packs, "PACKS");

	if (packs.size() % 3 != 0)
	{
		error("EmoteEntries.cfg PACKS is not in the form of visible_name; token; file_path;");
		return;
	}

	for (uint i = 0; i < packs.size(); i += 3)
	{
		EmotePack pack(packs[i], packs[i + 1], packs[i + 2]);

		string[] emotes;
		cfg.readIntoArray_string(emotes, pack.token);

		if (emotes.size() % 2 != 0)
		{
			error("EmoteEntries.cfg emotes are not in the form of visible_name; token;");
			continue;
		}

		for (uint j = 0; j < emotes.size(); j += 2)
		{
			Emote emote(emotes[j], emotes[j + 1], j / 2, pack);
			pack.emotes.push_back(emote);
			emotesDict.set(emote.token, emote);
		}

		packsDict.set(pack.token, pack);
	}

	this.set("emote packs", packsDict);
	this.set("emotes", emotesDict);
}

Emote@[] getWheelEmotes(CRules@ this, ConfigFile@ cfg)
{
	Emote@[] wheelEmotes;

	dictionary emotes;
	this.get("emotes", emotes);

	string[] data;
	cfg.readIntoArray_string(data, "WHEEL");

	for (uint i = 0; i < data.size(); i++)
	{
		Emote@ emote;
		if (emotes.get(data[i], @emote))
		{
			wheelEmotes.push_back(emote);
		}
	}

	return wheelEmotes;
}

ConfigFile@ loadEmoteConfig()
{
	string filename = "EmoteEntries.cfg";
	string cachefilename = "../Cache/" + filename;
	ConfigFile cfg;

	//attempt to load from cache first
	if (CFileMatcher(cachefilename).getFirst() == cachefilename && cfg.loadFile(cachefilename))
	{
		return cfg;
	}
	else if (cfg.loadFile(filename))
	{
		return cfg;
	}

	return null;
}

Emote@ getEmote(string token)
{
	if (token != "")
	{
		dictionary emotes;
		if (getRules().get("emotes", emotes))
		{
			Emote@ emote;
			if (emotes.get(token, @emote))
			{
				return emote;
			}
		}
	}

	return null;
}

void set_emote(CBlob@ this, string token, int time)
{
	Emote@ emote = getEmote(token);
	if (emote is null)
	{
		token = "";
	}

	this.set_string("emote", token);
	this.set_u32("emotetime", getGameTime() + time);
	bool client = this.getPlayer() !is null && this.isMyPlayer();
	this.Sync("emote", !client);
	this.Sync("emotetime", !client);
}

void set_emote(CBlob@ this, string token)
{
	if (this.isInInventory())
	{
		CBlob@ inventoryblob = this.getInventoryBlob();
		if (inventoryblob !is null && inventoryblob.getName() == "crate"
			&& inventoryblob.exists("emote"))
		{
			CBitStream params;
			params.write_string(token);
			params.write_u32(getGameTime() + 90);
			inventoryblob.SendCommand(inventoryblob.getCommandID("emote"), params);
			this.SendCommand(this.getCommandID("emote"), params);
		}
	}
	else
	{
		set_emote(this, token, 90);
	}
}

bool is_emote(CBlob@ this, bool checkBlank = false)
{
	string token = this.get_string("emote");
	u32 time = this.get_u32("emotetime");

	return time > getGameTime() && token != "" && (!checkBlank || (token != "dots"));
}

ConfigFile@ openEmoteBindingsConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/EmoteBindings.cfg"))
	{
		// grab the one with defaults from base
		if (!cfg.loadFile("EmoteBindings.cfg"))
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
string read_emote(ConfigFile@ cfg, dictionary emotes, string name, string default_value)
{
	Emote@ emote;

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
			if (check_pos[i]) //check front
			{
				if (attempt.substr(0, 1) == check)
				{
					attempt = attempt.substr(1, attempt.size() - 1);
				}
			}
			else //check back
			{
				if (attempt.substr(attempt.size() - 1, 1) == check)
				{
					attempt = attempt.substr(0, attempt.size() - 1);
				}
			}
		}

		if (emotes.get(attempt, @emote))
		{
			return emote.token;
		}
	}
	return default_value;
}

bool isMouseOverEmote(CSpriteLayer@ emote)
{
	Vec2f mousePos = getControls().getMouseWorldPos();
	Vec2f emotePos = emote.getWorldTranslation();

	//approximate dimensions of most emotes
	Vec2f tl = emotePos - Vec2f(8, 5);
	Vec2f br = emotePos + Vec2f(8, 9);

	return (
		mousePos.x >= tl.x && mousePos.y >= tl.y &&
		mousePos.x < br.x && mousePos.y < br.y
	);
}
