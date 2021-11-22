// Birthday.as

const string[] holiday_blobs =
{
	"tent",
	"chicken"
};

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (holiday_blobs.find(blob.getName()))
	{
		CSprite@ sprite = blob.getSprite();

		if (sprite is null)
			return;

		blob.AddScript("BirthdayAddon.as");
	}
}
