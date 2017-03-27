#include "RunnerCommon.as"

void onInit(CBlob@ this)
{
	//this.getCurrentScript().runFlags |= Script::tick_overlapping;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_not_onladder;
	this.getCurrentScript().runFlags |= Script::tick_not_onground;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
	if (!this.isKeyPressed(key_up)) { return; }

	CBlob@[] overlapping;
	if (this.getOverlapping(@overlapping))
	{
		RunnerMoveVars@ moveVars;
		if (!this.get("moveVars", @moveVars))
		{
			return;
		}

		for (uint i = 0; i < overlapping.length; i++)
		{
			CBlob@ b = overlapping[i];

			if (b.getName() == "arrow")
			{
				Vec2f vel = b.getVelocity();

				if (vel.LengthSquared() < 1)
				{
					moveVars.jumpCount = -1;
					Vec2f vel = this.getVelocity();
					if (vel.y > 0)
						this.setVelocity(Vec2f(vel.x, -1));

					if (getNet().isServer())
					{
						b.Damage(0.05f, b);
						if (b.getHealth() < 0)
						{
							b.getSprite().Gib();
							b.server_Die();
						}
					}

					return;
				}
			}
		}
	}
}
