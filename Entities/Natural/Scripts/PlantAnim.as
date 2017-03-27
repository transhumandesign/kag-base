// Plant animation

#include "PlantGrowthCommon.as";

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = 25;
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	bool isGrown = blob.hasTag(grown_tag);
	if (isGrown)
	{
		Animation @anim = this.getAnimation("grown");
		if (anim !is null)
		{
			this.SetAnimation(anim);
			anim.setFrameFromRatio(1.0f - (blob.getHealth() / blob.getInitialHealth()));
		}
	}
	else
	{
		Animation @anim = this.getAnimation("growth");
		if (anim !is null)
		{
			this.SetAnimation(anim);
			u8 amount = blob.get_u8(grown_amount);
			f32 ratio = f32(amount) / f32(growth_max);

			anim.setFrameFromRatio(ratio);
		}
	}
}
