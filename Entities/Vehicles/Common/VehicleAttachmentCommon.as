void TryToAttachVehicle(CBlob@ blob, CBlob@ toBlob = null)
{
	if (blob !is null && blob.getAttachments() !is null)
	{
		AttachmentPoint@ bap1 = blob.getAttachments().getAttachmentPointByName("VEHICLE");
		if (bap1 !is null && !bap1.socket && bap1.getOccupied() is null)
		{
			CBlob@[] blobsInRadius;
			if (toBlob !is null)
				blobsInRadius.push_back(toBlob);
			else
				getMap().getBlobsInRadius(blob.getPosition(), blob.getRadius() * 1.5f + 64.0f, @blobsInRadius);

			{
				for (uint i = 0; i < blobsInRadius.length; i++)
				{
					CBlob @b = blobsInRadius[i];
					if (b.getTeamNum() == blob.getTeamNum() && b.getAttachments() !is null)
					{
						AttachmentPoint@ bap2 = b.getAttachments().getAttachmentPointByName("VEHICLE");
						if (bap2 !is null && bap2.socket && bap2.getOccupied() is null)
						{
							b.server_AttachTo(blob, bap2);
							break;
						}
					}
				}
			}
		}
	}
}