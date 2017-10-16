//knight "cling" clashing sound

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	// play cling sound if other knight attacked us
	// dmg could be taken out here if we ever want to

	if (hitterBlob.getPosition().x < this.getPosition().x && hitterBlob.getName() == "knight") // knight and the left one (to play only once)
	{
		CSprite@ sprite = this.getSprite();
		CSprite@ hsprite = hitterBlob.getSprite();

		if (hsprite.isAnimation("strike_power_ready") || hsprite.isAnimation("strike_mid") ||
		        hsprite.isAnimation("strike_mid_down") || hsprite.isAnimation("strike_up") ||
		        hsprite.isAnimation("strike_down") || hsprite.isAnimation("strike_up"))
		{
			if (sprite.isAnimation("strike_power_ready") || sprite.isAnimation("strike_mid") ||
			        sprite.isAnimation("strike_mid_down") || sprite.isAnimation("strike_up") ||
			        sprite.isAnimation("strike_down") || sprite.isAnimation("strike_up"))
			{
				this.getSprite().PlaySound("SwordCling");
			}
		}
	}

	return damage; //no block, damage goes through
}
