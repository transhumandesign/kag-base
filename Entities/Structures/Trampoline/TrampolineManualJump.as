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

				f32 angle = this.getAngleDegrees();
				if (angle > 90 && angle < 270)
				{
					return;
				}
				if (b.isKeyJustPressed(key_up)
					&& getGameTime() - b.get_u32("safe_from_fall") > 10)
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