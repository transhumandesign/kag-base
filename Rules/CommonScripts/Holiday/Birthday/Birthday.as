// Birthday.as

#include "BirthdayCommon.as";
#include "HolidayCommon.as";

void onInit(CRules@ this)
{
	if (!this.exists(holiday_head_prop))
		this.set_u8(holiday_head_prop, 0);

	if (!this.exists(holiday_head_texture_prop))
		this.set_string(holiday_head_texture_prop, "BirthdayHeads.png");

	// Also add balloons to map-initiated blobs
	CBlob@[] blobs;
	for (u8 i = 0; i < holiday_blobs.length(); i++)
	{
		getBlobsByName(holiday_blobs[i], @blobs);
	}

	for (u8 i = 0; i < blobs.length(); i++)
	{
		CBlob@ b = blobs[i];
		AddBalloons(b.getSprite(), b.getName());
	}
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	string name = blob.getName();

	if (holiday_blobs.find(name) == -1)
		return;

	AddBalloons(blob.getSprite(), name);
}

void AddBalloons(CSprite@ this, string name)
{	
	if (this is null)
		return;

	Vec2f offset = Vec2f_zero;
	if (name == "chicken")
	{
		offset.x += 2.0f;
		offset.y += 8.0f;
	}

	this.getBlob().set_Vec2f(offset_prop, offset);

	this.AddScript("BirthdayAddon.as");
}
