// functions for building trader menu

#include "MakeScroll.as";
#include "Requirements.as";

shared class TradeItem
{
	string name;
	string iconName;
	u8 iconFrame; // used if iconName = ""
	string configFilename;
	string[] _description;		//build this with AddDescription()
	string final_description;	//caches getDescription()
	CBitStream reqs;
	string scrollName;
	bool instantShipping;
	bool buyIntoInventory;
	u32 unavailableTime;   // ticks
	u32 boughtTime;
	bool prepaidGold;
	u16 paidGold;

	bool isSeparator;
	Vec2f separatorIconSize;


	TradeItem()
	{
		instantShipping = true;
		isSeparator = false;
		buyIntoInventory = false;
		unavailableTime = boughtTime = paidGold = 0;
		prepaidGold = false;
		iconFrame = 0;
	}

	void Serialise(CBitStream@ stream)
	{
		//specialised description handling
		stream.write_s32(_description.length);
		for(int i = 0; i < _description.length; i++)
		{
			stream.write_string(_description[i]);
		}

		stream.write_string(scrollName);
		stream.write_string(name);
		stream.write_string(iconName);
		stream.write_u8(iconFrame);
		stream.write_string(configFilename);
		stream.write_u32(unavailableTime);
		stream.write_u32(boughtTime);
		stream.write_u16(paidGold);
		stream.write_Vec2f(separatorIconSize);

		stream.write_CBitStream(reqs);
		stream.write_bool(instantShipping);
		stream.write_bool(buyIntoInventory);
		stream.write_bool(prepaidGold);
		stream.write_bool(isSeparator);

	}

	bool Unserialise(CBitStream@ stream)
	{
		_description.clear();
		s32 description_size = 0;
		if (!stream.saferead_s32(description_size)) return false;
		while(description_size-- > 0) {
			string s;
			if (!stream.saferead_string(s)) return false;
			AddDescription(s);
		}

		if (!stream.saferead_string(scrollName)) return false;
		if (!stream.saferead_string(name)) return false;
		if (!stream.saferead_string(iconName)) return false;
		if (!stream.saferead_u8(iconFrame)) return false;
		if (!stream.saferead_string(configFilename)) return false;
		if (!stream.saferead_u32(unavailableTime)) return false;
		if (!stream.saferead_u32(boughtTime)) return false;
		if (!stream.saferead_u16(paidGold)) return false;
		if (!stream.saferead_Vec2f(separatorIconSize)) return false;

		if (!stream.saferead_CBitStream(reqs)) return false;
		if (!stream.saferead_bool(instantShipping)) return false;
		if (!stream.saferead_bool(buyIntoInventory)) return false;
		if (!stream.saferead_bool(prepaidGold)) return false;
		if (!stream.saferead_bool(isSeparator)) return false;

		return true;
	}

	void AddDescription(string s)
	{
		_description.push_back(s);
		final_description = "";
	}

	string getDescription()
	{
		if(final_description != "")
		{
			//cached already
			return final_description;
		}

		final_description = "";
		int size = _description.length;
		if(size > 0)
		{
			final_description = _description[0];
			for (int i = 1; i < size; i++)
			{
				string next_sep = (i == (size - 1)) ? "\n\n\n" : "   ";
				final_description = final_description + next_sep + getTranslatedString(_description[i]);
			}
		}
		return final_description;
	}
};

//

void CreateTradeMenu(CBlob@ this, Vec2f menuSlotsSize, const string &in caption)
{
	this.set_Vec2f("trade menu size", menuSlotsSize);
	this.set_string("trade menu caption", caption);
	BuildItemsArrayIfNeeded(this);
}

bool isMenuBuilt(CBlob@ this)
{
	return this.exists("items");
}

void BuildItemsArrayIfNeeded(CBlob@ this)
{
	if (!this.exists("items"))
	{
		TradeItem[] items;
		this.set("items", items);
	}
}

// generic gold item

TradeItem@ addTradeItem(CBlob@ this, const string &in name, int cost, const bool instantShipping, const string &in iconName, const string &in configFilename, const string &in description)
{
	BuildItemsArrayIfNeeded(this);

	TradeItem item;
	item.name = name;
	item.iconName = iconName;
	item.configFilename = configFilename;
	item.AddDescription(description);
	item.instantShipping = instantShipping;
	item.isSeparator = false;
	if (cost > 0)
	{
		AddRequirement(item.reqs, "blob", "mat_gold", "Gold", cost);
	}
	this.push("items", item);
	TradeItem@ p_ref;
	this.getLast("items", @p_ref);
	return p_ref;
}

// scrolls

TradeItem@ addTradeScrollFromScrollDef(CBlob@ this, const string &in name, s32 cost, const string &in description)
{
	ScrollDef@ def = getScrollDef("all scrolls", name);
	if (def !is null)
	{
		BuildItemsArrayIfNeeded(this);

		TradeItem item;
		item.scrollName = name;
		item.name = def.name;
		item.iconName = "$scroll" + def.scrollFrame + "$";
		item.configFilename = "scroll";
		item.iconFrame = def.scrollFrame;
		for (uint i = 0; i < def.items.length; i++)
		{
			item.AddDescription(def.items[i].iconName);
		}
		item.AddDescription(description);
		item.instantShipping = true;
		item.isSeparator = false;
		//item.prepaidGold = true; // stack gold  ITS BUGGY

		item.unavailableTime = getTicksASecond() * 60 * 10;

		AddRequirement(item.reqs, "blob", "mat_gold", "Gold", cost);
		this.push("items", item);
		TradeItem@ p_ref;
		this.getLast("items", @p_ref);
		return p_ref;
	}
	else
	{
		warn("missing scroll def by name: " + name);
		return null;
	}
}

// separators

TradeItem@ addTradeEmptyItem(CBlob@ this, Vec2f iconSize = Vec2f(1, 1))
{
	BuildItemsArrayIfNeeded(this);

	TradeItem item;
	item.isSeparator = true;
	item.separatorIconSize = iconSize;
	this.push("items", item);
	TradeItem@ p_ref;
	this.getLast("items", @p_ref);
	return p_ref;
}

TradeItem@ addTradeSeparatorItem(CBlob@ this, const string &in iconName, Vec2f iconSize)
{
	BuildItemsArrayIfNeeded(this);

	TradeItem item;
	item.isSeparator = true;
	item.iconName = iconName;
	item.separatorIconSize = iconSize;
	this.push("items", item);
	TradeItem@ p_ref;
	this.getLast("items", @p_ref);
	return p_ref;
}

/////////


CBlob@ getPostTrader(CBlob@ post, CBlob@[]@ traders)
{
	for (uint i = 0; i < traders.length; i++)
	{
		CBlob@ trader = traders[i];

		if ((post.getPosition() - trader.getPosition()).getLength() < post.getRadius() + trader.getRadius())
		{
			return trader;
		}
	}

	return null;
}

CBlob@ getPostTrader(CBlob@ post)
{
	CBlob@[] traders;
	getBlobsByName("trader", @traders);

	for (uint i = 0; i < traders.length; i++)
	{
		CBlob@ trader = traders[i];

		if (!trader.hasTag("dead") && (post.getPosition() - trader.getPosition()).getLength() < post.getRadius() + trader.getRadius())
		{
			return trader;
		}
	}

	return null;
}
