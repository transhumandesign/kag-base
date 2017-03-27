
bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return this.getName() != blob.getName();
}