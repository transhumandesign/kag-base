//collide with vehicles and structures

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (blob.getShape().isStatic() || (blob.isInWater() && blob.hasTag("vehicle"))); // boat
}
