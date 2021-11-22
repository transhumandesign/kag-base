#include "BirthdayCommon.as";

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (blob.exists("birthday activated"))
		return;

	Vec2f offset = Vec2f(blob.getWidth()/2 - 8, -blob.getHeight()/2 - 8);

	if (blob.exists(offset_prop))
		offset += blob.get_Vec2f(offset_prop);

	for (uint i = 0; i < balloon_amount; i++)
	{
		CSpriteLayer@ balloon_layer = this.addSpriteLayer("balloon " + i, "Balloons.png", 16, 16);

		if (balloon_layer !is null)
		{
			Animation@ bAnim = balloon_layer.addAnimation("balloon", 0, false);

			bAnim.AddFrame(i * 2 + XORRandom(2));
			
			balloon_layer.SetAnimation(bAnim);
			balloon_layer.SetRelativeZ(3);
			balloon_layer.SetOffset(offset);
		}
	}

	blob.set_bool("birthday activated", true);
}
