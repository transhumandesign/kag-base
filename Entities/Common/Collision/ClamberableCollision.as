
void onInit(CBlob@ this)
{
	this.Tag("clamberable");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if(blob.getShape().isStatic())
	{
		return true;
	}
	if (blob.isAttached()) // no colliding against people inside vehicles or held items
	{
		return false;
	}
	if (blob.hasTag("flesh"))
	{
		return (!blob.isKeyPressed(key_down) && this.getPosition().y > blob.getPosition().y + blob.getRadius());
	}
	else
	{
		return true;
	}
}
