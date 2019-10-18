#include "EatCommon.as";

void onInit(CBlob@ this)
{
	if (!this.exists("eat sound"))
	{
		this.set_string("eat sound", "/Eat.ogg");
	}

	this.addCommandID(heal_id);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID(heal_id))
	{
		this.getSprite().PlaySound(this.get_string("eat sound"));

		if (getNet().isServer())
		{
			u16 blob_id;
			if (!params.saferead_u16(blob_id)) return;

			CBlob@ theBlob = getBlobByNetworkID(blob_id);
			if (theBlob !is null)
			{
				u8 heal_amount;
				if (!params.saferead_u8(heal_amount)) return;

				if (heal_amount == 255)
				{
					theBlob.add_f32("heal amount", theBlob.getInitialHealth() - theBlob.getHealth());
					theBlob.server_SetHealth(theBlob.getInitialHealth());
				}
				else
				{
					f32 oldHealth = theBlob.getHealth();
					theBlob.server_Heal(f32(heal_amount) * 0.25f);
					theBlob.add_f32("heal amount", theBlob.getHealth() - oldHealth);
				}

				//give coins for healing teammate
				if (this.exists("healer"))
				{
					CPlayer@ player = theBlob.getPlayer();
					u16 healerID = this.get_u16("healer");
					CPlayer@ healer = getPlayerByNetworkId(healerID);
					if (player !is null && healer !is null)
					{
						bool healerHealed = healer is player;
						bool sameTeam = healer.getTeamNum() == player.getTeamNum();
						if (!healerHealed && sameTeam)
						{
							int coins = this.getName() == "heart" ? 5 : 10;
							healer.server_setCoins(healer.getCoins() + coins);
						}
					}
				}

				theBlob.Sync("heal amount", true);
			}

			this.server_Die();
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null)
	{
		return;
	}

	if (getNet().isServer() && !blob.hasTag("dead"))
	{
		Heal(blob, this);
	}
}


void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (this is null || attached is null) {return;}

	if (isServer())
	{
		Heal(attached, this);
	}

	CPlayer@ p = attached.getPlayer();
	if (p is null){return;}

	this.set_u16("healer", p.getNetworkID());
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	if (this is null || detached is null) {return;}

	if (isServer())
	{
		Heal(detached, this);
	}
	
	CPlayer@ p = detached.getPlayer();
	if (p is null){return;}

	this.set_u16("healer", p.getNetworkID());
}