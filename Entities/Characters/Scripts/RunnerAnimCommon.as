#include "EmotesCommon.as";

void defaultIdleAnim(CSprite@ this, CBlob@ blob, int direction)
{
	if (blob.isKeyPressed(key_down))
	{
		this.SetAnimation("crouch");
		blob.Tag("crouch dodge");
	}
	else if (is_emote(blob, 255, true))
	{
		this.SetAnimation("point");
		this.animation.frame = 1 + direction;
	}
	else
	{
		this.SetAnimation("default");
	}
}
