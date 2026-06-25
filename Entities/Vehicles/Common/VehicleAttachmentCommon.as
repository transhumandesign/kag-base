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

					CAttachment@ att = b.getAttachments(); 
					if (b.getTeamNum() == blob.getTeamNum() && att !is null)
					{
						// attach mounted bow to blob's BOW attachment point if it exists and is empty
						AttachmentPoint@ bap2 = att.getAttachmentPointByName("BOW");
						if (blob.getName() == "mounted_bow" && bap2 !is null && bap2.socket && bap2.getOccupied() is null)
						{
							b.server_AttachTo(blob, bap2);
							break;
						}

						// attach vehicle to blob's VEHICLE attachment point
						AttachmentPoint@ bap3 = att.getAttachmentPointByName("VEHICLE");
						if (bap3 !is null && bap3.socket && bap3.getOccupied() is null)
						{
							b.server_AttachTo(blob, bap3);
							break;
						}
					}
				}
			}
		}
	}
}