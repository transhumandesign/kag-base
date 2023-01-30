#include "BirthdayCommon.as";

const Vec2f offset_left = Vec2f(4, 2);
const Vec2f offset_middle = Vec2f_zero;
const Vec2f offset_right = Vec2f(-4, 3);

const uint8 frame_size = 8;

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	Vec2f offset = Vec2f(blob.getWidth()/2 - frame_size/2, -blob.getHeight()/2 - frame_size/2);

	if (blob.exists(offset_prop))
		offset += blob.get_Vec2f(offset_prop);

	CSpriteLayer@ string_layer = this.addSpriteLayer("string", "BirthdayBalloons.png", frame_size, frame_size);

	if (string_layer !is null)
	{
		Animation@ string_anim = string_layer.addAnimation("string", 0, false);

		string_anim.AddFrame(9);

		string_layer.SetAnimation(string_anim);
		string_layer.SetOffset(offset);
	}

	for (uint8 i = 0; i < 3; i++) // left, middle, right
	{
		CSpriteLayer@ balloon_layer = this.addSpriteLayer("balloon " + i, "BirthdayBalloons.png", frame_size, frame_size);

		if (balloon_layer !is null)
		{
			Animation@ balloon_anim = balloon_layer.addAnimation("balloon", 0, false);

			balloon_anim.AddFrame(i * 3 + XORRandom(3));

			Vec2f balloon_offset = offset;

			if (i == 0) // left
				balloon_offset += offset_left;
			else if (i == 1) // middle
				balloon_offset += offset_middle;
			else // right
				balloon_offset += offset_right;
			
			balloon_layer.SetAnimation(balloon_anim);
			balloon_layer.SetOffset(balloon_offset - Vec2f(0, frame_size));
		}
	}

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
