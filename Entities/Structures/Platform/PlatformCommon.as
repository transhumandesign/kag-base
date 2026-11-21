
bool CollidesWithPlatform(Vec2f ray, Vec2f hitpos, CBlob@ platform)
{
	f32 angle = platform.getAngleDegrees();
	Vec2f border_offset = Vec2f(0, -getMap().tilesize / 2);
	border_offset.RotateBy(Maths::Round(angle));         // getting rid of "0.001 off" cases
	
	const f32 ray_angle = border_offset.AngleWith(ray);
	
	if (!(ray_angle > -90.0f && ray_angle < 90.0f)) // facing against platform?
	{	
		Vec2f border_pos = platform.getPosition() + border_offset;
		hitpos = Vec2f(Maths::Round(hitpos.x), Maths::Round(hitpos.y));
		
		return ((angle + 45.0f) % 180.0f) < 90.0f ? border_pos.y == hitpos.y : border_pos.x == hitpos.x; // ray hitpos overlaps with border pos?
	}
	
	return false;
}
