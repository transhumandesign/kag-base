
void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point)
{
	if (getNet().isServer() && solid && !this.getShape().isStatic() && !this.isAttached())
	{
		if (this.getOldVelocity().y < 1.0f && !this.hasTag("can settle"))
		{
			this.server_SetTimeToDie(2);
		}
		else
		{
			this.server_Hit(this, this.getPosition(), this.getVelocity() * -1.0f, 10.0f, 0);
		}
	}
}
