shared class Crate
{
	string name;
	u8 frame;
	Vec2f space;
	u16 gold;
	string[] tags;
	
	Crate(const string &in name, const u8 &in frame, const Vec2f &in space, const u16 &in gold = 0, const string &in tags = "")
	{
		this.name = name;
		this.frame = frame;
		this.space = space;
		this.gold = gold;
		this.tags = tags.split("\\"); //hack
	}
}

bool hasSomethingPacked(CBlob @this)
{
	return (this.exists("packed") && this.get_string("packed").size() > 0);
}

bool hasPacked(CBlob @this, const string &in name)
{
	return (this.exists("packed") && this.get_string("packed") == name);
}

void SetCratePacked(CBlob @this, const string &in blobName, const string &in inventoryName, const u8 frameIndex)
{
	this.set_string("packed", blobName);
	this.set_string("packed name", inventoryName);
	this.set_u8("frame", frameIndex);
}