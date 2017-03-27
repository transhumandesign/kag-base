#include "AnimalConsts.as";

void onInit(CBlob@ this)
{
	this.set_u16("seat ride time", 90);
	this.Tag("animal");

	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runProximityTag = "player";
	this.getCurrentScript().runProximityRadius = 320.0f;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attachedPoint.socket)
	{
		this.set_u32("seat time", getGameTime());
		this.Tag("no barrier pass");
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	if (attachedPoint.socket)
	{
		detached.setVelocity(this.getVelocity());
		detached.AddForce(Vec2f(0.0f, -300.0f));
		this.Untag("no barrier pass");
	}
}

void onTick(CBlob@ this)
{
	// hack to disable seats

	const u32 seattime = this.get_u32("seat time");
	const u32 gametime = getGameTime();

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		u16 ridetime = this.get_u16("seat ride time");
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];

			if (ap.socket)
			{
				CBlob@ occ = ap.getOccupied();

				CBlob@ friend = getBlobByNetworkID(this.get_netid(friend_property));

				if (occ is null && seattime + ridetime > gametime)
					ap.SetKeysToTake(0);
				else
				{
					ap.SetKeysToTake(key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3);

					if ((occ !is null && occ is friend) || (XORRandom(3) == 0))
					{
						this.setKeyPressed(key_left, ap.isKeyPressed(key_left));
						this.setKeyPressed(key_right, ap.isKeyPressed(key_right));
						this.setKeyPressed(key_up, ap.isKeyPressed(key_down));
						this.setKeyPressed(key_down, ap.isKeyPressed(key_up));
					}

				}

				// GET OUT
				if (occ !is null && (ap.isKeyJustPressed(key_up) || (occ !is friend && (seattime + ridetime <= gametime) && this.getShape().vellen > 0.4f)))
				{
					this.server_DetachFrom(occ);
					// pickup shark after done riding on land
					if (this.getAttachments().getAttachmentPointByName("PICKUP") !is null && !this.isInWater())
					{
						occ.server_Pickup(this);
					}
				}
			}
		}
	}
}