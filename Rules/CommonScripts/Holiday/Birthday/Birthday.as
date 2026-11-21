// Birthday.as

#include "BirthdayCommon.as";
#include "HolidayCommon.as";

void onInit(CRules@ this)
{
	if (!this.exists(holiday_head_prop))
		this.set_u8(holiday_head_prop, 0);

	if (!this.exists(holiday_head_texture_prop))
		this.set_string(holiday_head_texture_prop, "BirthdayHeads.png");

	if (g_holiday_assets)
	{
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

	Vec2f offset = holiday_blob_offsets[holiday_blobs.find(name)];

	this.getBlob().set_Vec2f(offset_prop, offset);

	this.AddScript("BirthdayBalloons.as");
}
