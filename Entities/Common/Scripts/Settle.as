#include "SettleCommon.as"

void onInit(CBlob@ this)
{
	this.set_s32("settle_time", 0);
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	u32 time = this.get_s32("settle_time");
	CShape@ shape = this.getShape();

	// SETTLE

	if (!shape.isStatic())
	{
		Vec2f delta = shape.getVars().pos - shape.getVars().oldpos;
		f32 deltasq = delta.LengthSquared();
		f32 deltaang = Maths::Abs(shape.getVars().angvel - shape.getVars().oldangvel);

		if (deltasq < 5.0f && deltaang < 0.3f)
		{
			time++;

			if (time > 39)
			{
				Disable(this);
				time = 0;
				//printf("SET");
			}
		}
		else
		{
			if (time > 5)
			{
				time = 5;
			}

			time--;
		}
	}
	else
	{
		time = 0;
		// support fall
		if (shape.getCurrentSupport() < 0.05f)
		{
			Enable(this);
		}
	}

	this.set_s32("settle_time", time);
}
