void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this is hitterBlob)
	{
		return damage;
	}

	if (damage > 1.45f) //sound for anything 2 heart+
	{
		Sound::Play("ArgLong.ogg", this.getPosition(), 1.0f, this.getSexNum() == 0 ? 1.0f : 2.0f);
	}
	else if (damage > 0.45f)
	{
		Sound::Play("ArgShort.ogg", this.getPosition(), 1.0f, this.getSexNum() == 0 ? 1.0f : 2.0f);
	}
	else if (damage > 0.1f)
	{
		Sound::Play("ArgShort.ogg", this.getPosition(), 1.0f, this.getSexNum() == 0 ? 1.0f : 2.0f);
	}

	return damage;
}
