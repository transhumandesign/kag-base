void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	attachedPoint.offsetZ = -10.0f;
	this.getSprite().SetRelativeZ(-10.0f);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	attachedPoint.offsetZ = 0.0f;
	this.getSprite().SetRelativeZ(0.0f);
}
