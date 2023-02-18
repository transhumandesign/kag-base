#include "VehicleCommon.as"

// Boat logic

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              95.0f, // move speed
	              0.19f,  // turn speed
	              Vec2f(0.0f, -5.0f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;
	Vehicle_SetupAirship(this, v, -900.0f);

	Vec2f pos_off(0, 0);
	this.set_f32("map dmg modifier", 35.0f);

	this.getShape().SetOffset(Vec2f(-6, 16));
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().transports = true;
	
	// add custom capture zone
	getMap().server_AddMovingSector(Vec2f(-40.0f, -16.0f), Vec2f(15.0f, 4.0f), "capture zone "+this.getNetworkID(), this.getNetworkID());

	// additional shapes


	//front bits

	{
		Vec2f[] shape = { Vec2f(69.0f,  23.0f) - pos_off,
		                  Vec2f(93.0f,  31.0f) - pos_off,
		                  Vec2f(79.0f,  43.0f) - pos_off,
		                  Vec2f(69.0f,  45.0f) - pos_off
		                };
		this.getShape().AddShape(shape);
	}

	//back bit
	{
		Vec2f[] shape = { Vec2f(8.0f,  28.5f) - pos_off,
		                  Vec2f(18.0f, 28.5f) - pos_off,
		                  Vec2f(18.0f, 42.0f) - pos_off,
		                  Vec2f(11.0f, 42.0f) - pos_off
		                };
		this.getShape().AddShape(shape);
	}

	CSprite@ sprite = this.getSprite();

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			if (ap.name == "FLYER")
			{
				CSpriteLayer@ propeller = sprite.addSpriteLayer("propeller" + i, sprite.getConsts().filename, 8, 24);
				if (propeller !is null)
				{
					propeller.addAnimation("default", 4, true);
					int[] frames = { 13, 14, 15, 14 };
					propeller.animation.AddFrames(frames);
					propeller.SetRelativeZ(100.0f);
					propeller.SetOffset(Vec2f(-ap.offset.x, ap.offset.y + 16.0f));
					propeller.SetVisible(true);
					propeller.RotateBy(90.0f, Vec2f_zero);
				}
			}

			ap.offsetZ = 10.0f;
		}
	}

	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 96, 56);
	if (front !is null)
	{
		front.addAnimation("default", 0, false);
		int[] frames = { 0, 4, 5 };
		front.animation.AddFrames(frames);
		front.SetRelativeZ(55.0f);
	}

}

void onTick(CBlob@ this)
{
	if (this.hasAttached())
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v)) return;

		Vehicle_StandardControls(this, v);

		AttachmentPoint@[] aps;
		if (this.getAttachmentPoints(@aps))
		{
			CSprite@ sprite = this.getSprite();
			uint flyerCount = 0;
			for (uint i = 0; i < aps.length; i++)
			{
				AttachmentPoint@ ap = aps[i];
				if (ap.name == "FLYER")
				{
					CBlob@ blob = ap.getOccupied();
					CSpriteLayer@ propeller = sprite.getSpriteLayer(flyerCount);
					if (propeller !is null)
					{
						propeller.animation.loop = ap.isKeyPressed(key_down);;
						f32 y = (blob !is null) ? -40.0f : -35.0f;
						propeller.SetOffset(Vec2f(-ap.offset.x, ap.offset.y + y));

						const bool left = ap.isKeyPressed(key_left);
						const bool right = ap.isKeyPressed(key_right);
						propeller.ResetTransform();
						f32 faceMod = this.isFacingLeft() ? 1.0f : -1.0f;
						if (left)
						{
							propeller.RotateBy(90.0f + faceMod * 25.0f, Vec2f_zero);
						}
						else if (right)
						{
							propeller.RotateBy(90.0f - faceMod * 25.0f, Vec2f_zero);
						}
						else
						{
							propeller.RotateBy(90.0f, Vec2f_zero);
						}

					}

					flyerCount++;
				}
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_boat(this, blob);
}

// SPRITE

void onInit(CSprite@ this)
{
}

void onTick(CSprite@ this)
{
	this.SetZ(-50.0f);
	CBlob@ blob = this.getBlob();
	this.animation.setFrameFromRatio(1.0f - (blob.getHealth() / blob.getInitialHealth()));		// OPT: in warboat too
}
