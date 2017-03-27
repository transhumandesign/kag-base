// use this script if you want the blob to get in seats on down press

#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runProximityTag = "seats";
	this.getCurrentScript().runProximityRadius = 75.0f;
	this.getCurrentScript().runFlags |= Script::tick_not_ininventory;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	// find blobs with seats
	if (this.isKeyJustPressed(key_down) &&
	        !this.isAttached() &&
	        !this.isKeyPressed(key_action1) &&
	        !this.isKeyPressed(key_action2) &&
	        !this.isKeyPressed(key_action3) &&
	        !this.isKeyPressed(key_left) &&
	        !this.isKeyPressed(key_right))
	{
		CBlob@[] blobsInRadius;
		this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.5f + 25.0f, @blobsInRadius);
		AttachmentPoint@[] points;
		CBlob@ carried = this.getCarriedBlob();
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @blob = blobsInRadius[i];

			if ((blob !is this) &&
			        blob.hasTag("seats") &&
			        blob !is carried &&
			        (blob.getTeamNum() > 8 || blob.getTeamNum() == this.getTeamNum()))
			{
				//can't get into carried blob - can pick it up after they get in though
				//(prevents dinghy rockets)
				if (blob.isAttachedToPoint("PICKUP"))
					continue;

				if (blob !is this.getIgnoreCollisionBlob())
				{
					GatherAttachments(blob, @points);
				}
				else
				{
					this.IgnoreCollisionWhileOverlapped(null);
				}
			}
		}

		// pick closest seat
		f32 closestDist = 99999.9f;
		AttachmentPoint@ closestAP;
		Vec2f pos = this.getPosition();

		for (uint i = 0; i < points.length; i++)
		{
			AttachmentPoint @ap = points[i];

			if ((ap.getKeysToTake() == 0 || (this.getPlayer() !is null)))    // either this attachment doesn't require a controller or blob is controlled
			{
				f32 distance = (pos - (ap.getPosition() + Vec2f(0.0f, 4.0f))).getLength();     //adjust to detect lower

				if (distance <= ap.radius + 4.0f)
				{
					// cheat - attached objects have closer seats (cata in boat)
					if (ap.getBlob().isAttached())
					{
						distance *= 0.3f;
					}

					if (distance < closestDist)
					{
						closestDist = distance;
						@closestAP = ap;
					}
				}
			}
		}

		// sit in closest

		if (closestAP !is null)
		{
			closestAP.getBlob().server_AttachTo(this, closestAP);
		}
	}
}

void GatherAttachments(CBlob@ blob, AttachmentPoint@[]@ points)
{
	int count = blob.getAttachmentPointCount();
	for (int i = 0; i < count; i++)
	{
		AttachmentPoint @ap = blob.getAttachmentPoint(i);
		const bool driver = ap.name == "DRIVER";  // HACK:
		if (driver && blob.hasTag("immobile")) continue;
		if (ap.getOccupied() is null && ap.socket && ap.getKeysToTake() > 0 && (!driver || (driver && !blob.isAttached()))) // gather empty controllers attachments/seats
		{
			points.push_back(@ap);
		}
	}
}