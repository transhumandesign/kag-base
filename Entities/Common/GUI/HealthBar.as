// draws a health bar on mouse hover

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();

	if (blob.hasTag("dead"))
	{
		return;
	}

	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	if (mouseOnBlob)
	{
		//VV right here VV
		Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 20);
		Vec2f dim = Vec2f(24, 8);
		const f32 y = blob.getHeight() * 2.4f;
		const f32 initialHealth = blob.getInitialHealth();
		if (initialHealth > 0.0f)
		{
			const f32 perc = blob.getHealth() / initialHealth;
			if (perc >= 0.0f)
			{
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2, pos2d.y + y - 2), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 2));
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x - 2, pos2d.y + y + dim.y - 2), SColor(0xffac1512));
			}
		}
	}
}