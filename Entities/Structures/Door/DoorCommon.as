//common functionality for door-like objects

bool canOpenDoor(CBlob@ this, CBlob@ blob)
{
	if ((blob.getShape().getConsts().collidable) && //solid              // vvv lets see
	        (blob.getRadius() > 5.0f) && //large
	        (this.getTeamNum() == 255 || this.getTeamNum() == blob.getTeamNum()) &&
	        (blob.hasTag("player") || blob.hasTag("vehicle") || blob.hasTag("migrant"))) //tags that can open doors
	{
		Vec2f direction = Vec2f(0, -1);
		direction.RotateBy(this.getAngleDegrees());

		Vec2f doorpos = this.getPosition();
		Vec2f playerpos = blob.getPosition();

		if (blob.isKeyPressed(key_left) && playerpos.x > doorpos.x && Maths::Abs(playerpos.y - doorpos.y) < 11) return true;
		if (blob.isKeyPressed(key_right) && playerpos.x < doorpos.x && Maths::Abs(playerpos.y - doorpos.y) < 11) return true;
		if (blob.isKeyPressed(key_up) && playerpos.y > doorpos.y && Maths::Abs(playerpos.x - doorpos.x) < 11) return true;
		if (blob.isKeyPressed(key_down) && playerpos.y < doorpos.y && Maths::Abs(playerpos.x - doorpos.x) < 11) return true;
	}
	return false;
}