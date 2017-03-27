#include "SeatsCommon.as"

// optimization: we use script globals here cause all seats GUI use the same value for this
f32 bounce;
u32 lastBounceTime;

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;
	if (this is null) return; //can happen with bad reload

	// draw only for local player
	CBlob@ localBlob = getLocalPlayerBlob();

	if (localBlob is null || localBlob.isAttached())
	{
		return;
	}
	CBlob@ blob = this.getBlob();

	f32 arrowVisibleRadius = blob.getRadius() + 15.0f;

	//too far away
	if ((localBlob.getPosition() - blob.getPosition()).getLength() > arrowVisibleRadius)
	{
		return;
	}
	//carrying us
	if (localBlob.getCarriedBlob() is blob)
	{
		return;
	}
	//not same team
	if ((blob.getTeamNum() <= 8 && blob.getTeamNum() != localBlob.getTeamNum()))
	{
		return;
	}

	// dont draw if angle is upside down
	f32 angle = blob.getAngleDegrees();

	if (angle > 70.0f && angle < 290.0f)
	{
		return;
	}

	// draw arrows pointing towards seats
	if (lastBounceTime != getGameTime())
	{
		bounce = Maths::Sin((getGameTime() + blob.getNetworkID()) / 4.5f);
		lastBounceTime = getGameTime();
	}

	if (bounce > 0.8f)
	{
		return;
	}

	AttachmentPoint@[] aps;
	if (blob.getAttachmentPoints(@aps))
	{
		string lastPointName;
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];

			if (ap.getOccupied() is null && ap.socket && ap.getKeysToTake() > 0 && ap.radius > 0.0f && lastPointName != ap.name) // gather empty controllers attachments/seats
			{
				int occupied = ap.customData;
				const bool driver = ap.name == "DRIVER";  // HACK:
				if (driver && blob.hasTag("immobile")) continue;

				if (occupied == 0 && (!driver || (driver && !blob.isAttached())))
				{
					Vec2f pos = getDriver().getScreenPosFromWorldPos(ap.getPosition());
					pos.y += -3.0f + 10.0f * bounce;
					if (blob.isFacingLeft())
					{
						pos.x -= 8.0f;
					}

					GUI::DrawIconByName("$down_arrow$", pos);

					if (g_debug == 0)
					{
						lastPointName = ap.name;  // draw just one of a kind
					}
				}
			}
		}
	}
}
