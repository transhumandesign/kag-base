
bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (blob.getRadius() >= this.getRadius());
}