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