
void onInit(CBlob@ this)
{
	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			InitSeatAttachment(aps[i]);
		}
	}

	this.Tag("seats");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_hasattached;
}

void onTick(CBlob@ this)
{
	// set face direction

	const bool facing = this.isFacingLeft();
	const f32 angle = this.getAngleDegrees();

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			if (ap.socket)
			{
				CBlob@ occBlob = ap.getOccupied();
				if (occBlob !is null)
				{
					occBlob.SetFacingLeft(facing);
					occBlob.setAngleDegrees(angle);
				}
			}
		}
	}
}


void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attachedPoint.socket)
	{
		attached.Tag("seated");
		Sound::Play("GetInVehicle.ogg", attached.getPosition());

		if (this.getDamageOwnerPlayer() is null) {
			this.SetDamageOwnerPlayer(attached.getPlayer());
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (attachedPoint.socket)
	{
		detached.Untag("seated");

		if (!detached.getShape().isRotationsAllowed())
		{
			detached.setAngleDegrees(0.0f);
		}

		if (detached.hasTag("dead") || detached.getPlayer() is this.getDamageOwnerPlayer()) {
			
			this.SetDamageOwnerPlayer(null);
		}
	}
}

void InitSeatAttachment(AttachmentPoint@ ap)
{
	if (ap !is null && ap.socket)
	{
		ap.offsetZ = -10.0f;
		ap.customData = 0;

		if (ap.name == "PASSENGER")
		{
			//dont take mouse or actions so you can shoot
			ap.SetKeysToTake(key_left | key_right | key_up | key_down);
		}
		else if (ap.name == "DRIVER" || ap.name == "ROWER" || ap.name == "FLYER" || ap.name == "GUNNER" || ap.name == "MAG")
		{
			ap.SetKeysToTake(key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_inventory);
			ap.SetMouseTaken(true);

			if (ap.name == "DRIVER")
			{
				ap.controller = true;								// client-side movement
			}
		}
	}
}
