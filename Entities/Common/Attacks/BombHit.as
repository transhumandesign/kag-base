#include "Hitters.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::bomb || customData == Hitters::water)
	{
		if (this !is null && this.hasTag("player") && isClient())
		{
			this.AddForce(velocity);
		}
	}

	return damage; 
}
