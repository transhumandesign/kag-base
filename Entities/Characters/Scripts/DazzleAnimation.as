#include "PixelOffsets.as"
#include "RunnerTextures.as"

void onInit(CSprite@ this)
{
	CSpriteLayer@ stars = this.addSpriteLayer("dazzle stars", "Dazzle.png" , 16, 9, 0, 0);
	if (stars !is null)
	{
		Animation@ anim = stars.addAnimation("default", 3, true);

		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);

		stars.SetVisible(false);
		stars.SetRelativeZ(2.0f);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	CSpriteLayer@ stars = this.getSpriteLayer("dazzle stars");
	if (blob.hasTag("dazzled") && !blob.hasTag("dead"))
	{
		stars.SetVisible(true);

		int layer = 0;
		Vec2f head_offset = getHeadOffset(blob, -1, layer);

		if (layer != 0)
		{
			Vec2f off = Vec2f(this.getFrameWidth() / 2, -this.getFrameHeight() / 2);
			off += this.getOffset();
			off += Vec2f(-head_offset.x, head_offset.y);

			off += Vec2f(Maths::Round(Maths::Sin(getGameTime() * 0.2f) * 3 + 1), Maths::Round(-3 - Maths::Abs(Maths::Cos(getGameTime() * 0.15f) * 3)));

			stars.SetOffset(off);
		}
	}
	else
	{
		stars.SetVisible(false);
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!blob.isMyPlayer()) return;

	if (blob.hasTag("dazzled"))
	{
		SetScreenFlash(128, 230, 240, 255);
	}
}
