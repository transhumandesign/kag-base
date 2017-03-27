
//ignore all damage after this, basically "invincible"

void onInit(CBlob@ this)
{
	this.Tag("invincible");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0.0f;
}
