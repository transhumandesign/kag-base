
namespace Trampoline
{
	const string TIMER = "trampoline_timer";
	const u16 COOLDOWN = 7;
	const u8 SCALAR = 10;
	const bool SAFETY = true;
	const int COOLDOWN_LIMIT = 8;
}

void Bounce(CBlob@ this, CBlob@ blob, Vec2f point1 = Vec2f_zero)
{
	f32 angle = this.getAngleDegrees();
	Vec2f velocity = Vec2f(0, -Trampoline::SCALAR);
	velocity.RotateBy(angle);

	blob.setVelocity(velocity);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetAnimation("default");
		sprite.SetAnimation("bounce");
		sprite.PlaySound("TrampolineJump.ogg");
	}
}
