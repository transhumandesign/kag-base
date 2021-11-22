// Birthday.as

#include "BirthdayCommon.as"

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