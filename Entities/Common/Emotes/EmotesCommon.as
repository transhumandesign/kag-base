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

	this.set("emote packs", @packsDict);
	this.set("emotes", @emotesDict);
}

Emote@[] getWheelEmotes(CRules@ this, ConfigFile@ cfg)
{
	Emote@[] wheelEmotes;

	dictionary@ emotes;
	this.get("emotes", @emotes);

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
		dictionary@ emotes;
		if (getRules().get("emotes", @emotes))
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
			set_emoteByCommand(this, token);
			set_emoteByCommand(inventoryblob, token);
		}
	}
	else
	{
		set_emote(this, token, 90);
	}
}

void set_emoteByCommand(CBlob@ this, string token, int time = 90)
{
	CBitStream params;
	params.write_string(token);
	params.write_u32(getGameTime() + time);
	this.SendCommand(this.getCommandID("emote"), params);
}

bool is_emote(CBlob@ this, bool checkBlank = false)
{
	string token = this.get_string("emote");
	u32 time = this.get_u32("emotetime");

	return time > getGameTime() && token != "" && (!checkBlank || (token != "dots")) && !isIgnored(this.getPlayer());
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
string read_emote(ConfigFile@ cfg, const dictionary &in emotes, CPlayer@ player, const string &in name, const string &in default_value)
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

		if (emotes.get(attempt, @emote) && canUseEmote(player, emote))
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

string[] readEmoteBindings(CPlayer@ player)
{
	ConfigFile@ cfg = openEmoteBindingsConfig();

	dictionary@ emotes;
	getRules().get("emotes", @emotes);

	string[] emoteBinds = {
		read_emote(cfg, emotes, player, "emote_1", "attn"),
		read_emote(cfg, emotes, player, "emote_2", "smile"),
		read_emote(cfg, emotes, player, "emote_3", "frown"),
		read_emote(cfg, emotes, player, "emote_4", "mad"),
		read_emote(cfg, emotes, player, "emote_5", "laugh"),
		read_emote(cfg, emotes, player, "emote_6", "wat"),
		read_emote(cfg, emotes, player, "emote_7", "troll"),
		read_emote(cfg, emotes, player, "emote_8", "disappoint"),
		read_emote(cfg, emotes, player, "emote_9", "ladder"),
		read_emote(cfg, emotes, player, "emote_10", "flex"),
		read_emote(cfg, emotes, player, "emote_11", "down"),
		read_emote(cfg, emotes, player, "emote_12", "smug"),
		read_emote(cfg, emotes, player, "emote_13", "left"),
		read_emote(cfg, emotes, player, "emote_14", "okhand"),
		read_emote(cfg, emotes, player, "emote_15", "right"),
		read_emote(cfg, emotes, player, "emote_16", "thumbsup"),
		read_emote(cfg, emotes, player, "emote_17", "up"),
		read_emote(cfg, emotes, player, "emote_18", "thumbsdown")
	};

	return emoteBinds;
}

bool canUseEmote(CPlayer@ player, Emote@ emote)
{
	string[] excluded = {
		"dots",
		"pickup"
	};

	//emote excluded
	if (excluded.find(emote.token) > -1) return false;

	//thd privilege >:)
	if (player.isDev()) return true;

	bool patreonEmote = emote.pack.token == "patreon";
	bool patron = player.getSupportTier() != SUPPORT_TIER_NONE;

	return (
		//show patreon emote to patron
		(!patreonEmote || patron)
	);
}

bool isIgnored(CPlayer@ player)
{
	return player !is null && getSecurity().isPlayerIgnored(player);
}

Emote@[] getUsableEmotes(CPlayer@ player)
{
	Emote@[] usableEmotes;

	dictionary@ emotes;
	getRules().get("emotes", @emotes);
	string[] tokens = emotes.getKeys();

	for (uint i = 0; i < tokens.size(); i++)
	{
		Emote@ emote;
		emotes.get(tokens[i], @emote);

		if (canUseEmote(player, emote))
		{
			usableEmotes.push_back(emote);
		}
	}

	return usableEmotes;
}
