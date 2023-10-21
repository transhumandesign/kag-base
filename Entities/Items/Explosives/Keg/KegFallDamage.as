#include "FallDamageCommon.as";

void onInit(CBlob@ this)
{
	// Init saveable from fall damage
	this.getCurrentScript().tickIfTag = "will_go_oof";
	this.set_u32("safe_from_fall", 0); // Tick granted temp fall immunity
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid || this.isAttached())
	{
		return;
	}

	f32 vellen = this.getOldVelocity().Length();

	if (vellen > 1.7f)
	{
		Sound::Play("/WoodLightBump", this.getPosition(), Maths::Min(vellen / 8.0f, 1.1f));

		//printf("vellen " + vellen );
		if (this.hasTag("exploding") && vellen > 8.0f)
		{
			if (isSavedFromFall(this)) return;

			if (shouldFallDamageWait(point1, this))
			{
				this.Tag("will_go_oof");
				this.set_u32("tick_to_oof", getGameTime() + 2);
			}
			else
			{
				Boom(this);
			}
		}
	}
}

void onTick(CBlob@ this)
{
	if (!this.exists("tick_to_oof"))
	{
		this.Untag("will_go_oof");
		return;
	}

	if (getGameTime() >= this.get_u32("tick_to_oof"))
	{
		Boom(this);
	}
}

void Boom(CBlob@ this)
{
	if (isServer())
	{
		this.server_SetHealth(-1.0f);
		this.server_Die();
	}
	else
	{
		// screenshake when close to a Keg

		CBlob @blob = getLocalPlayerBlob();
		CPlayer @player = getLocalPlayer();
		Vec2f pos;

	    CCamera @camera = getCamera();
		if (camera !is null) {
			
			// If the player is a spectating, base their location off of their camera.	
			if (player !is null && player.getTeamNum() == getRules().getSpectatorTeamNum())
			{
				pos = camera.getPosition();
			}
			else if (blob !is null)
			{
				pos = blob.getPosition();
			} 
			else 
			{
				return;
			}

			pos -= this.getPosition();
			f32 dist = pos.Length();
			if (dist < 300) {
				ShakeScreen(200, 60, this.getPosition());
			}
		}
	}
}
