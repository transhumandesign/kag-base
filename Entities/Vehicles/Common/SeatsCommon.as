//LEGACY
void SetOccupied(AttachmentPoint @attachedPoint, int occupied)
{
	if (attachedPoint !is null && attachedPoint.socket)  		   //CRASH WITH NULL POINTER HERE SOMEHOW?
	{
		attachedPoint.customData = occupied;
	}
}