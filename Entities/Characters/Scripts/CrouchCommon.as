bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (this.isKeyPressed(key_down) && this.hasTag("crouch dodge") && !this.hasTag("ignore crouch"))
	{
		CShape@ shape = this.getShape();
		if (shape !is null && !shape.isStatic())
		{
			return false;
		}
	}
	
	return true;
}
