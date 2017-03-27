// sets a timer that decreases health of the object if it is not used

#define SERVER_ONLY

const s32 DEFAULT_TIMEOUT_SECS = 60;

void SetTimeout(CBlob@ this, int secs)
{
	this.set_s32("timeout", secs * getTicksASecond());
}

void onInit(CBlob@ this)
{
	SetTimeout(this, DEFAULT_TIMEOUT_SECS);
	this.getCurrentScript().runFlags |= Script::tick_not_hasattached;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().tickFrequency = 30;
}

void onTick(CBlob@ this)
{
	if (this.getVelocity().LengthSquared() > 1.0f)
	{
		SetTimeout(this, DEFAULT_TIMEOUT_SECS);   //we're moving, -> shouldn't time out
	}

	CInventory@ inv = this.getInventory();
	if (inv is null || this.getInventory().getItemsCount() == 0) // special case : only when inv empty
	{
		s32 timeout = this.get_s32("timeout");
		timeout -= this.getCurrentScript().tickFrequency;

		if (timeout <= 0)
		{
			this.server_Die();
			return;
		}

		this.set_s32("timeout", timeout);
	}
}

// increase timeout because object was used

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	SetTimeout(this, DEFAULT_TIMEOUT_SECS);
}