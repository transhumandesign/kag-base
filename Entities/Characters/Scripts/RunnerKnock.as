// stun
#include "/Entities/Common/Attacks/Hitters.as";
#include "Knocked.as";

void onInit(CBlob@ this)
{
	setKnockable(this);   //already done in runnerdefault but some dont have that
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("invincible")) //pass through if invince
		return damage;

	if (this.hasTag("dead")) //pass through if dead
		return damage;

	u8 time = 0;
	bool force = this.hasTag("force_knock");

	if (damage > 0.01f || force) //hasn't been cancelled somehow
	{
		if (force)
		{
			this.Untag("force_knock");
		}

		switch (customData)
		{
			case Hitters::builder:
				time = 0; break;

			case Hitters::sword:
				if (damage > 1.0f || force)
				{
					time = 20;
					if (force) //broke shield
						time = 10;
				}
				else
				{
					time = 2;
				}

				break;

			case Hitters::shield:
				time = 15; break;

			case Hitters::bomb:
				time = 20; break;

			case Hitters::spikes:
				time = 10; break;

			case Hitters::arrow:
				if (damage > 1.0f)
				{
					time = 15;
				}

				break;
		}
	}

	if (damage == 0 || force)
	{
		//get sponge
		CBlob@ sponge = null;
		//find the sponge with lowest absorbed
		CInventory@ inv = this.getInventory();
		if (inv !is null)
		{
			u8 lowest_absorbed = 100;
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob@ invitem = inv.getItem(i);
				if(invitem.getName() == "sponge")
				{
					if(invitem.get_u8("absorbed") < lowest_absorbed)
					{
						lowest_absorbed = invitem.get_u8("absorbed");
						@sponge = invitem;
					}
				}
			}
		}

		bool has_sponge = sponge !is null;
		bool wet_sponge = false;

		bool undefended = (force || !this.hasTag("shielded"));
		if ((customData == Hitters::water_stun && undefended) ||
		        customData == Hitters::water_stun_force)
		{
			if (has_sponge)
			{
				time = 5;
				wet_sponge = true;
			}
			else
			{
				time = 45;
			}

			this.Tag("dazzled");
		}

		if (has_sponge && wet_sponge)
		{
			string apn = "absorbed";
			u8 sp_max = 100;
			u8 sp_amount = Maths::Min(sp_max, sponge.get_u8(apn) + 50);
			//full?
			if(sp_amount == sp_max)
			{
				sponge.server_Die();
			}
			else
			{
				sponge.set_u8(apn, sp_amount);
				sponge.Sync(apn, true);
			}
		}
	}

	if (time > 0)
	{
		this.getSprite().PlaySound("/Stun", 1.0f, this.getSexNum() == 0 ? 1.0f : 2.0f);
		u8 currentstun = this.get_u8("knocked");
		this.set_u8("knocked", Maths::Clamp(time, currentstun, 60));
	}

//  print("KNOCK!" + this.get_u8("knocked") + " dmg " + damage );
	return damage; //damage not affected
}
