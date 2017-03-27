
bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (this.getShape().isStatic())
	{
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		return true;
	}

	return false;
}