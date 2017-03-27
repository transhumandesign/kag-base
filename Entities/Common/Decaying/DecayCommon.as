const bool DECAY_DEBUG = false;

bool dissalowDecaying(CBlob@ this)
{
	return (
	           this.getControls() !is null ||
	           this.isInInventory()
	       );
}

void SelfDamage(CBlob@ this, f32 dmg)
{
	this.server_Hit(this, this.getPosition(), Vec2f(0, -1), dmg, 0);
}

void SelfDamage(CBlob@ this)
{
	SelfDamage(this, this.getInitialHealth() * 0.33f);
}