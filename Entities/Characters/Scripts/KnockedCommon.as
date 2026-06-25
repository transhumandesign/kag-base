const string knockedProp = "knocked";
const string knockedTag = "knockable";

void InitKnockable(CBlob@ this)
{
	this.set_u8(knockedProp, 0);
	this.Tag(knockedTag);

	this.Sync(knockedProp, true);
	this.Sync(knockedTag, true);

	this.addCommandID("knocked");

	this.set_u32("justKnocked", 0);
}

// returns true if the new knocked time would be longer than the current.
bool setKnocked(CBlob@ blob, int ticks, bool server_only = false)
{
	if (blob.hasTag("invincible"))
		return false; //do nothing

	u8 knockedTime = ticks;
	u8 currentKnockedTime = blob.get_u8(knockedProp);
	if (knockedTime > currentKnockedTime)
	{
		if (isServer())
		{
			blob.set_u8(knockedProp, knockedTime);

			CBitStream params;
			params.write_u8(knockedTime);

			blob.SendCommand(blob.getCommandID("knocked"), params);
		}

		if(!server_only && blob.isMyPlayer())
		{
			blob.set_u8(knockedProp, knockedTime);
		}

		return true;
	}

	return false;
}

void KnockedCommands(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("knocked") && isClient())
	{
		u8 knockedTime = 0;
		if (!params.saferead_u8(knockedTime))
		{
			return;

		}

		this.set_u32("justKnocked", getGameTime());
		this.set_u8(knockedProp, knockedTime);
	}
}

u8 getKnockedRemaining(CBlob@ this)
{
	u8 currentKnockedTime = this.get_u8(knockedProp);
	return currentKnockedTime;
}

bool isKnocked(CBlob@ this)
{
	if (this.getPlayer() !is null && this.getPlayer().freeze)
	{
		return true;
	}

	u8 knockedRemaining = getKnockedRemaining(this);
	return (knockedRemaining > 0);
}

bool isJustKnocked(CBlob@ this)
{
	return this.get_u32("justKnocked") == getGameTime();
}

void DoKnockedUpdate(CBlob@ this)
{
	if (this.hasTag("invincible"))
	{
		this.DisableKeys(0);
		this.DisableMouse(false);
		return;
	}

	u8 knockedRemaining = getKnockedRemaining(this);
	bool frozen = false;
	if (this.getPlayer() !is null && this.getPlayer().freeze)
	{
		frozen = true;
	}

	if (knockedRemaining > 0 || frozen)
	{
		if (knockedRemaining > 0)
		{
			knockedRemaining--;
			this.set_u8(knockedProp, knockedRemaining);

			if (this.isMyPlayer())
			{
				this.ClearButtons();
				this.ClearMenus();
			}
		}

		u16 takekeys;
		if (knockedRemaining < 2 || (this.hasTag("dazzled") && knockedRemaining < 30))
		{
			takekeys = key_action1 | key_action2 | key_action3 | key_inventory;

			if (this.isOnGround())
			{
				this.AddForce(this.getVelocity() * -10.0f);
			}
		}
		else
		{
			takekeys = key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_inventory;
		}

		this.DisableKeys(takekeys);
		this.DisableMouse(true);

		// Disable keys takes the keys for tick after it's called
		// so we want to end on time by not calling DisableKeys before knocked finishes
		if (knockedRemaining < 2 && !frozen)
		{
			this.DisableKeys(0);
			this.DisableMouse(false);
		}

		if (knockedRemaining == 0)
		{
			this.Untag("dazzled");
		}

		this.Tag("prevent crouch");
	}
	else
	{
		this.DisableKeys(0);
		this.DisableMouse(false);
	}
}

bool isKnockable(CBlob@ blob)
{
	return blob.hasTag(knockedTag);
}
