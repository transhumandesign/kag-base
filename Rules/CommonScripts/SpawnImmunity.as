// no damage until action pressed or 5 secs
// works with UnSpawnImmunity.as on blobs

const f32 IMMUNITY_SECS = 3;

void onInit(CRules@ this)
{
	this.set_f32("immunity sec", IMMUNITY_SECS);
}

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale)
{
	CBlob@ victimblob = victim.getBlob();
	if (victimblob !is null && victimblob.getTickSinceCreated() < (victimblob.exists("custom immunity time") ? victimblob.get_u32("custom immunity time") : (getTicksASecond() * IMMUNITY_SECS)))
	{
		if (victimblob.hasTag("invincible"))
		{
			DamageScale = 0.0f;
		}
	}

	return DamageScale;
}