// scroll script that makes enemies insta gib within some radius

#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.addCommandID("sudden gib");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("sudden gib"), getTranslatedString("Use this to make all visible enemies instantly turn into a pile of gibs."), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sudden gib"))
	{
		ParticleZombieLightning(this.getPosition());

		bool hit = false;
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			const int team = caller.getTeamNum();
			CBlob@[] blobsInRadius;
			if (this.getMap().getBlobsInRadius(this.getPosition(), 500.0f, @blobsInRadius))
			{
				for (uint i = 0; i < blobsInRadius.length; i++)
				{
					CBlob @b = blobsInRadius[i];
					if (b.getTeamNum() != team && b.hasTag("flesh"))
					{
						ParticleZombieLightning(b.getPosition());
						if (getNet().isServer())
							caller.server_Hit(b, this.getPosition(), Vec2f(0, 0), 10.0f, Hitters::suddengib, true);
						hit = true;
					}
				}
			}
		}

		if (hit)
		{
			this.server_Die();
			Sound::Play("SuddenGib.ogg");
		}
	}
}