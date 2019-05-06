
const string knocked_tag = "knockable";

//make sure to use this in onInit if needed

void setKnockable(CBlob@ this)
{
	this.set_u32("knocked", 0);
	this.set_u32("last_server_knocked", 0);
	this.Tag(knocked_tag);
	this.Sync("knocked", true);
	this.Sync("last_server_knocked", true);
	this.Sync(knocked_tag, true);
}

u32 getKnocked(CBlob@ this)
{
	if (!this.exists("knocked"))
		return 0;

	u32 knocked_end = this.get_u32("knocked");
	u32 gameTime = getGameTime();

	if(gameTime > knocked_end)
	{
		return 0;

	}

	return knocked_end - gameTime;
}

bool isKnocked(CBlob@ this)
{
	return (getKnocked(this) > 0);
}

void DoKnockedUpdate(CBlob@ this)
{
	if (this.hasTag("invincible"))
	{
		this.DisableKeys(0);
		this.DisableMouse(false);
		return;
	}

	u32 knocked = getKnocked(this);

	if (knocked > 0)
	{
		u16 takekeys;
		if (knocked < 2 || (this.hasTag("dazzled") && knocked < 30))
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

		if (knocked == 0)
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
	return blob.hasTag(knocked_tag);
}

// This will return true if this is the frame that the knock got synced from the server
bool knockedJustSynced(CBlob@ blob)
{
	return getGameTime() == blob.get_u32("last_server_knocked");
}

void SetKnocked(CBlob@ blob, int ticks, bool sync = false)
{
	if((getNet().isServer() && sync) || !sync)
	{
		if ((blob.hasTag("invincible") && ticks != 0) || !isKnockable(blob))
			return; //do nothing

		u32 current = getKnocked(blob);
		ticks = Maths::Min(255, Maths::Max(current, ticks));
		u32 knocked_time = getGameTime() + ticks;
		blob.set_u32("knocked", knocked_time);
		if (sync)
		{
			blob.set_u32("last_server_knocked", getGameTime());
			blob.Sync("last_server_knocked", true);
			blob.Sync("knocked", true);
		}
	}

}
