// Flesh hit

f32 getGibHealth(CBlob@ this)
{
	if (this.exists("gib health"))
	{
		return this.get_f32("gib health");
	}

	return 0.0f;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	this.Damage(damage, hitterBlob);
	// Gib if health below gibHealth
	f32 gibHealth = getGibHealth(this);

	//printf("ON HIT " + damage + " he " + this.getHealth() + " g " + gibHealth );
	// blob server_Die()() and then gib


	//printf("gibHealth " + gibHealth + " health " + this.getHealth() );
	if (this.getHealth() <= gibHealth)
	{
		this.getSprite().Gib();
		this.server_Die();
	}

	return 0.0f; //done, we've used all the damage
}
