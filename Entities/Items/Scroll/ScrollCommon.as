#include "ShopCommon.as"

// consts for use everywhere scrolls are made - TODO config file

const s32 cost_crappiest = 60;
const s32 cost_crappy 	= 100;
const s32 cost_medium 	= 200;
const s32 cost_big	 	= 300;
const s32 cost_super 	= 500;

//scroll definitions

shared class ScrollDef
{
	string name;
	ShopItem[] items;
	string[] scripts;
	// scroll
	u8 scrollFrame;
	// research
	f32 level;
	f32 tier;
	bool researching;

	u32 timeSecs; // ticks


	string[] connections;

	f32 percent;
	bool special_unlock;

	ScrollDef()
	{
		scrollFrame = 0;
		level = tier = -1.0f;
		timeSecs = 0;
		percent = 0.0f;
		special_unlock = false;

		votes = 0;
		weight = XORRandom(32);
		researching = false;
	}

	bool hasTech() { return percent >= 1.0f || special_unlock; }

	//net stuff

	void Serialise(CBitStream@ stream)
	{
		stream.write_string(name);
		stream.write_f32(level);
		stream.write_f32(tier);
		stream.write_f32(percent);
		stream.write_u32(timeSecs);
		stream.write_bool(researching);
		stream.write_u8(votes);
		stream.write_u8(weight);
		stream.write_bool(special_unlock);
		stream.write_u8(scrollFrame);
		stream.write_u8(connections.length);
		for (uint j = 0; j < connections.length; j++)
		{
			stream.write_string(connections[j]);
		}
	}

	bool Unserialise(CBitStream@ stream)
	{
		u8 len;
		string temp;
		if (!stream.saferead_string(name)) return false;
		if (!stream.saferead_f32(level)) return false;
		if (!stream.saferead_f32(tier)) return false;
		if (!stream.saferead_f32(percent)) return false;
		if (!stream.saferead_u32(timeSecs)) return false;
		if (!stream.saferead_bool(researching)) return false;
		if (!stream.saferead_u8(votes)) return false;
		if (!stream.saferead_u8(weight)) return false;
		if (!stream.saferead_bool(special_unlock)) return false;
		if (!stream.saferead_u8(scrollFrame)) return false;
		if (!stream.saferead_u8(len)) return false;
		for (uint i = 0; i < len; i++)
		{
			if (!stream.saferead_string(temp)) return false; connections.push_back(temp);
		}

		return true;
	}

	//vote stuff

	u8 weight; //random weight for tie breaking
	u8 votes; //no downvoting, so this is a nice compact way to do it.
	string[] usernames; //list of people who have voted this up (so we can toggle)

	void toggleVote(const string &in player)
	{
		if (hasTech()) return; //ignore votes on techs we have

		int index = -1;
		for (uint i = 0; i < usernames.length; i++)
		{
			if (usernames[i] == player)
			{
				index = i;
				break;
			}
		}
		if (index != -1)
		{
			usernames.erase(index);
			votes--;
		}
		else
		{
			usernames.push_back(player);
			votes++;
		}

	}

}

//scroll sets

shared class ScrollSet
{
	dictionary scrolls;
	string[] names;

	ScrollSet() {}
}

shared ScrollSet@ getScrollSet(const string &in name)
{
	ScrollSet@ set;
	getRules().get(name, @set);					//tip: if we dont use SHARED class we will get null in another script!
	return set;
}

shared ScrollDef@ getScrollDef(const string &in setname, const string &in defname)
{
	ScrollSet@ set = getScrollSet(setname);
	if (set !is null)
	{
		ScrollDef@ def;
		set.scrolls.get(defname, @def);
		return def;
	}
	else
		warn("getScrollDef: scroll set not found " + setname);
	return null;
}

shared ScrollDef@ getScrollDef(ScrollSet@ set, const string &in defname)
{
	if (set !is null)
	{
		ScrollDef@ def;
		set.scrolls.get(defname, @def);
		return def;
	}
	else
		warn("getScrollDef: scroll set not found");
	return null;
}

void copyFrom(dictionary@ from, string key, dictionary@ to)
{
	ScrollDef@ temp;
	from.get(key, @temp);
	if (temp !is null)
	{
		to.set(key, temp);
	}
	else
		warn("set " + key + " not found");
}

