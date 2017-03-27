
bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.isAttached()) // no colliding against people inside vehicles
		return false;
	return (!this.isOnMap() || (blob.getShape().isStatic() && !blob.getShape().getConsts().platform));
}