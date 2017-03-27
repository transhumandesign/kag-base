void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-20.0f);
	this.getSprite().animation.frame = (this.getNetworkID() * 31) % 4;

	this.SetFacingLeft(((this.getNetworkID() + 27) * 31) % 18 > 9);
}

void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 2.0;
	const u8 team = blob.getTeamNum();

	const string filename = this.getFilename();

	if ((blob.getNetworkID() * 31) % 3 != 0)
	{
		CParticle@ Head     = makeGibParticle(filename, pos, vel + getRandomVelocity(90, hp , 80), 6, 0, Vec2f(16, 16), 2.0f, 20, "/material_drop", team);
	}

	{
		int r = ((blob.getNetworkID() * 31) % 3);
		CParticle@ Large1   = makeGibParticle(filename, pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 7 - (r % 2), 1 - (r / 2), Vec2f(16, 16), 2.0f, 20, "/material_drop", team);
	}

	{
		int r = (((blob.getNetworkID() + 1) * 31) % 3);
		CParticle@ Large1   = makeGibParticle(filename, pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 7 - (r % 2), 1 - (r / 2), Vec2f(16, 16), 2.0f, 20, "/material_drop", team);
	}

}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.0f)
	{
		if (worldPoint.x > this.getPosition().x)
		{
			this.setAngleDegrees(this.getAngleDegrees() - 3 - XORRandom(10));
		}
		else
		{
			this.setAngleDegrees(this.getAngleDegrees() + 3 + XORRandom(10));
		}
	}
	return damage;
}
