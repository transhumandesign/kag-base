const string HELPS_ARRAY = "helps array";

shared class HelpText
{
	string name;
	string recipient;
	string text;
	string altText;
	u32 reduceAfterTimes;
	// rendering
	u32 usedCount;
	f32	fadeOut;
	Vec2f drawSize;
	bool showAlways;

	HelpText()
	{
		usedCount = 0;
		fadeOut = 1.0f;
	}
};

// altText - when not recipient
HelpText@ SetHelp(CBlob@ this, const string &in name, const string &in recipient, const string &in text, const string &in altText = "", bool showAlways = false)
{
	if (!getNet().isClient())
		return null;

	if (!this.exists(HELPS_ARRAY))
	{
		HelpText[] helps;
		this.set(HELPS_ARRAY, helps);
	}
	HelpText@ old = getHelpText(this, name, text);
	if (old !is null) // same thing again
		return old;

	HelpText ht;
	ht.name = name;
	ht.recipient = recipient;
	ht.text = text;
	ht.altText = altText;
	ht.reduceAfterTimes = 1;
	ht.showAlways = showAlways;
	this.push(HELPS_ARRAY, ht);

	HelpText@ p_ref;
	this.getLast(HELPS_ARRAY, @p_ref);
	return p_ref;
}

HelpText@ SetHelp(CBlob@ this, const string &in name, const string &in recipient, const string &in text, const string &in altText, const u32 reduceAfterTimes, bool showAlways = false)
{
	if (!getNet().isClient())
		return null;

	if (!this.exists(HELPS_ARRAY))
	{
		HelpText[] helps;
		this.set(HELPS_ARRAY, helps);
	}
	HelpText@ old = getHelpText(this, name, text);
	if (old !is null) // same thing again
		return old;

	HelpText ht;
	ht.name = name;
	ht.recipient = recipient;
	ht.text = text;
	ht.altText = altText;
	ht.reduceAfterTimes = reduceAfterTimes;
	ht.showAlways = showAlways;
	this.push(HELPS_ARRAY, ht);

	HelpText@ p_ref;
	this.getLast(HELPS_ARRAY, @p_ref);
	return p_ref;
}

HelpText[]@ getHelps(CBlob@ this)
{
	HelpText[]@ helps;
	this.get(HELPS_ARRAY, @helps);
	return helps;
}

HelpText@ getHelpText(CBlob@ this, const string &in name)
{
	HelpText[]@ helps = getHelps(this);
	if (helps is null)
		return null;

	for (uint i = 0; i < helps.length; i++)
	{
		HelpText@ ht = helps[i];
		if (ht.name == name)
		{
			return ht;
		}
	}
	return null;
}

HelpText@ getHelpText(CBlob@ this, const string &in name, const string &in description)
{
	HelpText[]@ helps = getHelps(this);
	if (helps is null)
		return null;

	for (uint i = 0; i < helps.length; i++)
	{
		HelpText@ ht = helps[i];
		if (ht.name == name && ht.text == description)
		{
			return ht;
		}
	}
	return null;
}

HelpText@ getHelpTextWithRecipient(CBlob@ this, const string &in name, const string &in recipient)
{
	HelpText[]@ helps = getHelps(this);
	if (helps is null)
		return null;

	for (uint i = 0; i < helps.length; i++)
	{
		HelpText@ ht = helps[i];
		if (ht.name == name && (ht.recipient.size() == 0 || ht.recipient == recipient))
		{
			return ht;
		}
	}
	return null;
}

bool hasHelp(CBlob@ this, const string &in name)
{
	return getHelpText(this, name) !is null;
}

void RemoveHelps(CBlob@ this, const string &in name)
{
	if (!getNet().isClient())
		return;

	HelpText[]@ helps =  getHelps(this);
	if (helps !is null)
	{
		for (uint i = 0; i < helps.length; i++)
		{
			HelpText@ ht = helps[i];
			if (ht.name == name)
			{
				helps.erase(i);
				i = 0;
			}
		}
	}
}
