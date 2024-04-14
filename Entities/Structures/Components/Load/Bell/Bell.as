// Bell.as

#include "MechanismsCommon.as";

class Bell : Component
{
	u16 id;

	Bell(Vec2f position, u16 _id)
	{
		x = position.x;
		y = position.y;

		id = _id;
	}

	void Activate(CBlob@ this)
	{
		this.Tag("ringing");
	
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.SetEmitSoundPaused(false);
		}
	}

	void Deactivate(CBlob@ this)
	{
		this.Tag("stop ringing");
	
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.SetEmitSoundPaused(true);
			//sprite.RewindEmitSound();
			sprite.PlaySound("BellRingEnd.ogg");
		}
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place ignore facing");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("BellRing.ogg");
		sprite.SetEmitSoundPaused(true);
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;
	const u16 ANGLE = this.getAngleDegrees();

	Bell component(POSITION, this.getNetworkID());
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		rotateTopology(ANGLE, TOPO_DOWN),   // input topology
		TOPO_NONE,                          // output topology
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}
	
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetZ(-55);
		sprite.SetFacingLeft(false);

		// background layer
		CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Bell.png", 16, 16);
		layer.addAnimation("default", 0, false);
		layer.animation.AddFrame(1);
		layer.SetRelativeZ(-2);

		// bell layer
		CSpriteLayer@ bell = sprite.addSpriteLayer("bell", "Bell.png", 8, 8);
		bell.addAnimation("default", 0, false);
		bell.animation.AddFrame(1);
		bell.SetRelativeZ(1);

		// ringer layer
		CSpriteLayer@ ringer = sprite.addSpriteLayer("ringer", "Bell.png", 8, 8);
		ringer.addAnimation("default", 0, false);
		ringer.animation.AddFrame(4);
		ringer.SetRelativeZ(-1);
	}
}

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickIfTag = "ringing";
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ bell = this.getSpriteLayer("bell");
	CSpriteLayer@ ringer = this.getSpriteLayer("ringer");
	CBlob@ blob = this.getBlob();

	if (bell !is null && ringer !is null && blob !is null)
	{
		if (blob.hasTag("stop ringing"))
		{
			// set to original offset
			blob.Untag("ringing");
			blob.Untag("stop ringing");
			bell.SetOffset(Vec2f_zero);

			ringer.SetOffset(Vec2f_zero);
			ringer.ResetTransform();
		}
		else
		{
			// set to offset with some deviation
			bell.SetOffset(Vec2f(XORRandom(11) * 0.1f - 0.5f,  XORRandom(11) * 0.1f - 0.5f));
			
			ringer.ResetTransform();
			ringer.RotateBy(XORRandom(110) * 0.3f - 30, Vec2f(0, 2));
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}
