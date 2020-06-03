// stun
#include "/Entities/Common/Attacks/Hitters.as";
#include "KnockedCommon.as";
#include "ShieldCommon.as";
#include "KnightCommon.as";

const u8 slash_knock = 9;

void onInit(CBlob@ this)
{
	InitKnockable(this);   //already done in runnerdefault but some dont have that
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
						time = slash_knock;
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

		{
			//find the sponge with highest absorbed amount
			CBlob@[] sponges;
			//gather held sponge if exists
			//(first, so carried sponge is prioritised if equal)
			CBlob@ carryblob = this.getCarriedBlob();
			if (carryblob !is null && carryblob.getName() == "sponge")
			{
				sponges.push_back(carryblob);
			}
			//gather inventory
			CInventory@ inv = this.getInventory();
			if (inv !is null)
			{
				for (int i = 0; i < inv.getItemsCount(); i++)
				{
					CBlob@ invitem = inv.getItem(i);
					if (invitem.getName() == "sponge")
					{
						sponges.push_back(invitem);
					}
				}
			}
			//check all
			int highest_absorbed = -1;
			for(int i = 0; i < sponges.length; i++)
			{
				CBlob@ current_sponge = sponges[i];
				int absorbed = current_sponge.get_u8("absorbed");
				if (absorbed > highest_absorbed)
				{
					highest_absorbed = absorbed;
					@sponge = current_sponge;
				}
			}
		}

		bool has_sponge = sponge !is null;
		bool wet_sponge = false;

		bool defended = this.hasTag("shielded");

		// If the class has a shield (check for ShieldVars) then check that the shield is pointing in the right direction
		if (getShieldVars(this) !is null && !blockAttack(this, velocity, damage))
		{
			defended = false;
		}

		// Don't allow the player to shield their own water explosives
		if (hitterBlob.getDamageOwnerPlayer() is this.getPlayer())
		{
			defended = false;
		}

		if (customData == Hitters::water_stun
			|| customData == Hitters::water_stun_force)
		{
			if (has_sponge)
			{
				if(customData == Hitters::water_stun_force)
				{
					time = 22;
				}
				else
				{
					time = 5;

				}
				wet_sponge = true;
			}
			else
			{
				time = 45;
			}

			// Halve the stun if it was blocked
			if (defended)
			{
				Sound::Play("ShieldHit.ogg", this.getPosition(), this.isMyPlayer() ? 1.3f : 0.7f);
				time *= 0.5;
			}

			this.Tag("dazzled");
		}

		if (has_sponge && wet_sponge)
		{
			string apn = "absorbed";
			u8 sp_max = 100;
			u8 sp_amount = Maths::Min(sp_max, sponge.get_u8(apn) + 50);
			//full?
			if (sp_amount == sp_max)
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

	/*
	KnightInfo@ knight;
	if (!this.get("knightInfo", @knight))
	{
		return damage;
	}

	s32 currentStateIndex = this.get_s32("currentKnightState");
	u8 state = knight.state;

	print("key2 pressed? " + this.isKeyPressed(key_action2));
	print("knocked? " + getKnockedRemaining(this));
	print("onHit: " + this.getPlayer().getUsername() + " currentIndex: " + currentStateIndex + " state: " + state);
	*/

	if (time > 0)
	{
		this.getSprite().PlaySound("/Stun", 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
		setKnocked(this, Maths::Min(time, 60), true);
	}


//  print("KNOCK!" + this.get_u8("knocked") + " dmg " + damage );
	return damage; //damage not affected
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (this.getPlayer() == null) // so drills and what not dont come up with it
	{
		return;
	}

	const f32 currentHealth = this.getHealth();
	f32 temp = currentHealth - oldHealth;

	if (temp > 25)
	{
		temp = 25;
	}

	while (temp > 0) // if we've been healed, play a particle for each healed unit
	{
		const string particleName = "HealParticle"+(XORRandom(2)+1)+".png";
		const Vec2f pos = this.getPosition() + getRandomVelocity(0, this.getRadius(), XORRandom(360));

		CParticle@ p = ParticleAnimated(particleName, pos, Vec2f(0,0),  0.0f, 1.0f, 1+XORRandom(5), -0.1f, false);
		if (p !is null)
		{
			p.diesoncollide = true;
			p.fastcollision = true;
			p.lighting = true; // required unless you want it so show up under ground
		}

		temp -= 0.125f; // now go down to prevent a loop
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	KnockedCommands(this, cmd, params);
}
