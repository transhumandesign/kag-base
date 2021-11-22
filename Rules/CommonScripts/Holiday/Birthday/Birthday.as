// Birthday.as

#include "BirthdayCommon.as";
#include "HolidayCommon.as";

void onInit(CRules@ this)
{
	if (!this.exists(holiday_head_prop))
		this.set_u8(holiday_head_prop, 0);

	if (!this.exists(holiday_head_texture_prop))
		this.set_string(holiday_head_texture_prop, "BirthdayHeads.png");
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	string name = blob.getName();

	if (holiday_blobs.find(name) == -1)
		return;

	CSprite@ sprite = blob.getSprite();

	if (sprite is null)
		return;

	Vec2f offset = Vec2f_zero;
	if (name == "chicken")
	{
		offset.x += 2.0f;
		offset.y += 8.0f;
	}

	blob.set_Vec2f(offset_prop, offset);

	sprite.AddScript("BirthdayAddon.as");
}