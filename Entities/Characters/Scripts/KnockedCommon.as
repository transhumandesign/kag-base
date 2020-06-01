const string knockedProp = "knockedTime";
const string knockedTag = "knockable";

void InitKnockable(CBlob@ this)
{
	this.set_u32(knockedProp, 0);
	this.Tag(knockedTag);

	this.Sync(knockedProp, true);
	this.Sync(knockedTag, true);

	this.addCommandID("knocked");
}

// returns true if the new knocked time would be longer than the current.
bool setKnocked(CBlob@ blob, int ticks)
{
	if (blob.hasTag("invincible"))
		return false; //do nothing

	// set knocked to current time + ticks
	u32 knockedTime = getGameTime() + ticks;
	u32 currentKnockedTime = blob.get_u32(knockedProp);
	if (knockedTime > currentKnockedTime)
	{
		blob.set_u32(knockedProp, knockedTime);
		if (getNet().isServer())
		{
			CBitStream params;
			params.write_u32(knockedTime);

			blob.SendCommand(blob.getCommandID("knocked"), params);

		}
		return true;
	}
	return false;

}

void KnockedCommands(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("knocked"))
	{
		u32 knockedTime = 0;
		if (!params.saferead_u32(knockedTime))
		{
			return;

		}

		this.set_u32(knockedProp, knockedTime);
	}
}

u32 getKnockedRemaining(CBlob@ this)
{
	u32 currentKnockedTime = this.get_u32(knockedProp);
	u32 time = getGameTime();
	if (time >= currentKnockedTime)
	{
		return 0;
	}

	return currentKnockedTime - time;
}

bool isKnocked(CBlob@ this)
{
	u32 knockedRemaining = getKnockedRemaining(this);
	return (knockedRemaining > 0);
}

void DoKnockedUpdate(CBlob@ this)
{
	if (this.hasTag("invincible"))
	{
		this.DisableKeys(0);
		this.DisableMouse(false);
		return;
	}

	u32 knockedRemaining = getKnockedRemaining(this);

	if (knockedRemaining > 0)
	{
		u16 takekeys;
		if (knockedRemaining < 2 || (this.hasTag("dazzled") && knockedRemaining < 30))
		{
			takekeys = key_action1 | key_action2 | key_action3;

			if (this.isOnGround())
			{
				this.AddForce(this.getVelocity() * -10.0f);
			}
		}
		else
		{
			takekeys = key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3;
		}

		this.DisableKeys(takekeys);
		this.DisableMouse(true);

		this.Tag("prevent crouch");
	}
	else
	{

		if (this.hasTag("dazzled"))
		{
			this.Untag("dazzled");
		}

		this.DisableKeys(0);
		this.DisableMouse(false);
	}
}

bool isKnockable(CBlob@ blob)
{
	return blob.hasTag(knockedTag);
}
