
bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (this.getTeamNum() != blob.getTeamNum() || (blob.getShape().isStatic() && !blob.getShape().getConsts().platform));
}