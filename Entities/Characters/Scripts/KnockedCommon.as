const string knockedProp = "knockedTime";
const string knockedTag = "knockable";

void InitKnockable(CBlob@ this)
{
	this.set_u32(knockedProp, 0);
	this.Tag(knockedTag);

	this.Sync(knockedProp, true);
	this.Sync(knockedTag, true);

	this.addCommandID("knocked");

	//this.set_u32("knocked_realticks", 0);
	//this.set_s32("knocked_timer", 0);
}

// returns true if the new knocked time would be longer than the current.
bool setKnocked(CBlob@ blob, int ticks, bool server_only = false)
{
	if (blob.hasTag("invincible"))
		return false; //do nothing

	u32 knockedTime = ticks;
	u32 currentKnockedTime = blob.get_u32(knockedProp);
	if (knockedTime > currentKnockedTime)
	{
		//blob.set_u32("knocked_realticks", getGameTime());
		//print(blob.getPlayer().getUsername() + " stun amount " + knockedTime + " gameTime: " + getGameTime());
		if (getNet().isServer())
		{
			blob.set_u32(knockedProp, knockedTime);

			CBitStream params;
			params.write_u32(knockedTime);

			blob.SendCommand(blob.getCommandID("knocked"), params);

		}

		if(!server_only)
		{
			blob.set_u32(knockedProp, knockedTime);
		}

		return true;
	}
	return false;

}

void KnockedCommands(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("knocked") && getNet().isClient())
	{
		u32 knockedTime = 0;
		if (!params.saferead_u32(knockedTime))
		{
			return;

		}

		this.set_u32("justKnocked", getGameTime());
		this.set_u32(knockedProp, knockedTime);
	}
}

u32 getKnockedRemaining(CBlob@ this)
{
	u32 currentKnockedTime = this.get_u32(knockedProp);
	return currentKnockedTime;
}

bool isKnocked(CBlob@ this)
{
	if (this.getPlayer() !is null && this.getPlayer().freeze)
	{
		return true;

	}

	u32 knockedRemaining = getKnockedRemaining(this);
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

	u32 knockedRemaining = getKnockedRemaining(this);
	bool frozen = false;
	if (this.getPlayer() !is null && this.getPlayer().freeze)
	{
		frozen = true;
	}

	if (knockedRemaining > 0 || frozen)
	{
		//this.set_s32("knocked_timer", 0);
		knockedRemaining--;
		this.set_u32(knockedProp, knockedRemaining);

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

		// for some reason keys are taken for 1 tick to long in the engine
		if (knockedRemaining < 2)
		{
			this.DisableKeys(0);
			this.DisableMouse(false);
		}

		if (knockedRemaining == 0)
		{
			this.Untag("dazzled");
			//u32 knockedStart = this.get_u32("knocked_realticks");
			//print(this.getPlayer().getUsername() + " knocked actual ticks: " + (getGameTime() - knockedStart));
			//print(this.getPlayer().getUsername() + " knocked finished gameTime: " + getGameTime());
		}


		this.Tag("prevent crouch");
	}
	else
	{
		this.DisableKeys(0);
		this.DisableMouse(false);
	}

	/*if (knockedRemaining <= 0)
	{
		this.set_s32("knocked_timer", this.get_s32("knocked_timer")+1);
	}*/
}

bool isKnockable(CBlob@ blob)
{
	return blob.hasTag(knockedTag);
}
