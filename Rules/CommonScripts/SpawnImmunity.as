// no damage for 3 sec.
// Depletes faster if key_action1 is pressed.
// works with UnSpawnImmunity.as on blobs.

const f32 IMMUNITY_SEC = 3;

void onInit(CRules@ this)
{
	this.set_f32("immunity sec", IMMUNITY_SEC);
}

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale)
{
	CBlob@ victimblob = victim.getBlob();
	if (victimblob !is null 
		&& victimblob.getTickSinceCreated() < getTicksASecond() * IMMUNITY_SEC 
		&& victim !is attacker)
	{
		if (victimblob.hasTag("invincible"))
		{
			DamageScale = 0.0f;
		}
	}

	return DamageScale;
}
