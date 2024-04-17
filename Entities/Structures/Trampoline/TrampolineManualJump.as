#include "TrampolineCommon.as";

void onInit(CBlob@ this)
{
	// this.getCurrentScript().runFlags |= Script::tick_overlapping; // Wat this do?
	// this.getCurrentScript().runProximityTag = "player";
	this.getCurrentScript().tickIfTag = "player_touching";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1, Vec2f point2)
{
	if (blob !is null && blob.hasTag("player"))
	{
		this.Tag("player_touching");
	}
}

void onTick(CBlob@ this)
{
	if (this.hasTag("folded")) return;

	bool player = false;
	CBlob@[] overlapping;
	if (this.getOverlapping(@overlapping))
	{
		for (int i = 0; i < overlapping.length; ++i)
		{
			CBlob@ b = overlapping[i];
			if (b.hasTag("player"))
			{
				player = true;

				bool jump;
				f32 angle = this.getAngleDegrees();

				if (angle < 40) // Up
				{
					jump = (b.isKeyJustPressed(key_up)
							&& !b.isKeyPressed(key_down));
				}
				else if (angle < 80) // Up-right
				{
					jump = (b.isKeyJustPressed(key_up)
							&& b.isKeyJustPressed(key_right));
				}
				else if (angle < 100) // Right
				{
					jump = ((b.isKeyJustPressed(key_up)
								|| b.isKeyJustPressed(key_down))
							&& b.isKeyJustPressed(key_right));
				}
				else if (angle < 160) // Down-right
				{
					jump = (b.isKeyJustPressed(key_down)
							&& b.isKeyJustPressed(key_right));
				}
				else if (angle < 200) // Down
				{
					jump = (b.isKeyJustPressed(key_down)
							&& (b.isKeyJustPressed(key_up)
								|| b.isKeyJustPressed(key_right)
								|| b.isKeyJustPressed(key_left)));
				}
				else if (angle < 260) // Down-left
				{
					jump = (b.isKeyJustPressed(key_down)
							&& b.isKeyJustPressed(key_left));
				}
				else if (angle < 280) // Left
				{
					jump = ((b.isKeyJustPressed(key_up)
								|| b.isKeyJustPressed(key_down))
							&& b.isKeyJustPressed(key_left));
				}
				else if (angle < 320) // Up-left
				{
					jump = (b.isKeyJustPressed(key_up)
							&& b.isKeyJustPressed(key_left));
				}
				else // Up
				{
					jump = (b.isKeyJustPressed(key_up)
							&& !b.isKeyPressed(key_down));
				}

				if (jump && getGameTime() - b.get_u32("safe_from_fall") > 10)
				{
					Bounce(this, b);
				}
			}
		}
	}

	if (!player)
	{
		this.Untag("player_touching");
	}
}